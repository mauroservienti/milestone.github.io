---
layout: post
author: Mauro Servienti
title: "AsyncAPI, a tool in our toolbox"
header_image: 
synopsis: "Distributed systems governance is a hot topic. At first, it might feel overwhelming. It's important to understand what we need to govern and which tools can help."

header_image: /img/posts/asyncapi-tool-in-our-toolbox/header.jpg 
tags:
- distributed-systems
- soa
---

Last summer, I delivered a distributed systems workshop for a local user group. A common question attendees raise during this type of training is governance-related.

What generally happens is that attendees are exposed to concepts like pub/sub and event-driven architectures, in many cases for the first time. The immediate reaction is to imagine their current systems rearchitected using the presented paradigms. The number of events they can think about quickly becomes overwhelming, and they immediately forecast a governance problem.

There is no doubt distributed systems come with governance concerns. The number of moving parts is significantly higher than with different types of architecture. And with a lot of moving parts, understanding and mastering governance is a must.

Let's go back to the initial concern, for a second: the number of events. 

It's expected. The first time we encounter new technology, we risk using it as a hammer, and everything becomes a suitable nail. And that's especially true for the system we are working on right now. We get excited by the opportunity of immediately applying what we are learning.

When it comes to events, not all events are born equal. The event sourcing persistence pattern uses domain events, and then there are pub/sub-events. Pub/sub is not descriptive enough, though. [Like for async](https://milestone.topics.it/2021/09/15/linguistic-limitation.html), we also have a linguistic limitation with the word event.

When it comes to pub/sub, I like how [EventStorming](https://blog.avanscoperta.it/2014/02/12/introducing-event-storming/) presents the different types of events.

Pivotal events are particularly relevant for our discussion.

When it comes to event-driven architecture and distributed systems, it's common to identify hundreds, if not thousands, of events during the analysis phase. However, the large majority of the identified events are relevant within the boundaries of a specific service. Only a handful of them is destined to cross boundaries. Those are the key events that move the overall system state forward, the EventStorming Pivotal Events.

All that is not to say there is no need for governance for events that live within a service boundary. It is expected that the team owning the service has full knowledge and control over those events, leading to less need for formal widely-accepted governance.

On the other hand, events that cross service boundaries are critical. They are owned by a service team and consumed by several other teams and services. In such a situation, governance is crucial, primarily from the consumer's perspective.

In the .NET ecosystem, the de facto standard is NuGet. A publisher defines its events in a .NET project shared as a NuGet package. Usually, the project is named something like "MyServices.Messages.Events", or a variation of that, making it simple for subscribers to find message packages by searching for `*messages*`.


A NuGet package alone might not be enough. We could be in a situation where some documentation detailing the reasons for the events or their business meaning might still be something teams need. A documentation repository thus becomes an essential governance part.

Publishers can also decide to follow [Semantic Versioning (SemVer)](https://semver.org) to help packages users understand a contract's evolution.


Sharing contracts as NuGet packages containing .NET assemblies comes with a downside, though. It creates platform coupling. Subscribers need to be .NET projects to reference a .NET assembly.

What if one endpoint uses NServiceBus, and another Ruby or Python? [NServiceBus supports cross-platform integration via native message processing](https://particular.net/blog/cross-platform-integration-with-nservicebus-native-message-processing). However, we still need to share contracts in some way. And as said, sharing a .NET assembly between Ruby, or Python, and .NET is not an option.

## Services share schema and contract, not class

What publishers share with subscribers using NuGet packages, for example, are schemas and contracts. By chance, we respect the SOA third tenet using C# classes or interfaces to define the mentioned contracts. However, despite being indeed comfortable, that's not a requirement.

[AsyncAPI](https://www.asyncapi.com) is a protocol-agnostic specification designed to describe asynchronous APIs:

```yaml
asyncapi: 2.2.0
info:
  title: Account Service
  version: 1.0.0
  description: This service is in charge of processing user signups
channels:
  user/signedup:
    subscribe:
      message:
        $ref:'#/components/messages/UserSignedUp'
components:
  messages:
    UserSignedUp:
      payload:
        type: object
        properties:
          displayName:
            type: string
            description: Name of the user
          email:
            type: string
            format: email
            description: Email of the user
```

(from AsyncAPI's samples)

The presented YAML document describes the `UserSignedUp` event much better than what a NuGet package with a C# class and accompanying documentation can do, if only for the simple fact that everything is in the same document.

The second interesting aspect of the AsyncAPI specification is the community-driven set of generators. For example, there is a [template to generate C# code from an AsyncAPI YAML document](https://github.com/jonaslagoni/asyncapi-quicktype-template). There are also generators to output HTML documents for a documentation website.

The fact that all information is in a single place, the YAML document, and that there are generators available allows teams to share AsyncAPI specs documents instead of C# compiled artifacts. Once consumers and producers reference the YAML files, they can apply the templates to transform them into C# classes or interfaces.


The advantage of this approach is that it entirely removes platform coupling from the equation. The system can be polyglot. Each endpoint can be coded using the platform and the language of choice.

## Conclusion

In many cases, we're sharing NuGet packages and .NET assemblies when we need to share message contracts because that's the simplest thing we can do. Not to mention that it's also a scenario well supported by the toolchain in use, for example, Visual Studio or JetBrains Rider. There are scenarios in which the limitations imposed by the generated platform coupling are a blocker. AsyncAPI might come to the rescue and save the day.


---

Photo by <a href="https://unsplash.com/@polarmermaid?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Anne Nygård</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
