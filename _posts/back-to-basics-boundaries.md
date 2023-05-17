---
layout: post
title: "Back to Basics: service boundaries, autonomous components, and coupling"
author: Mauro Servienti
synopsis: "When you're involved with something for a very long time, it's easy to fall into the trap of taking many concepts for granted. Let's go back to the basics and build a common foundation. Today's topics are service boundaries, autonomous components, and coupling."
header_image: /img/posts/back-to-basics-boundaries/header.jpg
tags:
- soa
- architecture
- back-to-basics
---

Domain Driven Design (DDD) folks talk a lot about bounded contexts. Service Oriented Architecture (SOA) people discuss service boundaries as if there is no tomorrow. Something must be interesting about those _"fences"_ and the separation they continuously discuss. But what is that, and why is it so important?

## Coupling

Let's take a step back and understand first the real problem we're trying to address. But first things first, the [Wikipedia definition for coupling is](https://en.wikipedia.org/wiki/Coupling_%28computer_programming%29):

> In software engineering, coupling is the degree of interdependence between software modules; a measure of how closely connected two routines or modules are; the strength of the relationships between modules.

The consequence of the provided definition is that the higher the interdependence, the harder it'll be to independently evolve the coupled modules or routines. In itself, coupling is not a problem. It becomes an issue in the context of a continuously evolving software system. When we write it once and never touch it again, it doesn't matter if it's highly-coupled spaghetti code.

Service-Oriented Architecture design comes to the rescue with three constructs at different granularity levels. They are (from the most granular to the least granular):

- Autonomous components
- Business components
- Services

## Autonomous components

Autonomous components are the smallest unit. They are usually stateless; if there is a state, it's typically elementary with no transitions. It's a zero or one kind of thing. They are triggered by one specific request, usually a command-like type.

Autonomous components are the single responsibility principle (SRP) incarnation in Service-Oriented Architecture design. They do only one thing.

Creating a new user account is a good example. There is an incoming command, the requests to create a new user, and the autonomous component limits itself to doing what it's been programmed for. At the end of its task, it'll announce the task completion by, for example, publishing an event or replying to the caller.

## Business components

Business components are generally stateful and characterized by more than one state transition. They are triggered by more than one command or event.

If an autonomous component creates users, a business component creates users too. However, the main difference is the business meaning of the user creation process.

An autonomous component is responsible for the sole step of adding the new user to the database, for example. A business component is accountable for the whole user creation process, which includes more steps.

It'll include logic to decide what to do if a user with the same username already exists. It'll handle the user's email confirmation process, etc. All the creation tasks will be physically performed by autonomous components and orchestrated by a business component.

The business component performs no tasks; it'll decide the next step and offload the execution to an autonomous component.

## Services

A service is a logical collection of autonomous and business components. They share a common business purpose. Following our example, the autonomous component creating users and the business component responsible for the user creation process belong to the same user management service.

> For a detailed explanation of what "logical" means in this context, look at [Let's get logical! On logical and physical architectural views](https://milestone.topics.it/2022/01/25/lets-get-logical.html)

### Service boundaries

As a consequence of services' existence, a service boundary is a _virtual_ fence that protects services from being _contaminated_ by components not belonging to them. It also prevents leakages. Components belonging to a service won't leak into other services.

## More in-depth articles

I discussed services, components, and coupling from various perspectives in the past. Here is a non-exhaustive list of articles covering the mentioned topics:

- In [Not all changes are born equal](https://milestone.topics.it/2021/03/10/not-all-changes-are-born-equal.html), I look at what coupling is and how it affects or doesn't various parts of the system based on the type of changes we're facing.
- [There is no such thing as orchestration](https://milestone.topics.it/2021/07/08/no-orchstration.html) looks at orchestration and the inherited coupling it brings to the table.
- The focus is on cache misuse leading to cumbersome implementations in [Own the cache!](https://milestone.topics.it/2021/07/15/own-the-cache.html).
- [Update me, please](https://milestone.topics.it/2021/08/03/update-me-please.html) takes an entirely different point of view and looks at a notification system and its relationship with coupling.
- [Distributed systems evolution challenges](https://milestone.topics.it/2022/06/11/distributed-systems-evolution-challenges.html) is a short series of articles detailing the challenges and options to evolve a live distributed system and the role played by coupling.
- [How many (micro)services do I need?](https://milestone.topics.it/2023/03/15/how-many-services.html) discusses what happens when we go crazy and end up with too many autonomous and business components and too many services.
- Last but not least, [Autonomy probably doesn't mean what you think it means](https://milestone.topics.it/2022/09/05/autonomy.html) discusses the autonomy concept as the other side of the medal of coupling.

## Conclusion

When designing software systems, we have many tools at our disposal. They range from practical ones, like programming languages or integrated development environments (IDEs), to more meta types of tools, like the architectural constructs discussed in this article. All of them are critical for success. Architectural constructs like autonomous and business components, or services and service boundaries, are particularly helpful in defining virtual fences to avoid concepts belonging to different business concerns from leaking and melting into each other, creating a spaghetti mess.

Photo by <a href="https://unsplash.com/@benhershey?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Ben Hershey</a> on <a href="https://unsplash.com/photos/8KaU5I4SBIw?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
