---
layout: post
author: Mauro Servienti
title: "Distributed systems evolution challenges"
synopsis: "What are the challenges posed by evolving distributed systems architecture? In this short series of articles, we'll understand the critical factors we should be keeping an eye on and how to address them."
header_image: /img/posts/distributed-systems-evolution-challenges/header.jpg
enable_mermaid: true
series: distributed-systems-evolution
tags:
- distributed-systems
---

Version one of the system is happily running in production, and everything proceeds as expected. The business comes and raises some new requirements. The team's first reaction is, "no problem we can handle those." They are breaking changes; however, they are in the context of a single service boundary.

That shouldn't come with headaches. We designed everything keeping an eye on service boundaries and controlling coupling. Endpoints share data only within the context of a service boundary. That makes services autonomous and free to evolve.

> This website is primarily about service-oriented architecture. I dissect autonomous services and their benefits in [Not all changes are born equal](https://milestone.topics.it/2021/03/10/not-all-changes-are-born-equal.html) and [Is it complex? Break it down.](https://milestone.topics.it/2022/01/03/is-it-complex-break-it-down.html)

## Not so fast

Before proceeding with the changes, the team analyzes the requirements and the current situation in production. The idea is to lay out all the steps required to move from where we stand today to the new desired state.

The service in question is responsible for a long-running task; imagine something like image OCR processing. Clients submit processing requests through an API and wait, asynchronously, for responses on a WebSocket connection.

> If you're interested in understanding how to implement long-running processes in a distributed system architecture, check out ["The case of NServiceBus long running jobs: OCR Processing."](https://milestone.topics.it/2016/12/20/the-case-of-nservicebus-long-running-handlers-ocr-processing.html)

The following is a synthetic representation of the structure of the service:

<div class="mermaid">
sequenceDiagram
   Web client ->> Rest API: HTTP request
   Rest API ->> Backend: Queue message
   Backend ->> Long-running process: Trigger long-running process
   Long-running process ->> Database: Manipulate data
   Long-running process ->> Backend: Process completed
   Backend ->> Rest API: Topic event
   Rest API ->> Web client: WebSocket message
</div>

The changes requested by the business affect most of the above structure. The new process requires more data and a couple of changes to existing data. It'll require changes to the inputs and the processing logic.

What's immediately apparent to the team is that some of the changes are breaking and others are not. The team is mainly concerned about the upgrade process that must deal with currently ongoing operations. When the upgrade happens, there will be in-flight messages flowing from the public-facing API to the backend, and more importantly, there will be backend processing instances running. Both in-flight messages and instances of running processes are handling the previous messages and data format.

It sounds like one of those cumbersome problems that can only give rise to a headache. If we try to address it in its entirety, that's a given. However, we can chop it up and analyze each piece in isolation to see if we can solve them one by one. As said, we want to break it down and solve more straightforward problems one by one.

## What does evolution mean?

When we require evolving a system, we generally need to apply changes to the following things:

- Messages: messages flow from one endpoint to another, carrying information. When processes change, they might need different data. In such cases, it's likely messages need to evolve.
- Data structures: as processes change, so do the supporting data structures. In distributed systems, when using tools like NServiceBus, [saga](https://docs.particular.net/nservicebus/sagas/) data instances are an example of those structures.
- Supporting input/output devices: when the system changes, to operate with different data, it needs other input forms, visualization, and reporting structures.

Those are the three main areas we'll have to deal with when evolving distributed systems. Those are not the only challenges, though. For each area presented, we have to understand the direction of the change, the change type, and the deployment requirements.

## What's the change direction?

For monolithic architecture, the change direction is irrelevant. For the sake of the sample, let's imagine a system that is well-componentized and deployed monolithically in production. To deploy, we stop the current version, deploy the new one, and start again. From the development point of view, changing the database schema before the user interface or the other way around doesn't matter that much.

The reality is a bit different when we're dealing with a distributed architecture, and we need to be able to deploy changes with little to no downtime.

If we can afford to stop the system before the deployment, even if it's a distributed system, we can manage it as if it wasn't.

If we cannot shut down the system, the direction of the changes is crucial. If we were to update and deploy the user interface before the database schema, we'd be sending data into the void for a while. On the other end, if we were to apply the schema changes first, we're faced with the issue of how to deal with data coming from the user interface not matching the new schema.

My rule of thumb for distributed systems is that changes flow from the inside to the outside. For example, we change the database schema first and then the user interface and understand how to deal with incompatible data.

## Changes types

The change direction is not the only thing we want to consider. The type of change is critical too. We have two main categories:

- Breaking vs. non-breaking changes.
- Retroactive vs. non-retroactive changes.

### Breaking vs. non-breaking changes

As the name implies, breaking changes are changes that break the contract between two or more endpoints. For example, a breaking change breaks the message wire compatibility preventing endpoints from communicating. E.g., the system is moving from a message like:

```csharp
class SampleMessage
{
   string ID;
}
```

to one like the following:

```csharp
class SampleMessage
{
   Guid ID;
}
```

The type change of the ID property from `string` to `Guid` makes messages incompatible. If a receiver endpoint expects the ID property to be a string, it cannot deal with a different type.

At the same time, one could argue that all changes are breaking. For example, if the above message evolved like the following:

```csharp
class SampleMessage
{
   string ID;
   int AnotherValue;
}
```

Technically speaking, it's not a breaking change. However, receivers need to adapt to the new incoming data to fulfill the business requirements connected to the additional information. This second one doesn't qualify as a breaking change, though. It could be that a publisher updates the information it publishes, adding a few more data. One of the many subscribers corrects its behavior to handle the new data structure. All the others don't. They are not interested in the additional attributes. They'll continue to work even though additional data are coming in because the changes don't break the message's wire compatibility.

### Retroactive vs. non-retroactive changes

The second type of change is more subtle and, I'd argue, less frequent. It's worth mentioning it, though. There are scenarios in which the changes must be retroactive. That means they apply to in-flight messages and currently running processes. One example is when the change corrects a previous mistake. The current process doesn't adhere to the business rules, and thus when applying the fixes, we also have to fix running processes and in-flight messages. Usually, fixing running processes involves some data migration. It's trickier to fix in-flight messages since we cannot patch data stored in a queue. We need to intercept and fix messages when picked up and before processing starts.

## What about no-downtime side-by-side deployments?

The last topic, but no less critical, is how we need or can deploy changes. We laid out all the steps to apply the necessary changes; it's time to deploy. Can we shut down the service that needs updating, or do we need to keep it running while the upgrade occurs? That's a crucial question. Looking at it from a different point of view, it's asking: will we have different versions of the same service running simultaneously in production or not? We don't need to deal with the so-called side-by-side deployment in most cases. However, in the rare instance we need, it's essential to understand the challenges.

Stay tuned for future articles. They'll be grouped in the [Distributed systems evolution series](/series/distributed-systems-evolution). If you feel I missed something, do not hesitate to leave a comment.

---

Photo by [Steven Lelham on Unsplash](https://unsplash.com/photos/atSaEOeE8Nk?utm_source=unsplash&utm_medium=referral&utm_content=creditShareLink)
