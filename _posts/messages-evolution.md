---
layout: post
author: Mauro Servienti
title: "Distributed systems evolution: message contracts"
synopsis: "Evolving distributed systems architecture is challenging. If the system is message-based, the first challenge comes from evolving message contracts."
header_image: /img/posts/messages-evolution/header.jpg
enable_mermaid: true
series: distributed-systems-evolution
tags:
- distributed-systems
---

In [Distributed systems evolution challenges](https://milestone.topics.it/2022/06/11/distributed-systems-evolution-challenges.html), we analyzed many situations we must face and be aware of when evolving distributed systems.

As I said, I work for [Particular Software](https://particular.net), the makers of [NServiceBus](https://docs.particular.net/tutorials/quickstart/), a messaging middleware aiming to ease the usage of messaging and queues when designing distributed systems.

I'll assume the system we need to evolve is a message-based one. It's indeed true that many of the discussed techniques apply to other technologies like HTTP or gRPC, where the exchanged payload is similar to messages.

## Evolving messages

In the [previous article](https://milestone.topics.it/2022/06/11/distributed-systems-evolution-challenges.html), we discussed the direction of the changes. We mentioned that it's generally better to start applying changes from the inside and then gradually move to the outside.

Applying the inside-out technique to message evolution means changing receivers before publishers/senders. Let's take into account a subset of the scenario outlined above:

<div class="mermaid">
sequenceDiagram
   Rest API ->> Backend: Queue message
</div>

We want to update the Backend endpoint first, and once that's in production, we can apply changes to the API endpoint.

### Message exchange and contracts sharing

At this point, we need a little digression to dive a bit into how messages are exchanged between endpoints. In the .NET world, there is a preference for strong typing. Developers prefer using C# classes, as presented above, to define messages. Those classes, which effectively are contracts, are generally shared across endpoints as NuGet packages. The `SubmitRequest` type is built into an assembly, packaged into a NuGet package, and referenced by the different endpoints using it to communicate.

When evolving systems requires evolving contracts, we face the messages update dilemma. In the above-presented scenario, if we change the contract and package it, both senders and receivers can (and probably will) upgrade. However, we don't want that; we want to ensure we upgrade receivers first and senders after that. The easiest but fragile option is to use a policy like "hey sender, please, refrain from updating until we say you can." As you can imagine, it might not be a solid choice.

### On the wire, types don't matter

The fact that we're sharing a class library with contracts is convenient but not mandatory. When a sender endpoint sends a message, the message payload is serialized and transmitted to the queuing system alongside headers, one of which is the serialized message type name. 

The queuing infrastructure knows nothing about classes and types. The recipient endpoint receives the message at the destination and deserializes it using the types it knows about and matching them with the incoming header that specifies the message type. That means we don't need to share classes. We only need to make sure the type at the sender is more or less the same as the receiver. "More or less" because many serializers are flexible and easily pleased.

We could have senders defining a class that matches the type of the receiver without sharing them using, for example, assemblies and NuGet packages. We don't generally do that because it comes with the complexity of keeping them in sync when changes occur, and there is a preference for simplicity and easy living.

When evolving messages with non-breaking changes, we can take a more straightforward approach. We don't have to go down the rabbit hole of defining the same type multiple times for different endpoints. Let's have a look at what we can do.

### Evolving messages: non-breaking changes

The first and most straightforward change is a non-breaking change to message contracts. For example, imagine that the HTTP API allows clients to submit requests to kickoff some process. Requests contain some data, and new requirements expand the set to include additional data. That means we must extend messages and Rest APIs to include new data. Currently, the system uses the following message to submit requests from the API to the backend service:

```csharp
public class SubmitRequest
{
   public int RequestType { get; set; }
}
```

The new requirement also allows users to select the payment method. That means adding a new property to the above message:

```csharp
public class SubmitRequest
{
   public int RequestType { get; set; }
   public int PaymentType { get; set; }
}
```

We don't want to extend the original contract. That might complicate things because we have no control over other endpoints' upgrades.
The easiest thing to do is to create a separate message instead of extending the existing one:

```csharp
public class SubmitRequestV2
{
   public int RequestType { get; set; }
   public int PaymentType { get; set; }
}
```

The `SubmitRequestV2` can be packaged in the same NuGet package as the `SubmitRequest` message. Suppose we're paranoid and want to be truly safe. In that case, we could define the message as `internal` and use the `InternalsVisibleTo` attribute to ensure the message is visible only to the receiver endpoint. Once the `SubmitRequestV2` is in place, we add a new message handler to the receiver endpoint and deploy it to production.

The receiver endpoint can now handle the new process requirement. However, no one can send the new message yet. At the same time, the handler and logic for `SubmitRequest` are still in place, so the receiver will continue to handle in-flight messages as expected.

We're now ready to update sender endpoints. If we previously deployed the new message version as `internal`, we're prepared to make it `public` and update our documentation.

Teams owning sender endpoints can update their processes at their own pace. We'll gradually see less usage of the `SubmitRequest` message handler and an increase in usage of the `SubmitRequestV2` handler.

#### When enough is enough

At this stage, a good question is: how do we know when we can stop supporting the `SubmitRequest` message? The easiest answer is that we never drop support for it. If code and requirements change at an incredibly low speed we could be in a position to keep the code around forever. Otherwise, we have to define an obsoletion policy. Our team publishes a policy stating that we'll support the `SubmitRequest` message for a certain amount of time, after which we'll treat it as an error. We can do that by decorating the message with the .NET `Obsolete` attribute alongside some documentation updates.

### Where does the receivers' responsibility end?

The last thing to address is how to handle situations like: we stopped supporting the message, but somehow, more are coming. We have done all that we described so far. However, when the time comes, and we remove the handler for `SubmitRequest` from the receiver endpoint, we notice that messages are still arriving by looking at logs. For example, if you are using NServiceBus, logs will contain an error message like the following:

> No handlers could be found for message type: _message type_

_Source: <https://github.com/Particular/NServiceBus/blob/master/src/NServiceBus.Core/Pipeline/Incoming/LoadHandlersConnector.cs#L27>_

That means not all senders have been updated to use the new message version. Or there are still in-flight messages. Even though we removed `SubmitRequest` from the NuGet package, there are no guarantees that other teams will update sender endpoints and stop using the old message type.

Let's acknowledge that we're safe using a tool like NServiceBus. Failed messages will be moved to the error queue and not lost. However, if we retry them, they'll end up in the same receiver queue and fail again.

It's not a receiver problem, though. Senders are not respecting the published policy by sending unsupported messages. What receivers can do is reject the message with accompanying supporting data. For example, a receiver could reply with a message like:

```csharp
public class UnsupportedMessageType
{
   public byte[] RawReceivedMessage { get; set; }
   public string RejectReason { get; set; }
}
```

When that happens, the sender will receive a message for which there is no handler, causing the message to end up in the configured error queue. At this point, it becomes a sender problem, as it should.

## Do we necessarily need to create different messages?

The quick response is no; we don't. There are other ways to evolve message contracts. For example, we could be using message inheritance or multiple inheritance using .NET interfaces. I'm not sure those techniques provide more value, given the effort, compared to creating new contracts. It's worth looking at them anyway to see the available options.

### Message inheritance

Using the above message as an example, what we could do to evolve it is the following:

```csharp
public class SubmitRequestV2 : SubmitRequest
{
   public int PaymentType { get; set; }
}
```

We're using inheritance to extend the original message. This technique works only for non-breaking changes. The advantages are that senders can immediately stop sending version 1 of the message, but recipients can still receive it. The deserialization process will happily deserialize `SubmitRequestV2` into `SubmitRequest`, with data loss, even though that might be irrelevant for some receivers.

### Multiple inheritance using interfaces 

Another option, to begin with, is to define contracts using interfaces instead of classes. For example:

```csharp
public interface ISubmitRequest
{
   int RequestType { get; set; }
}
```

Senders can the define an internal class that implements the above interface:

```csharp
class SubmitRequestImpl : ISubmitRequest
{
   public int RequestType { get; set; }
}
```

Receivers define handlers for the interface and not the class. That enables the sender to define a second interface to define the new requirement:

```csharp
public interface ISubmitRequestV2 : ISubmitRequest
{
   int PaymentType { get; set; }
}
```

and finally, extend the message implementation:

```csharp
class SubmitRequestImpl : ISubmitRequestV2
{
   //omitted for clarity 
}
```

As you can imagine, that can lead to some neat tricks because .NET interfaces can be used to simulate multiple inheritance. That means senders can define one class that implements multiple interfaces. Receivers know about interfaces only, and the serializes of choice will apply the required magic to deserialize the message at the destination correctly.

## If it's so powerful, where's the washout?

Inheritance is a powerful technique that significantly simplifies senders' and publishers' life. There is no need to deal with different contracts and send/publish additional messages in parallel during the transition period. Senders and publishers can immediately use the latest version, and inheritance will make so receivers can still receive the old versions.

The transition period might be tricky for receivers. Let's imagine you're using NServiceBus, and you have a message handler like the following:

```csharp
public class SubmitRequestHandler : IHandleMessages<ISubmitRequest>
{
   public Task Handle( ISubmitRequest message, IMessageHandlerContex ctx )
   {
      // do something interesting from the business perspective 
   }
}
```

If the process of handling the new version is different enough, a receiver might define another handler in the same endpoint:

```csharp
public class SubmitRequestHandler : IHandleMessages<ISubmitRequestV2>
```

At this point, when messages are received and deserialized, they'll match both handlers, and two different business processes get executed. That might not be what we want. On top of that, the two handlers will be invoked in the same transaction, causing even more headaches.

That means using inheritance might require more changes than we like. In some cases, those changes could be tricky, like trying to understand the actual type of the messages we're handling and skipping the processing steps in some scenarios. I prefer to skip this option and use different messages altogether.

## Conclusion

We have many options to evolve message contracts. Depending on the need, we could create new messages, extend existing ones, or use multiple inheritance to solve complex puzzles. Be aware not to introduce more complexity than needed. My suggestion is to create new messages regardless of whether it's a breaking change or not. It's the more straightforward approach and solves the problem in many cases.

---

Photo by [Sue Hughes on Unsplash](https://unsplash.com/photos/toQNPpuDuwI)