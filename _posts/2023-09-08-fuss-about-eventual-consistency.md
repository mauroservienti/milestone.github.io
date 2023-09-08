---
layout: post
title: "Why all this fuss about eventual consistency? It's everywhere!"
author: Mauro Servienti
synopsis: "Our industry seems to worry A LOT about eventual consistency. The real world is eventually consistent by definition. Still, we continuously try to fit a square peg into a round hole. Why is that, and what can we do about it?"
header_image: /img/posts/fuss-about-eventual-consistency/header.jpeg
Tags:
- soa
- distributed-systems
---

First and foremost, my colleague [Dennis Van Der Stelt](https://twitter.com/dvdstelt) delivered an excellent talk on dealing with eventual consistency at NDC Oslo. Watch it. It might address all your doubts, and you won't need to read this article!

<iframe width="560" height="315" src="https://www.youtube.com/embed/Wy-BmhB6ty4" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

Still here? Good. Nearly every time I read an article, a blog post, or watch a video about some architectural design options proposing how to address the issues that come with a monolith architecture, there are comments similar to:

> Yeah, neat solution. But it'll introduce eventual consistency.

Followed by a set of (apparent) reasons why eventual consistency is a terrible problem in their context.

[Systems, applications, services, and user scenarios](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html) have several attributes. One of those attributes defines if, in a particular scenario, the user needs to "read their own writes."

An example might help. In the context of an e-commerce system, when creating a new product to sell, back-office users:

- Fill in product details.
- Click on a button to select the supplier name.
  - If the supplier doesn't exist in the system, they are presented with a screen to add a new supplier.

Once the step is completed, they return to the product creation screen and expect to use the recently created supplier immediately. That's a scenario when users need to "read their own writes."

In contrast, this blog is eventually consistent, and that's just fine:

- I write a markdown document.
- Push changes to GitHub.
- GitHub pages schedule an Action to regenerate the blog.
- After regeneration, an Action step publishes the new content to GitHub pages.

That's eventual consistency at play. It can take a few minutes to complete, and that's fine.

From the end-user perspective, that's the same that happens when creating a product in an e-commerce system. They don't know the creation process is happening, and they're not waiting.

Readers and writers are different personas. The reader is unaware of when the writer pushes changes and thus is not eagerly waiting for the newly created article or product to be available. Who writes differs from who reads.

Eventual consistency causes headaches, primarily if not only in the "read your own writes" scenario.

## A note: Eventual consistency is with us...

...and has always been unless pessimistic locking was in place. Let's look at another example: in the previously mentioned e-commerce scenario, there is a strange rule, also known as invariant—[which is evil](https://milestone.topics.it/2021/05/05/tales-of-a-reservation.html), stating that customers cannot buy any out-of-stock product. The only possible way to enforce the rule is to serialize requests to the database using the highest possible transaction level. If that's not the case, there's always a chance of [phantom reads](https://sqlsolutionsgroup.com/dodging-phantom-reads/) leading to more than one customer ordering the last-in-stock [lightsaber](https://en.wikipedia.org/wiki/Lightsaber).

That is to demonstrate that unless we explicitly design to prevent eventual consistency from happening, the system has a chance of being affected. Sure, it might be a rare scenario, but still, it needs to be protected from the lack of complete consistency. I'd even argue it could be a worse scenario; it's subtle and hard to detect.

## How it all started

When we started using relational databases, we needed to solve the problem of storing data structures that we would later call complex object graphs, requiring interaction with more than one database table.

Transactions were a perfect solution. They came with Atomicity, Consistency, Isolation, and Durability. ACID transactions were a game changer. For example, we need to store an order and its details or a shopping cart and its items. Those are complex graphs characterized by a master/details relationship. In a relational database, we need two tables, one for the shopping cart and one for the shopping cart items. The latter has a foreign key to the former to connect shopping cart items to the owning shopping cart. We require a transaction to ensure no items are written without an owning shopping cart or the other way around.

From the programming model perspective, it's mostly about complete consistency. We want all of them to be written at once without incurring partial writes. At the same time, we want all of them to be available for readers when they are all written to avoid phantom reads. For example, we don't wish cart items to be available for reads while we still write the owning shopping cart.

## Distributed transactions, DCOM and CORBA

But then distributed transactions came, and we got carried away. In their simplest form, distributed transactions allow a transaction between two database tables defined in different databases on different computers.

We did not stop there. Different resources could be enlisted in a distributed transaction, like a database table, a message queue, and a remote service invocation. Can you imagine all those heterogeneous things in the same transaction?

We even went further with protocols like DCOM or CORBA, presenting to consumers a set of distributed object instances as if they were a single instance. All of them coordinated by transactions.

What could possibly go wrong?

## The cloud changed everything

Transactions were so engraved that for some, it was hard, even impossible, to think about a world without transactions. But "recently," something changed. The cloud became an affordable and available option to the masses. And the cloud, primarily for the vendors' benefit, decided that (distributed) transactions were to be banned in disgrace. The underlying reason is that infrastructure in the cloud is flaky in nature, and transaction protocols were thought and designed under the assumption that [the network is reliable](https://particular.net/blog/the-network-is-reliable), the number one fallacy of distributed computing.

## A new hope (cit.)

The cloud also came with a neat solution to the problem: messaging, message queues, and message brokers. Instead of having so many heterogeneous resources in a single transaction, developers can use reliable messaging infrastructure to send requests to other services.

Messaging allows splitting significant processes into smaller chunks and connecting them using messages. A bit of a process happens there, and then a message gets sent to a different node to continue with another bit. And so on until the process is completed. 

Messaging is a way to trade consistency for availability.

The proposed exchange brings eventual consistency into the mix. Because what previously was a monolithic process governed by transactions locking the requestor and forcing them to wait, is now a set of smaller steps independent of each other with no control over consistency, making it hard for requestors to wait for completion.

## So what?

Not all hope is lost, and there are a few things we can do to solve, alleviate, or work around any eventual consistency-related issues.

### The "one architecture to rule them all" fallacy

The first and probably most important thing is to stop using the same architectural style everywhere in the system.

I've witnessed many instances of "we've decided to use [chose your favorite architecture]." That decision makes the architectural choice a top-level architecture, constraining all system parts to use it.

In many cases, there is this tendency to restrain that through code, by enforcing coding styles, or by building an internal framework to ease development. The internal framework ships base abstract classes, such as `AggregateBase` or `EventSourcedEntity`, and the team's policy is to use those everywhere.

Stop doing that. We don't need to use the same architecture everywhere in the system.

## Choose wisely

Before choosing which architecture to use, validate where eventual consistency is a pain that must affect the system. List all scenarios and carefully evaluate if there is no other way to implement them. Most of the time, you can also filter out all non-"read your own writes" scenarios. Even if they are eventually consistent, it's no big deal.

Then, go through use cases where eventual consistency emerges due to the performance implications of the system under load. When that's the case, go to the business, sit with them, and define performance boundaries. [Only by knowing your limits](https://milestone.topics.it/2022/05/30/know-your-limits.html) can you decide if eventual consistency is something you must deal with.

For all the others, go with a synchronous approach. Measure and postpone any decision.

## Technology shall not command

Rarely, if ever, technology is a driver for architectural choices. It's the other way around. My favorite way of approaching the problem of digitally transforming business processes is to observe, ask, or imagine how humans would run them without technology. The first implementation mimics what I learned. Life is eventually consistent by definition. Sometimes, there is little point in folding that into a synchronous behavior.

## Flares

For all the other cases, which should now be the minority, fake it!

Dazzle them with flares to deceive users. It's a matter of applying countermeasures where it's strictly necessary. In the presented blog scenario, there is no need for any flares.

We can use different tools when creating new products and selecting suppliers if the scenario mandates eventual consistency. I discussed them in the past (no pun intended) in [Can we predict the future?](https://milestone.topics.it/2021/06/02/can-we-predict-the-future.html)

Our options don't stop there. [A thorough UX analysis is part of the solution](https://milestone.topics.it/2021/04/02/a-thorough-ux-analysis-is-part-of-the-solution.html). There are plenty of "tricks" we could use to deceive them. Let me give you a couple of examples.

When adding items to the shopping cart on an e-commerce website, we could show an "other people that bought this also bought these other things" intermediary page instead of immediately showing the shopping cart content. That serves two purposes. It helps sell more. It compensates for the shopping cart's eventual consistency if it turns out it must be eventually consistent.

A friend showed me another one. They were developing an iOS application a few years ago. The app needed a few seconds to be ready to use. If I recall correctly, iOS didn't support splash screens then. They took a screenshot of the ready app and showed that while finishing loading all that needed. It's a dirty trick, but it served them well.

## Conclusion

Eventual consistency surrounds us. By conducting a thorough architectural and user experience analysis, we can identify those scenarios where eventual consistency is a must-have, a pain we must accept. All the other use cases can be synchronous, for example.

Lastly, we can adopt various flares, tricks, and UI/UX tips to help users navigate the difficulties of an eventually consistent system. Before you leave, if you haven't already, [watch Dennis' talk ;-)](https://www.youtube.com/embed/Wy-BmhB6ty4).

---

Photo by <a href="https://unsplash.com/@pagsa_?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Pablo García Saldaña</a> on <a href="https://unsplash.com/photos/lPQIndZz8Mo?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
