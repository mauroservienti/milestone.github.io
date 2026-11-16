---
layout: post
title: "Reserve, or apologize? Two answers to stale data"
author: Mauro Servienti
synopsis: "Data is stale the moment we read it. When two users compete for the last unit of something, no amount of locking in the UI will save us. We can reserve, or we can accept and apologize. Which one, and who decides?"
header_image: /img/posts/reserve-or-apologize/header.jpg
related:
- 2021-05-05-tales-of-a-reservation.md
- 2023-06-27-reject-commands.md
- 2023-09-08-fuss-about-eventual-consistency.md
- 2021-06-02-can-we-predict-the-future.md
- 2026-11-26-idempotency-deep-dive.md
- 2021-01-21-ooops-can-I-try-again-please.md
resources:
- "[Stale Data Is More Than an Eventual Consistency Problem](https://codeopinion.com/stale-data-consistency-boundaries/) by [Derek Comartin](https://codeopinion.com/)"
tags:
- soa
- distributed-systems
- architecture
---

I once got a tablet I never paid for.

The tablet arrived, but the payment never went through. I contacted the dealer to pay. According to their system, the order was shipped. They could see it wasn't paid, but there was nothing they could do about it.

So I never paid for it.

Somewhere in that system lived a rule: nothing ships unless it's paid. The rule broke, and nobody had designed a way to deal with it.

That tablet came back to my mind while reading ["Stale Data Is More Than an Eventual Consistency Problem"](https://codeopinion.com/stale-data-consistency-boundaries/) by Derek Comartin. It's a good read, and it made me nod more than once.

The scenario goes more or less like this: two dispatchers look at the same screen. The screen says a carrier has one free slot left. Both assign a shipment to it. One of them is in for a surprise.

Derek's point is that the data was stale the moment the dispatchers read it. It's not an eventual consistency problem; it's the nature of reading data that someone else can change. His answer is to stop treating it as a read problem and model it as a "reserve capacity" operation, owned by the service that owns the capacity.

I agree with the diagnosis. However, I think there's a second answer, and it's one I wrote about a while ago in ["Tales of a reservation"](https://milestone.topics.it/2021/05/05/tales-of-a-reservation.html): accept, and apologize if needed. Let's look at both.

## All data is stale

Before getting to the answers, let's agree on the problem.

The moment a query returns, the result describes the past. It might be the very recent past, a few milliseconds ago, but it's the past. By the time the user looks at the screen, thinks about it, and clicks a button, anything could have happened.

It's tempting to fight that with technology:

- **Optimistic concurrency.** The second dispatcher gets an error instead of a surprise. That's better, but the dispatcher still made a decision based on data that wasn't true anymore, and now has to make it again.
- **Moving the query next to the command.** Checking availability in the same transaction that assigns the shipment narrows the window. It doesn't change the fact that the user decided based on what the screen showed.
- **Real-time UI updates.** Pushing changes to the screen makes the data less stale. It doesn't make it fresh. As I wrote in ["Can we predict the future?"](https://milestone.topics.it/2021/06/02/can-we-predict-the-future.html), the UI is always behind.

None of these are bad ideas. They just don't answer the real question: what should happen when two people want the last slot?

That's not a technical question. It's a business one.

## Answer one: reserve

The first answer is to make the competition explicit. Instead of "assign the shipment to the carrier," the operation becomes "reserve a slot on the carrier." The service that owns the carrier's capacity is the only one that can grant a reservation. It can say yes to the first dispatcher and no to the second, consistently, because it's the single writer for that capacity.

That's what we do with hotel rooms and concert tickets. The room is held for us while we type our credit card details. If we take too long, the reservation expires and the room goes back on the market.

It's a sound approach, but let's be honest about what a reservation is: it's a lock. A business-level lock, with a timeout, but still a lock. And locks come with costs:

- **Held capacity.** While a slot is reserved, nobody else can have it. If the reservation is abandoned, that capacity sat idle for the whole reservation period.
- **Expiration.** Someone has to decide how long a reservation lasts, and something has to release it when it expires. Too short, and users lose reservations they meant to complete. Too long, and capacity is wasted.
- **Contention.** Popular resources get many concurrent reservation attempts. The more popular the resource, the more users hear "sorry, it's gone" at the very moment they wanted it.

Reservations work best when capacity is truly fixed, like a hotel room or a seat in a theater. When the business can't create one more of something, reserving is often the only sensible option.

### Reservations that expire

Expiration deserves a closer look, because that's where the details bite.

A timed reservation usually works like this: the dispatcher reserves a slot, the system creates the shipment, and the shipment creation confirms the reservation. If the confirmation doesn't arrive in time, the reservation expires and the slot goes back on the market.

It sounds simple. Let's see what can go wrong.

- **The confirmation arrives after the reservation expired.** Should the capacity owner reject it, try to reserve the slot again, or accept it and deal with a possible overbooking? Look closely at the last option: it's an apology.
- **Messages arrive more than once.** Reserve and confirm requests can be retried or duplicated. Both must be idempotent, or a retry could reserve two slots for the same shipment. I covered the techniques in ["Idempotent, you must be. A deep dive into idempotency"](https://milestone.topics.it/2026/11/26/idempotency-deep-dive.html).
- **Something fails after the reservation.** If the shipment creation fails, who releases the slot, and when? Waiting for the timeout is simple, but it holds capacity for nothing.
- **Someone has to own the workflow.** Reserving, waiting for a confirmation, and expiring is a long-running process with a timeout. It belongs to the service that owns the capacity, and a saga with a timeout is a natural fit for it.

Finally, how long should a reservation last? That's not a technical decision. Ten minutes might be fine for a dispatcher and way too long for a concert ticket on sale day. Ask the business.

## Answer two: accept and apologize

The second answer goes the other way around. The system accepts the assignment. Both dispatchers succeed. Later, the service that owns the capacity notices that the carrier is overbooked and deals with it.

How? That's up to the business. For example:

- rebook one of the shipments on the next available carrier;
- upgrade it to a faster, more expensive option at no extra cost for the customer;
- ask the carrier whether it can take one more shipment anyway.

That last option is not a joke. Airlines do something similar every day, and they have a name for it: overbooking. They know that some passengers won't show up, so they sell more tickets than there are seats. When everyone shows up, they apologize: they look for volunteers, rebook passengers on the next flight, and compensate them. It happened to me once, on a Sunday night flight from London City to Milan, where a bid ran at the gate because there were four more passengers than seats.

Overbooking doesn't require elastic capacity. The plane doesn't grow an extra seat. It's a bet based on statistics, and carriers can make the same bet: some shipments get canceled, some aren't ready on time, some are smaller than declared. A capacity owner that knows those numbers might decide to accept more than the nominal capacity on purpose. As I wrote in ["Tales of a reservation"](https://milestone.topics.it/2021/05/05/tales-of-a-reservation.html), invariants are often less invariant than we think.

This is what I call a follow-the-money approach. The question is not "how do we prevent this from ever happening?" It's "what does it cost when it happens, and how do we make it right?"

There's a catch, though: apologizing is a process, and someone has to design it. My tablet dealer had a rule but no plan for when the rule broke. The system couldn't take a late payment for a shipped order, so the business didn't apologize: it silently lost money.

Accepting and apologizing also means commands don't fail. As I discussed in ["What if my command was rejected?"](https://milestone.topics.it/2023/06/27/reject-commands.html), a command that can't be rejected is a lot simpler to deal with in a distributed system. The user's intent is captured, and the system takes care of the consequences.

A waitlist is a milder version of the same idea. When capacity runs out, the request is accepted anyway and filled later, from cancellations or expired reservations. If nothing frees up, the business says sorry.

## Is there a middle ground?

So far, I presented the two answers as opposites. They don't have to be. Think about a concert in a stadium with tens of thousands of seats. Pure reservations hurt the most there: everyone wants the same thing at the same second, and everyone competes for the same capacity.

There are a few options in between.

### Partition the capacity

A stadium isn't one pool of 60,000 seats. It's 40 sectors. If each sector is managed independently, contention is spread across 40 small pools instead of one big counter, and sectors don't need to coordinate with each other.

The price is fragmentation. Sector B can sell out while sector F still has seats, and a group of four might not fit anywhere because the free seats are scattered. Someone has to decide whether, and how, to rebalance. In the dispatchers' example, the equivalent is partitioning carrier capacity by route or by day.

A variation is to partition by who sells instead of by what is sold. Hotels give a fixed allotment of rooms to each booking site, and each site sells from its own slice without coordinating with the others. What's left unsold goes back to the hotel at a cutoff date.

### Reserve a quantity, not an item

"Two seats in sector B" is a lot less contended than "seats B-14 and B-15." Users reserve a quantity, and the specific seats are assigned later, for example, as the best available at checkout. Airlines work like that: we buy a seat in a fare class, and the seat number comes later.

Contention moves from items to counters, and counters are much easier to partition.

### Switch strategy at a threshold

While capacity is plentiful, accept freely: an overbooking is practically impossible. When capacity drops below a threshold, switch to strict reservations. That's where the "only 3 left!" messages come from. It's literally a mix of the two answers, chosen based on how much risk is left.

### Change the rules

Sometimes the best option is to change the game. Some big events sell tickets with a lottery. Requests are collected for a while, and tickets are allocated afterward. Nobody competes with anybody, no command fails, and not getting a ticket is part of the rules, not an apology.

That's not a technical solution. It's the business redesigning the process so that the stale data problem doesn't exist anymore. Virtual waiting rooms go in the same direction, more modestly: they control how many users compete at the same time.

## What does an overbooking cost?

So, reserve or apologize? The answer depends on a question we should ask the business before writing any code:

> What happens, and what does it cost, when two shipments end up on a carrier that can take only one?

If the answer is "a missed delivery that costs us a key customer," reserving is probably worth the held capacity and the contention. If the answer is "we move one shipment to the next truck, and nobody notices," then the reservation machinery costs more than the problem it solves.

Most of the time, the answer is somewhere in between, and it might even change depending on the resource. The last slot on the only carrier going to a remote location is not the same as the last slot on one of twenty carriers going to the same city.

The key is that the decision belongs to the service that owns the resource. It's the capacity owner that knows how hard its limits are and what the alternatives look like. The dispatchers' screen doesn't, and neither does the service that owns the shipments.

## Queries inform, commands decide

There's a principle underneath both answers. Udi Dahan put it well in ["Clarified CQRS"](https://udidahan.com/2009/12/09/clarified-cqrs/): the query side informs users' decisions, but it's the command side that decides.

The screen showing "one free slot" is not lying. It's telling the dispatcher what was true a moment ago, to help them make a choice. Whether that choice can be honored is up to the command, and the service handling it.

Once we accept that, stale data stops being a bug to fix. It's a fact of life, like it is in the real world, as I argued in ["Why all this fuss about eventual consistency? It's everywhere!"](https://milestone.topics.it/2023/09/08/fuss-about-eventual-consistency.html). What remains is a design decision: does the command reserve, or does it accept and let the owner apologize?

## Conclusion

Data is stale the moment we read it, and no amount of technology in the user interface changes that. When users compete for a limited resource, we have two honest answers:

- **Reserve**, making the competition explicit and accepting the costs of a business-level lock: held capacity, expirations, and contention.
- **Accept and apologize**, capturing the user's intent and letting the resource owner make it right when the limit turns out to be exceeded.

Neither is better in general. Reservations fit truly fixed resources; apologies fit elastic ones, or ones where an occasional overbooking is cheap. And there's plenty of room in between: partitioning the capacity, reserving quantities instead of items, switching strategy at a threshold, or changing the rules altogether. Asking the business what an overbooking costs usually tells us which is which. And in both cases, the decision belongs to the service that owns the resource.

There's one question I deliberately left out: who generates the reservation identifier? If the client does, retries become trivially idempotent. But we're now trusting the client with something the capacity owner cares a lot about. That's a story for another post ;-)

---

<!-- TODO: header image and Unsplash credit -->
