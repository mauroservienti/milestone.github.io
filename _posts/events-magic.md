---
layout: post
title: "Someone says event, and magically, coupling goes away"
author: Mauro Servienti
synopsis: "I feel events are used too many times as a hammer to dismantle coupling. Unfortunately, it's gold plating. It might look better, but it'll fire back in the long term and cost more."
header_image: /img/posts/events-magic/header.jpg
tags:
- architecture
---

I know... I'm grumpy, and [I've been ranting lately](https://milestone.topics.it/2024/01/27/cqrs-and-es.html). I promise it's the last time—famous last words 😬

The [Mongo DB Is Web Scale](https://youtu.be/b2F-DItXtZs?si=7oZfEm0udIHCrGZZ) cartoon always makes me roll on the floor laughing. If you have never seen it, those are 5 minutes well spent. Take a look:

<iframe width="560" height="315" src="https://www.youtube.com/embed/b2F-DItXtZs?si=WES0g_W1kT0GFY7K" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

It's twelve years old. MongoDB may not be the main character anymore, and maybe it wasn't even then. It's more about stubbornness and the conviction that tools blindly put to work can solve any problem. The same applies to many other concepts back in the day and nowadays, too. Tools are not, and can't be, [silver bullets](https://en.wikipedia.org/wiki/No_Silver_Bullet).

Recently, I was chatting with my dear friend [Weronika Łabaj](https://twitter.com/weralabaj), and she said what then became the title of this article and also something that can easily replace the word MongoDB in the presented meme/cartoon:

> Someone says event, and magically, coupling goes away.

We discussed this ongoing trend: There is this belief that introducing events into systems' architecture will magically eliminate coupling. Or, adopting an event-driven architecture is sufficient so that coupling never appears.

Paraphrasing the meme: events are web-scale.

One could argue what it is that makes people freak out when thinking about coupling. That's an appropriate and to-the-point question. Coupling, per se, is neither good nor bad. It's a metric measuring how much two components are "connected." Before trying to eliminate as much coupling as possible blindly, we should understand the context because [not all changes are born equal, and the same is true for coupling; not all coupling is bad coupling](https://milestone.topics.it/2021/03/10/not-all-changes-are-born-equal.html).

## Events are not "web-scale"

Let's start by disambiguating what kind of events we are talking about. In the software architecture world, the word event [means too many things](https://milestone.topics.it/2021/09/15/linguistic-limitation.html).

We're not discussing C# events, like delegates or Event Sourcing events. We're examining events published by a publisher to which more than one subscriber could subscribe. Hold on, C# events and delegates match the definition, and I'm hoping that no one publishes Event Sourcing domain events for public consumption. Unfortunately, and that's why disambiguation is crucial. Let's try again:

> Events asynchronously published by a publisher to which more than one subscriber could asynchronously subscribe and independently consume.

Asynchronicity and independence rule out C# delegates and, at the same time, don't impose any technology. For example, we don't want to state that those events must be messages on a queue.

## Beliefs

In chatting with many people, the belief goes along the lines of: It's the communication protocol that causes coupling.

That means that swapping the communication protocol for something that, on paper, promises less or no coupling is the solution to all coupling-related issues.

Let me use a couple of examples. Two components, A and B, communicate by storing data in a database table. A writes some data, which B then reads to continue the business process.

Oh! They use the same storage, and if A and B were (micro)services, that's bad. They are coupled with the same technology and many other irrelevant (pardon my candor) things. The decision is to remove that coupling by, e.g., replacing the communication protocol with HTTP, gRPC, some obscure JSON-based stuff, messages on a queue, or events on a broker.

The problem is that coupling doesn't go anywhere, and things might worsen. What was a monolith with some coupling could transform into a distributed monolith with coupling in the same places, creating many new problems.

## Where should we focus instead?

Events should be the natural consequence of something else, not the primary goal. We should focus on [autonomous components and service boundaries](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html). Finding service boundaries is the first step. That alone enables the defining of autonomous components. At this point, we'll realize that the natural way for autonomous components to communicate, especially across service boundaries, is by using thin events carrying only identifiers and no other data.

If we start from the end by introducing events first when the service boundaries are ill-defined, we're destined to face the dreaded "how do I get the data stored in that other service that I need here now to perform my task" question. There can only be three answers:

- Let's expose a RESTful API to allow querying for the needed data.
- Let's share the needed data using the events and messages we're already sending or publishing.
- Maybe our service boundaries are wrong.

It's tough to accept the truth that service boundaries are wrong. It's much more tempting to conclude that we can expose an API to allow querying for the needed data or replicate it across services using events the system is already publishing.

Unfortunately, not recognizing that the boundaries are wrong leads to designing a distributed monolith affected by schema and temporal coupling to begin with.

It's also crucial to understand that it's not a monolithic process. We don't need to sort out all boundaries perfectly. Then, define all the autonomous components. And finally, determine who publishes what and who subscribes. It's a messy process that leads to rough boundaries or isolates one or more services from the rest of the system. By looking at the relationships between the identified services and components, it's possible to start crafting some events. We're ready to return to the drawing board and address another portion of the system. The other critical part is that we should not fear any rework of previously identified boundaries and components, which might lead to reshaping events.

It's a difficult task. That's one of the reasons we need to work in a stable domain; otherwise, it's like building on the sand. Identifying solid boundaries is nearly impossible if the ground moves under our feet, and we cannot count on solid foundations.

## Conclusion

There is little to no chance that coupling will magically disappear by introducing events into a random system architecture. Events are the natural consequence of getting rid of coupling by correctly identifying service boundaries first. And if coupling doesn't go away by introducing events, if we feel the need to share data via those events, or by exposing cross-service APIs, that indicates that we're working with ill-defined service boundaries. In those cases, do not try to hammer in events; instead, focus on service boundaries first.

---

## Video resources

- [Finding your service boundaries: a practical guide](https://particular.net/webinars/finding-your-service-boundaries-a-practical-guide), by [Adam Ralph](https://twitter.com/adamralph).
- [Autonomous microservices don't share data. Period](https://particular.net/videos/autonomous-microservices-dont-share-data), by [Dennis van der Stelt](https://twitter.com/dvdstelt).
- [All our aggregates are wrong](https://particular.net/webinars/all-our-aggregates-are-wrong), by me.

---

Photo by <a href="https://unsplash.com/@art_maltsev?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Artem Maltsev</a> on <a href="https://unsplash.com/photos/person-holding-wand-on-top-of-bowl-3n7DdlkMfEg?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
