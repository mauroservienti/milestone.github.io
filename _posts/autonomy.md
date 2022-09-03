---
layout: post
title: "Autonomy probably doesn't mean what you think it means"
author: Mauro Servienti
synopsis: "There seems to be some misunderstanding around the word 'autonomous' when used in the context of distributed systems. Unfortunately, there is no unique meaning, it depends on the context and the observer's point of view. It might not mean what you think."
header_image: /img/posts/autonomy/header.jpg
tags:
- soa
- distributed-systems
---

I was sure I had already written on the topic, but my search-fu was failing me. I need a way to better index all my articles. I'm open to suggestions.

That being said, let's get into today's topic — autonomy in a service-oriented architecture.

One question I get asked frequently is:

> If a service has to publish an event to allow a different service to move forward, how can it be autonomous? Doesn't the event couple the services?

I briefly touched on the topic in ["Not all changes are born equal."](https://milestone.topics.it/2021/03/10/not-all-changes-are-born-equal.html) However, the discussion was about bad and good coupling. I didn't dive into what it means for a component or a service to be autonomous.

Coupling and its counterbalance, autonomy, are subtle topics. They sometimes feel esoteric and philosophical, and they probably are. However, it's essential to master them to navigate the turbulent waters of distributed systems architecture.

In [Welcome to the (State) Machine](https://milestone.topics.it/talks/welcome-to-the-state-machine.html), I present a scenario in which a service demands an event from another service.

In the talk, I present a ticket reservation system sample. There is a scenario in which, at checkout time, the amount due is authorized on the customer credit, but the remaining part of the process fails. The immediate reaction is to ask the failing service to publish an "I failed in doing X" event.

I define that as a source of coupling hurting autonomy, other than having more nuanced issues. At the same time, the services happily share other events without showing any coupling issues. What's the difference?

## What is autonomy?

We first need to understand what autonomy is. Autonomy refers more to the internals of a component rather than to the externals. The open/closed principle is an "inverse" instance of that: extensions should be allowed without the need to modify the internals. When that's the case, the opposite is also true: a component can change its internals without affecting others. The component is autonomous.

How does that apply to distributed systems? We can view it in the following way: components are autonomous when they are free to evolve internally. They can change their behaviors, add new behaviors, and have complete control over the data structure they decide to use and possibly change over time. All those changes won't affect other components in the system.

Is it always possible to design autonomous components? No, when it's not possible, coupling surfaces. When we're trying to develop a distributed system, lack of autonomy, and thus coupling, is generally caused by sharing too many internal details of the wannabe autonomous components. That can be in the form of sharing data impeding data schema changes, leaking technical information (e.g., the type of the storage), allowing other components to make assumptions about the behaviors, etc.

Is that a problem? It depends. That's why we define service boundaries. If two or more components are somewhat coupled within the boundaries of a service, this is way less of a problem than if there is coupling across services. Being coupled across services hurts autonomy much more than within a single service boundary.

### Why is that?

The assumption is that autonomous components are easier to maintain and evolve. They are also easier to deploy because they won't affect other parts of the system. Based on business concerns, we can group components into services: Components dealing with similar business requirements will live in the same service boundary (it's probably simplistic, but it's good enough for today's discussion).

Services inherit components' autonomy making them autonomous too. If coupling surfaces within service boundaries across components, that service will be more complex to maintain, evolve, and deploy. If coupling surfaces across services, the entire system will.

## What about the business?

One thing that usually goes under the radar is the following sentence:

> Components dealing with similar business requirements will live in the same service boundary

That translates to "business requirements couple components." That's business coupling.

If requirements couple components, continuing on the same path, the business couples services. They exist because the business needs them. If there is no need to deliver goods to customers, there won't be a shipping service.

That being said. The next question could be:

> Do they know each other?

Sure they do. Otherwise, the business doesn't exist.

Continuing the e-commerce analogy, if Shipping doesn't know about Sales, there wouldn't be a way to sell and deliver stuff. The business needs to sell goods, deliver them to customers, and, for example, keep under control how the overall process behaves. That is what couples services together.

The mentioned business coupling in a distributed systems architecture is expressed by events crossing service boundaries. Those events are special events. [Alberto Brandolini](https://twitter.com/ziobrando), the [event storming](https://www.eventstorming.com/) inventor, calls them _Pivotal Events_. A pivotal event allows a system to move to a new state. Examples are: checkout started, order delivered, order canceled, new customer created, etc.

> More details and examples about pivotal events are available in the excellent [Domain-Driven Design Use Case: Improving A Life Insurance Selling Platform](https://www.blog.jamesmichaelhickey.com/DDD-Use-Case-Life-Insurance-Platform/) by [James Hickey](https://www.blog.jamesmichaelhickey.com/).

## The business doesn't care about coupling

At this point, we have a problem. The business doesn't pay any attention to the type of coupling we consider harmful from the architectural perspective. Some forms of coupling might be interesting from the business perspective. For example, depending on a single supplier might be an issue. However, they don't consider the dependencies between Sales and Shipping as a concern.

But we do! And that implies that we look at autonomy with different eyes.

Back to the type of coupling and autonomy concerning the architecture: If events are what connect services, it's crucial to keep them as thin as possible and to respect their immutable nature. That translates into a "share nothing" policy. I expect an OrderDelivered event to look like the following:

{
  orderId;
  customerId;
  deliveryTypeId;
}

Usually, nothing else. That event type reduces coupling to its minimum. It's improbable that any of the shared information changes over time. The critical part is that the primary key structure is not supposed to change so we can share identifiers. Or, if that changes, it will be such a disruptive process that coupling is a breeze.

## Alarm bells

How do we determine if something shared across service boundaries hurts autonomy? My general approach is to look at the request using the open/closed principle lenses. Does the request imply sharing internals of service? Does the request cause data to leak? Does the demanding service request data that is not interesting for the owing service?

## Conclusion

Autonomy and coupling go hand in hand. If one increases, the other diminishes. The more the coupling, the less autonomy, and vice versa. However, the tricky part is that they both change their meaning based on the observer's point of view. As for events, when it comes to coupling and autonomy, we have a [linguistic issue](https://milestone.topics.it/2021/09/15/linguistic-limitation.html). However, we have good guiding questions to help up detect that something is off.

---

Photo by <a href="https://unsplash.com/@hdbernd?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Bernd Dittrich</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
