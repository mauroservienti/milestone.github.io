---
layout: post
title: "Define messages as POCO, interfaces, or records. Does it really matter?"
author: Mauro Servienti
synopsis: ".NET developers building message-based systems seem to give serialization and surrounding concerns more importance than needed. Let's try to dissect the topic"
header_image: /img/posts/defining-messages/header.jpg
tags:
- messaging
---

Let me get this straight: There are design dilemmas that are weapons of mass distraction. Or, if you prefer, they are honey, attracting developers like the sirens did with Ulysses.

Now that I said what I wanted let me try to articulate that better. In the context of distributed systems and messaging, serialization enters the stage to handle the transformation of object instances into something that can be transferred on the wire.

> More details about messages in [Back to basics: Commands, events, and messages](https://milestone.topics.it/2023/05/25/back-to-basics-messages.html).

For example, take the following JavaScript object:

```javascript
var person = {
  "firstName": "Mauro",
  "lastName": "Servienti"
};
```

To transfer it on the wire as the body of a message on a queue, we need to transform it into something like this:

```json
{
  "firstName": "Mauro",
  "lastName": "Servienti"
}
```

The result in the JavaScript case is similar to the source object and can be obtained using the `JSON.stringify(person)` method.

Serialization and its counterpart deserialization are pretty straightforward. We start from an object instance and get some text representation in the case of JSON. Through deserialization, we can reverse the process. From the text representation, we obtain an object instance.

> There are plenty of serialization formats, all with pros and cons. They are not the topic of this article. Even if, sometimes, I feel they are also weapons of mass distraction 🤪

## What should we use to define messages?

When dealing with message-based systems and .NET, the problem is finding the best coding structure to define messages and later serialize and transfer them on the wire.

Shall we define messages as regular C# classes (aka [POCO, plain old CLR objects](https://en.wikipedia.org/wiki/Plain_old_CLR_object))? Are interfaces better? Or do the recently introduced records obsolete everything else, and we should rewrite our systems?

> I've witnessed people breaking friendships over those discussions. It's as hot as tabs vs spaces. It's spaces, obviously! 🤪

## POCO

One could say (and I'm one of them), "Keep it simple, stupid!" ([KISS](https://en.wikipedia.org/wiki/KISS_principle)) and use POCO classes. For example:

```csharp
public class OrderAccepted
{
   public string OrderNumber { get; set; }
}
```

The presented class represents an event in a system dealing with orders. It comes with a few potential flaws that are worth listing (in no particular order):

1. The `OrderAccepted` type is mutable. After deserializing the message, a receiver can change the `OrderNumber` property value. And that might even be worse because an event must be immutable (for the purists), considering it represents the past.
2. [Contracts evolution](https://milestone.topics.it/2022/07/04/messages-evolution.html) might be tricky because using classes makes adopting a multiple inheritance approach difficult, if not impossible.

A quick solution to the first problem could be to use a private setter for the public properties, or some similar approach, and a constructor that allows setting those property values once at initialization time:

```csharp
public class OrderAccepted
{
   public OrderAccepted( string orderNumber ) => OrderNumber = orderNumber;
   public string OrderNumber { get; private set; }
}
```

That's neat, even if it's more verbose and might limit the serializer choice: We can only select serializers supporting setting private or read-only properties and capable of using non-default or private constructors.

## Interfaces

What sounds like a better way to define the `OrderAccepted` event is by using an interface.

Messaging libraries like [NServiceBus support sending messages as interfaces](https://docs.particular.net/nservicebus/messaging/messages-as-interfaces) primarily to support multiple inheritance. At runtime, the library creates a dynamic proxy class that implements the interface, allowing code like the following:

```csharp
await endpoint.Send<IMyMessage>(message =>
{
    message.SomeProperty = "Hello world";
}).ConfigureAwait(false);
```

In the above snippet, the `message` instance is the proxy type instance presented to the code as `IMyMessage`.

With that in mind, can we define the `OrderAccepted` event as follows?

```csharp
public interface OrderAccepted
{
   string OrderNumber { get; }
}
```

If we could, we'd have solved both the mutability issue of the POCO class and we'd be supporting multiple inheritance. Unfortunately, we cannot. If we were to use such an interface, the following code wouldn't compile:

```csharp
await endpoint.Publish<OrderAccepted>(message =>
{
    message.OrderNumber = "123ABC";
}).ConfigureAwait(false);
```

The `OrderNumber` property is "get" only. It cannot be set. The interface works well for the message receiver rather than for the sender. The solution is to avoid creating the dynamic proxy class at the sender and instead have an explicit implementation:

```csharp
internal class ConcreteOrderAccepted : OrderAccepted
{
   public string OrderNumber { get; set; }
}
```

The `ConcreteOrderAccepted` class is defined in the same project as the publisher, and it's not shared with subscribers/receivers. The interface is shared as a contract. It is private to the publisher that can use it as follows:

```csharp
OrderAccepted evt = new ConcreteOrderAccepted
{
    OrderNumber = "123ABC"
}

await endpoint.Publish( evt ).ConfigureAwait(false);
```

It solves the listed concerns, but it's incredibly lengthy, and it requires some governance to explain to team members how to create and publish those concrete classes. This approach has no limitations on the serializer choice, which might compensate for the verboseness.

## Records

With C# 9, .NET introduced support for `record` types. That means we could be defining the `OrderAccepted` event as follows:

```csharp
public record OrderAccepted
{
   public string OrderNumber { get; init; }
}
```

I love records to define messages. They are concise and super-expressive. They are immutable but not perfect:

1. Contract evolution remains an unsolved issue.
2. Not all serializers play nicely with records. Even though being records a built-in .NET feature, most serializers will support them over time.

## Who's faster? 

I don't know; it doesn't matter as an absolute, out-of-context question. When I wrote [Know your limits. Infinite scalability doesn't exist](https://milestone.topics.it/2022/05/30/know-your-limits.html), I intended to look at performance from the system design perspective. In this case, my point of view doesn't change. If the system handles ten messages every minute, choosing a faster serializer or avoiding dynamically generated proxies will not change much. Sure, message handling might be 20 milliseconds faster for each message, but does it matter?

If your answer is yes, it matters, then go ahead and test the performance of the various options on the table.

On the other hand, if the system needs to be crazy fast and handles hundreds of thousands of messages per minute, optimizing every bit of the message-handling process makes a lot of sense. It's the hot path; if performance is critical, it deserves attention.

## Conclusion

When it comes to defining messages, we have many options. Each one has its pros and cons. To complicate the choice, we have to factor in serializers—they might not be compatible with the chosen message definition choice.

The matter becomes even more complex if we try to evolve an existing system and discover that the production serializer races against us.

If we're using a tool like NServiceBus we can [gradually change the serialization format](https://docs.particular.net/samples/serializers/transitioning-formats/) or [move to a different serializer without redeploying](https://docs.particular.net/nservicebus/serialization/#specifying-additional-deserializers) the whole system at once.

Tools like NServiceBus help—we know that a decision is not set in stone, and we can evolve later. That said, evaluating all the options and how they impact the system design is critical before making a choice.

---

Photo by <a href="https://unsplash.com/@ekrull?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Eric Krull</a> on <a href="https://unsplash.com/photos/black-vinyl-record-on-black-vinyl-record-fi3_lDi3qPE?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
