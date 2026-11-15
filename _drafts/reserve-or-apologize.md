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

<!-- TODO: decide whether the expiration details stay here as a teaser or move entirely to the follow-up "Reservations that expire: the details that bite" -->

Reservations work best when capacity is truly fixed, like a hotel room or a seat in a theater. When the business can't create one more of something, reserving is often the only sensible option.

## Answer two: accept and apologize

The second answer goes the other way around. The system accepts the assignment. Both dispatchers succeed. Later, the service that owns the capacity notices that the carrier is overbooked and deals with it.

How? That's up to the business. For example:

- rebook one of the shipments on the next available carrier;
- upgrade it to a faster, more expensive option at no extra cost for the customer;
- ask the carrier whether it can take one more shipment anyway.

That last option is not a joke. A carrier is not a hotel room. A truck that can take ten pallets can sometimes take eleven. The "one free slot" on the screen might be a softer limit than it looks. As I wrote in ["Tales of a reservation"](https://milestone.topics.it/2021/05/05/tales-of-a-reservation.html), invariants are often less invariant than we think, and airlines built a whole business practice, overbooking, on that idea.

<!-- TODO: double-check the carrier capacity claim against the domain; if "slot" in the example means a hard limit (e.g., a dock appointment), reword -->

This is what I call a follow-the-money approach. The question is not "how do we prevent this from ever happening?" It's "what does it cost when it happens, and how do we make it right?"

There's a catch, though: apologizing is a process, and someone has to design it. My tablet dealer had a rule but no plan for when the rule broke. The system couldn't take a late payment for a shipped order, so the business didn't apologize: it silently lost money.

Accepting and apologizing also means commands don't fail. As I discussed in ["What if my command was rejected?"](https://milestone.topics.it/2023/06/27/reject-commands.html), a command that can't be rejected is a lot simpler to deal with in a distributed system. The user's intent is captured, and the system takes care of the consequences.

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

Neither is better in general. Reservations fit truly fixed resources; apologies fit elastic ones, or ones where an occasional overbooking is cheap. Asking the business what an overbooking costs usually tells us which is which. And in both cases, the decision belongs to the service that owns the resource.

<!-- TODO: closing wink or a teaser for the follow-up on expiring reservations -->

---

<!-- TODO: header image and Unsplash credit -->
