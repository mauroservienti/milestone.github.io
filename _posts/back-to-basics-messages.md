---
layout: post
title: "Back to Basics: commands, events, and messages"
author: Mauro Servienti
synopsis: "When you're involved with something for a very long time, it's easy to fall into the trap of taking many concepts for granted. Let's go back to the basics and build a common foundation. Today's topics are commands, events, and messages."
header_image: /img/posts/back-to-basics-messages/header.jpg
tags:
- messaging
- architecture
- back-to-basics
---

I often find myself talking about distributed systems and message-based architecture. Ultimately, it's been my focus for the last 15 years. I realized, though, that I often take basic concepts for granted. For example, I assume there's clarity about the differences between commands, events, and messages.

In the long term, a lack of clarity can lead to misunderstandings and suboptimal implementations that might be hard to fix.

People used to dirt their hands with message-based architecture, and distributed systems often refer to commands and events. But what are they, and why are they so important?

When it comes to commands and events, it's all about semantics and logical concepts.

## There are only messages

Let's start with the first essential concept. Everything on the wire is a message. From the queueing system perspective, they are all messages. There is no distinction between commands and events. And that's true regardless of the infrastructure we're using. For example, Amazon Simple Notification Service (SNS) is a broadcasting service dealing with topics and subscriptions. Still, what travels on the wire are messages.

Messages are some form of representation of a higher-level concept. They can be text messages, for example, a json or xml string, or binary messages, like a byte array. There might be restrictions, but generally, the underlying infrastructure cares very little about message format.

## With messages come message headers

More than messages alone is required. Like when we send a message in the real world, we need some surrounding metadata. For example, a text message from a mobile phone requires the recipient's phone number. A letter requires the recipient's postal address. And in both cases, the recipient receives the sender's address. The mobile phone sends it automatically, and we write our address on the envelope.

The same concept applies to messages in a queueing system. In reality, messages are composed of two pieces: message bodies and message headers. The body is the message content. Headers are the additional metadata the infrastructure or our system requires to function correctly.

For example, in RabbitMQ, one of the headers is `reply-to`. Publishers can use it to declare the address receivers can use when replying.

## Messages are not expressive enough

The reader probably noticed that I mixed up a few terms. I used senders and publishers interchangeably and never used subscriber, but always recipient. That needs to be clarified, and we want to avoid confusion. The issue is that each queuing system comes with its terminology. For example, RabbitMQ has no senders, they are all publishers, and there is no "send" API. Instead, the only option is to publish messages. Something similar applies to Amazon SNS.

When discussing architecture, we want to be as clear as we can. Misunderstandings are dangerous. At the same time, we want to avoid any technology-dependent language. We have yet to decide on a specific technology or prefer not to pollute the architecture with technical details.

Using terms like command, event, and message is preferable to identify messages and their kind. Sender, receiver, publisher, and subscriber to define actors in the system and their role.

### Commands

Commands are imperative verbs. "Charge the credit card," "proceed to checkout," or "publish the newsletter" are valid commands.

Commands are one-to-one. A sender sends a command to a receiver. Commands are intended for a particular receiver. Specificity is vital in this context. A command like "charge the credit card" is unlikely to have different recipients. Different senders might dispatch the same command, though. For example, placing an order using the online store sends the "charge the credit card" command, and the same goes for placing orders by phone.

### Events

Events represent the past. "The credit card was charged," "checkout started," or "newsletter published" are valid events.

Events are one-to-many. A publisher publishes an event to zero or more subscribers. A specific publisher publishes events. It's unlikely different publishers will publish the same event.

## Receivers own commands. Publishers own events

One could argue that if we can place orders by phone or online, the "order placed" event could be published by the online ordering process and by the telephone ordering one. True, but that comes with confusion. It's more straightforward if the online process publishes the "online order placed" and the phone one publishes a different event.

If different publishers could publish the same event, subscribers must inspect the incoming message to determine whether they are interested. It's a waste.

Similarly, if different recipients could handle the same command, senders would be required to have logic to determine where to send messages. It needs to be evident who the receiver is.

For those reasons, it's commonly accepted that recipients own commands and publishers own events. Recipients own commands because they own the business logic to process them. Publishers own events because they own the business logic to determine when and why to publish them.

### Why is ownership significant?

We can use ownership to determine who drives changes in the system. For example, a recipient changes a command because the processing logic changes. The changes will percolate down to senders. The opposite applies to events, publishers, and subscribers. For more information on distributed system changes and evolution, look at the [distributed systems evolution article series](https://milestone.topics.it/series/distributed-systems-evolution.html).

## Events cross service boundaries. Commands don't.

Events are, by definition, immutable. They represent something that happened in the past. And the past cannot be changed. Events are good candidates for cross-boundaries communication.

> For an introduction to services, boundaries, and components, please, refer to "[Back to Basics: service boundaries, autonomous components, and coupling](TODO-add-link)."

When crossing a boundary, we're leaving a well-known territory to explore somewhere under someone else's control, a different service. We want to ensure they trust we won't move around the cheese. The second important aspect is that we have no control over someone else lawn. A service cannot tell another service, "Do this for me," it can only broadcast to those interested that something happened.

### Messages

Finally, there are messages. But those are different messages than seen from the queueing system perspective.

> It might not be obvious, I know. I already discussed the [linguistic limitations](https://milestone.topics.it/2021/09/15/linguistic-limitation.html) our industry faces.

There are scenarios where we need to respond to someone, but the response qualifies neither as a command nor an event. It might signal that something happened, but it's not an _event_ we want to broadcast; it's intended for a specific audience. For example, an endpoint that processes credit card payments receives a command to charge a particular credit card for a certain amount. Once done, it'll send a reply message to the original sender reporting the outcome of the operation. The sender might publish an event like `OrderPaid` or `OrderCanceledDueToPaymentFailure`. Those are more meaningful events than an `AmexChargeOperationSucceded` or `AmexChargeOperationFailed`.

The presented scenario is a typical request/response one. It has pros and cons. I recently discussed the [pitfalls of request/response over messaging](https://milestone.topics.it/2023/01/19/pitfalls-of-request-response-over-messaging.html).

## Conclusion

Disconnection from the technology we'll use is critical when thinking about message-based systems. Different queuing infrastructures have slightly different interpretations of messages and events, and most don't take commands into account. At the same time, we need to represent message-related concepts in the architecture. Commands, events, and messages are the perfect abstraction. They are decoupled from the underlying technology but still grounded in messaging.

---

Photo by <a href="https://unsplash.com/@beckyphan?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Becky Phan</a> on <a href="https://unsplash.com/photos/BVYRU3aFKsU?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
