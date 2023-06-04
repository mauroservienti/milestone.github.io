---
layout: post
title: "What if my command was rejected?"
author: Mauro Servienti
synopsis: "Distributed systems are different and require a different mindset. That's particularly true when dealing with async processes and failures. We need new tools and a new toolbox. And in the end,  at e we can avoid rejecting that command."
enable_mermaid: true
header_image: /img/posts/reject-commands/header.jpg
tags:
- soa
- architecture
- messaging
---

I recently got a [comment](https://milestone.topics.it/2019/05/02/safety-first.html#comment-6166203046) on an article about ViewModel Composition, [Safety first!](https://milestone.topics.it/2019/05/02/safety-first.html). Alisher asks about failure scenarios and the possible ramifications of failures in distributed systems:

> Still, after reading this article it's unclear what to do if command was rejected/failed for some reason (validation, invariants) in one of service back-ends.
> Do we trigger compensating actions in all other handlers?
You mentioned in one of your "All our aggregates are wrong" video that handlers must implement IHandleErrors interface, did you omit this part here because you no longer think it's a good approach?
Or am I missing something?
> The more I think of write part of this whole approach (and microservices in general), the more questions arise - like, ok, I can probably compensate database mutations, but what about events that were already propagated downstream? I can't really send compensating event like "actually, it didn't happen".
> There are not many resources on all these details and intricacies, that's why your blog is really valuable - your sharing of knowledge is much appreciated.

Alisher poses perfect questions for which there aren't easy answers. They can only lead to one of those never-ending "it depends" rabbit holes. Why? Because each business scenario comes with very different solutions to the mentioned concerns.

Brace, brace, brace! It's going to be a challenging article ;-)

Before ~~continuing~~ bracing, it's worth reading and watching a few resources on the subject:

- "[Businesses don't fail, they make mistakes](https://milestone.topics.it/2019/09/10/businesses-dont-fail-they-make-mistakes.htm)," from this blog.
- "[Tales of a Reservation](https://milestone.topics.it/2021/05/05/tales-of-a-reservation.html)," also from this blog.
- "[I caught an exception. Now what?](https://particular.net/blog/but-all-my-errors-are-severe)," from Particular's blog.
- "[If (domain logic) then CQRS, or Saga?](https://youtu.be/fWU8ZK0Dmxs)," DDD Europe talk by Udi Dahan.

## Bird eye view

[Tales of a Reservation](https://milestone.topics.it/2021/05/05/tales-of-a-reservation.html) answers some of the mentioned concerns. It uses a simplified hotel booking scenario and some techniques to deal with business failures. Let's start from there and provide some general guidance.

## Asynchronous darkness

The asynchronous world is paved with good intentions, but sometimes to get where you want, you feel like you need to be [Indiana Jones](https://it.wikipedia.org/wiki/Indiana_Jones).

In contrast, the synchronous world is so much easier. When something fails during a synchronous request, the system can take the simplest route, let the error bubble up to the user, and get them to decide what to do. Usually, it's a variation of two options: abandon or retry. For example, they are adding an item to the shopping cart. The database has issues due to a deadlocked query, and the operation results in an HTTP 500. The system catches the error, wraps it in a human-understandable error, and shows it to users.

In an asynchronous system, that luxury doesn't exist. When something goes wrong, users might have already moved to something else. For example, users are booking a hotel room. They place the reservation, get a "thanks for your reservation page," and close the browser. After a while, the system realizes that the selected hotel is sold out, and there is a rule that prevents over-booking. At this point, the error management flow is more complex.

One could argue that it primarily concerns user experience and information architecture people. However, the system design can significantly alleviate that pain.

## Ooops. Let me retry that for you

Surprisingly, the first technique is retrying as if the system was synchronous and the user was still there. We can categorize a whole set of errors as temporary or transient.

We're trying to reserve a hotel room. The web front-end sends a message to the booking back-end service. Something goes wrong while processing the message; for example, the request to the CRM to retrieve the customer's details fails with an HTTP 503 (server too busy). The user might have already closed the browser page.

HTTP 503 is a transient error, like many others. We can retry the incoming message a few times. We could retry it in a loop five times, pause for five seconds if it's still failing, and then try again. If it's still unsuccessful, we can wait longer, e.g., ten seconds, and retry a few more times.

We can solve 95% of the transient errors by applying a similar back-off policy. What about the remaining 5%? We're entering the "it depends" territory where the business domain matters A LOT.

If a one-hour or longer delay in processing a user request is acceptable from the business perspective, we can leverage more extended back-off policies or error queues. If the processing endpoint exhausts all the retry attempts, it can move the failing message to an error queue. When in the error queue, operations people will look at the root cause, possibly fix it and finally retry the message that will eventually succeed.

Going back to Alisher's question for a second: The `IHandleError` interface of [ServiceComposer](https://github.com/ServiceComposer/ServiceComposer.AspNetCore) is an extension point to introduce error management and possibly retries.

Getting into uncomfortable conversations with the business is critical, and asking difficult questions is vital.

## Failing gracefully without failing

If waiting so long is unacceptable or recovering from the error is impossible, we don't want to be failure driven but want to drive the failure.

We need to design the system to fail gracefully, and it can only happen if that's a business scenario. Failing gracefully is the main topic of [Businesses don't fail, they make mistakes](https://milestone.topics.it/2019/09/10/businesses-dont-fail-they-make-mistakes.htm). Let me quickly recap the essence of that article.

There are two main error categories, the ones we can recover from and those we cannot. If the system can recover, some form of retrying is the way. Otherwise, there is no point in retrying or even sending messages to the error queue.

For example, the credit card validation process of the above-mentioned hotel booking system detects the usage of an invalid credit card. Is there a point in retrying the validation? No. Is there a point in sending the message to the error queue and having a human look at it? No.

The system must be designed to handle that scenario. The validation process should "fail" immediately and reply to the caller with an `InvalidCardDetected` message alongside all the details for the recipient to move on and handle the exceptional scenario. In the case of asynchronous systems, we can notify users by email or using a different notification mechanism if such an error happens in back-end services.

> On notifications, I wrote ["Update me, please"](https://milestone.topics.it/2021/08/03/update-me-please.html) and ["Hold on! Your updates are spamming me"](https://milestone.topics.it/2021/09/28/hold-on-your-updates-are-spamming-me.html).

## Why fail if the business can handle it?

A better question is: do we need to fail gracefully or, worse, reject requests?

In our family, we do part of the grocery shopping online. We use a service called ["Esselunga a casa](https://www.esselungaacasa.it/)." Esselunga, an Italian superstore chain, provides the service.

We select what we would like from the online catalog. Decide when/can receive the delivery (it's a two-hour window on the appointed day). We pay by credit card. They immediately authorize the amount on the card. That's the first rule, take the money and deal with the rest later.

On the day of the delivery, they send an email with two lists. The first list is what will be delivered, and the second is what's unavailable.

Think about it for a second. What's happening is very straightforward: the customer wants a few goods, say 25 different items. When collecting them on the delivery day, Esselunga realizes that two are out of stock or the desired quantity is unavailable. They deliver what they have and charge the credit card for a lesser amount. And everyone is happy.

It feels so natural, right? If that's the case, why do we use invariants?

```csharp
var inStockQty = getStockQuantityFromDatabase( itemSku );
if ( inStockQty < requestedQuantity )
{
   throw new InvalidOperationException( "Items out of stock" );
}
```

That code is already broken in a synchronous code base. The only situation in which it could work as expected is if the entire block is surrounded by a serializable transaction that effectively makes it so that only one request at a time evaluates the invariant. It's effective but tremendously inefficient. A synchronous code base requires some load for the problem to manifest. In a distributed system, it'll eventually happen very quickly.

## Can we be like Esselunga?

The answer truly depends on the business scenario. Whenever we feel the urgency of using an invariant, we should go back to the business and ask a few questions:

- Can we sell more than what is in stock?
- Can we overbook the flight?
- Can we allow booking more rooms than we have?
- Can we allow a delay in charging the credit card if the vending machine fails to connect to the back end?
- Can we ship from multiple warehouses or create more than one shipment for a single order?

We all would answer yes to those questions because that's how the world works. It's eventually consistent and compensates later for earlier changes. That's why my favorite architecture analysis question is: how would we implement that without computers? And in most cases, the answer doesn't include invariants.

## Design for hardware failures by embracing horizontal scaling

Last but not least, a different but more straightforward story: what if there is no software error?

I'm booking a hotel room, and in doing so, the system sends a message to the booking service back-end. The booking service is down and doesn't process the message. There is no way to fail gracefully. No one can reply by saying, "Sorry, I'm offline." One could argue that a [watchdog](https://en.wikipedia.org/wiki/Watchdog_timer) is a good countermeasure, but I could say that it could be down too.

Scaling out the booking service by deploying multiple instances that behave as [competing consumers](https://docs.particular.net/nservicebus/architecture/scaling#scaling-out-to-multiple-nodes-competing-consumers) is a handy way to create the necessary redundancy to alleviate any hardware related issue.

Sure, a [squirrel could attack](https://www.datacenterknowledge.com/archives/2012/07/09/outages-surviving-electric-squirrels-ups-failures/) the data center our stuff runs in. If that's a concern, geo-redundancy is the solution. Rarely do we need to reinvent the wheel. The industry provides a ton of battle-tested solutions to address such concerns.

## Conclusion

As described, we have multiple options, from technical solutions like retries and error queues to designing to avoid rejecting requests. When dealing with potential failures, as in many other contexts, the business is king, and it should be our primary choice when faced with something that looks very much like an invariant.

---

Photo by <a href="https://unsplash.com/@dimhou?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Dim Hou</a> on <a href="https://unsplash.com/photos/BjD3KhnTIkg?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
