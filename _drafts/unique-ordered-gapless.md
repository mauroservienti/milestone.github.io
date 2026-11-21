---
layout: post
title: "Unique, ordered, gapless: who gets to pick the number?"
author: Mauro Servienti
synopsis: "Identifiers look like a solved problem until we ask more of them. Unique is cheap, ordered is harder, and gapless, the one invoice numbers need, is a different beast altogether. Who should generate them, and when?"
header_image: /img/posts/unique-ordered-gapless/header.jpg
related:
- 2027-02-10-reserve-or-apologize.md
- 2026-11-26-idempotency-deep-dive.md
- 2021-01-21-ooops-can-I-try-again-please.md
- 2021-05-05-tales-of-a-reservation.md
tags:
- soa
- distributed-systems
- architecture
---

In ["Reserve, or apologize?"](https://milestone.topics.it/2027/02/10/reserve-or-apologize.html), I looked at what happens when two people compete for the last of something, a slot on a carrier, a hotel room, a concert ticket. One answer is to reserve: the service that owns the capacity holds the item for us for a while, and we either confirm the reservation or let it expire.

Every reservation needs an identifier, something to confirm, cancel, or retry it with. At the end of that post, I left a question hanging: who generates that identifier? And I promised to come back to it, together with its evil twin: invoice numbers.

Here we are.

Identifiers look like a solved problem. Slap a GUID on it and move on. That works, as long as all we ask of an identifier is to be unique. The trouble starts when we ask for more:

- **Unique:** no two things share the same identifier.
- **Ordered:** identifiers sort in the order things were created.
- **Gapless:** no number is ever skipped.

Each requirement is more expensive than the previous one. Let's see why.

## Unique is cheap

If uniqueness is all we need, the client can generate the identifier. A GUID, or UUID, is unique enough that no coordination is needed: no round trip, no central counter, no contention.

And there's a bonus. If the client generates the reservation ID before sending the command, retries become trivial. The same command, with the same ID, can arrive twice, and the capacity owner recognizes it. That's idempotency for free, or almost; I went through the details in ["Idempotent, you must be"](https://milestone.topics.it/2026/11/26/idempotency-deep-dive.html).

Is that it? Not quite.

## Can we trust the client?

A client-generated identifier is a promise made by someone we don't control. A buggy client, or a malicious one, can reuse an identifier, or guess somebody else's. For a reservation, that might mean overwriting or canceling a reservation that isn't ours.

One middle ground is to let the server hand out identifiers in batches. The client asks for a block of, say, 100 identifiers, uses them one by one, and asks for a new block when it's running low, for example, at 70% usage. Database people will recognize the idea: it's what Hi/Lo identifier generators have done for years. We get uniqueness without a round trip per request.

However, look closely at what the server now has to do. To trust an identifier, it must verify that it was issued to that client and hasn't been used yet. It tracks issued, used, and expired identifiers, per client.

That's a reservation. A reservation of identifiers, with all the costs we discussed for reservations: held capacity, expirations, and bookkeeping. There's no free lunch; we moved the problem, we didn't remove it.

## Ordered is harder

GUIDs don't sort in creation order. Often, that's fine. Sometimes, it isn't: we want the newest orders first, or we want a database index that doesn't get fragmented by random keys.

Time-ordered identifiers help. [UUID version 7](https://www.rfc-editor.org/info/rfc9562/) starts with a timestamp, so identifiers generated later sort later. Twitter's Snowflake did something similar, combining a timestamp, a machine identifier, and a sequence number.

The catch is the word "later." Later according to whose clock? Two machines generating identifiers at the same time don't share a clock, and their clocks drift. Time-ordered identifiers are roughly ordered, and roughly is often good enough. If we need strict ordering across the whole system, we need a single source of truth that hands out numbers one at a time.

A single counter, in other words. And a single counter is a contention point by definition.

## Gapless is a different beast

Now the evil twin.

In many countries, invoices must be numbered sequentially. The [EU VAT directive](https://eur-lex.europa.eu/legal-content/EN/ALL/?uri=celex%3A32006L0112) asks for "a sequential number, based on one or more series, which uniquely identifies the invoice." In Italy, the number must be progressive and identify the invoice uniquely. Numbering no longer has to restart every year, but it still has to move forward one step at a time.

A gap is a question an auditor will ask. Where's invoice 1042? Was it issued and hidden? Was it deleted? We'd better have an answer.

Here's what makes gapless so nasty: none of the tricks we've seen so far work.

- **Client-generated identifiers:** the client has no idea what the next number is.
- **Batches:** a client that crashes takes its unused batch with it, and every number in it becomes a gap.
- **Database sequences:** they don't help either. In most databases, a sequence value consumed by a transaction that later rolls back is gone. Sequences are designed to be fast, not gapless.

A gapless number is a reservation that never expires and can never be released. Once taken, it must be used. If it's not used, we have a hole in the sequence and some explaining to do.

So what's left? A single writer, assigning numbers one at a time, at a moment when it knows the number will be used.

## Assign the number as late as possible

That last part is the key. The mistake is treating the invoice number as the invoice identity.

An invoice can have two identifiers:

- An **internal identifier**, unique, generated whenever we like, by whoever we like. A GUID is fine. Drafts, approvals, PDFs, and messages between services use this one.
- A **legal number**, gapless, assigned by the service that owns invoicing, at the very last moment: when the invoice is issued, and nothing can make it fail afterward.

The draft can be created, edited, and thrown away without consuming anything. Only issuing touches the counter, and issuing is a short, single-writer operation. Contention is still there, but it's limited to the one step that needs it.

And remember "based on one or more series"? That's partitioning. Many businesses use separate series, for example, one per branch, or one per sales channel. Each series is its own counter, with its own single writer. It's the stadium sectors from ["Reserve, or apologize?"](https://milestone.topics.it/2027/02/10/reserve-or-apologize.html) all over again: smaller pools, less contention, and some rules about which pool to use.

## You can't delete an invoice

What if an issued invoice is wrong? We can't delete it; that would leave a gap. We issue a credit note that cancels it, fully or partially, and if needed, a new invoice.

Think about it for a second: the credit note is a legal, standardized apology. Accounting institutionalized "accept and apologize" a long time ago. The invoice was issued, it's part of history, and the only way forward is a compensating action. Commands don't fail; we just record what happened next.

There's one exception that proves the rule. In Italy, electronic invoices go through a central exchange system, and when it rejects an invoice, for example, because a field is malformed, the invoice is considered never issued. In that case, the [tax agency's guidance](https://www.agenziaentrate.gov.it/portale/documents/20143/297470/Circolare+n+13+del+02+luglio+2018_Circolare_13_02072018.pdf/da0b0db7-64eb-ac7b-c925-4fdbc776279d) prefers sending the corrected invoice with the same number and date, within five days of the rejection.

In other words, a rejected invoice gives its number back, with a deadline. A reservation that expires, but only if we act on it in time.

## Conclusion

Identifiers are a requirements problem disguised as a technical one. Before picking a GUID, a sequence, or a fancy time-ordered scheme, it's worth asking which of the three properties we actually need:

- **Unique** is cheap. Let the client generate it, and enjoy idempotent retries. Validate what you can't trust.
- **Ordered** is harder. Time-ordered identifiers are good enough most of the time; strict ordering needs a single source of truth.
- **Gapless** is expensive. It needs a single writer per series, and the number must be assigned only when it's guaranteed to be used.

In most systems, only a small part of the data needs gapless numbers, and it's usually the part with legal consequences. Keep it small: give everything a cheap, unique identity, and let the owner of the legal number assign it as late as possible.

As for the tablet a dealer once shipped me without ever getting paid for it, I wonder if it ever got an invoice number. I'd love to know how they explained the gap ;-)

---

Photo by <a href="https://unsplash.com/@omilaev?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Igor Omilaev</a> on <a href="https://unsplash.com/photos/a-bunch-of-rubber-ducks-sitting-on-a-blue-surface-VyD_UzTDm9o?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a>
