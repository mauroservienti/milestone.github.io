---
layout: post
title: "What's an Outbox and why do we need it? Hint: it's about data integrity"
author: Mauro Servienti
synopsis: "Distributed systems are ugly beasts sometimes. They hide subtle tricks that can lead to data loss and system corruption. The Outbox pattern helps address a couple of them."
enable_mermaid: true
header_image: /img/posts/outbox-what-and-why/header.jpg
tags:
- messaging
- distributed-systems
---

When the software industry invented transactions and distributed transactions, the game changed. Suddenly, it was possible to guarantee that a set of operations was atomic. An all-or-none approach became the norm, greatly simplifying the engineers' work. Doing backflips to get consistency became a thing of the past. The transaction coordinator took responsibility for all that.

How does that influence a message-based system? Let's take a look at the following diagram:

<div class="mermaid">
graph LR
    E[Endpoint] -- store data --> DB[(database)]
    E -- send message --> MSMQ
</div>

The presented endpoint needs to store some data and send a message. It uses MSMQ and SQL Server. At runtime, they will both enlist in a distributed transaction, making it so that both operations will be atomic and consistent. If for some reason, one of the operations fails, everything is rolled back. The system won't send messages and won't change any data. That's very handy, and it makes things so simple.

It comes at a cost, though. Transactions are expensive, and distributed transactions are even more costly. They have a performance impact because getting all the participants into an agreement takes time. As you can imagine, the more participants, the greater the effect. Last but not least, transaction protocols rely on high network stability. Poor network connectivity hinders participants' ability to participate in the distributed transaction coordination process. That means it's unlikely cloud environments support distributed transaction protocols.

All this means that the above diagram only works in a cloud environment if the database server runs on the same machine where the MSMQ is installed. This sounds illogical because that means the only option to use distributed transactions is to have all participants on the same box, which is precisely what we don't want in the cloud.

## Back to the drawing board

What do we need? The requirement is to guarantee that outgoing operations are atomic with other operations happening in the context, or not, of an incoming message. Wow, hold on, that's a lot.

Let's dissect that. We could be in one of the following scenarios:

<div class="mermaid">
graph LR
    E[Endpoint] -- store data --> DB[(database)]
    E -- send messages --> Q[Queuing system]
</div>

In the first one, there isn't an incoming message. For example, an HTTP request could trigger the endpoint to send out the message.

Instead, in the second scenario, we are in the context of an incoming message. The trigger is a message:

<div class="mermaid">
graph LR
    M[Incoming message] --> E[Endpoint]
    E -- store data --> DB[(database)]
    E -- send messages --> Q[Queuing system]
</div>

Despite looking more complex, the second is more straightforward. We'll talk about that.

Up to this point, the critical bit is that we must guarantee that both operations succeed or fail. We don't want to store data and not send out messages or the other way around. We want atomic operations without distributed transactions.

## Enter the outbox

Conceptually, an outbox is as simple as storing outgoing messages in the same storage where we keep data using a local transaction and only send them to the queuing infrastructure afterward. Unfortunately, the implementation is more complex.

If messages are stored in the same storage with business data and only later sent, we need to mark them as sent somehow. We cannot do that in the same transaction we use to store; otherwise, we're back to the original problem. We cannot guarantee the send operation and the mark as read operation to be atomic.

All that means we could be in a situation where an endpoint successfully stores data and messages (the intent to send them) in the storage but fails to deliver them to the queuing system. Or it could dispatch them but fail at marking messages as delivered.

A temptation could be to use a background task. The endpoint could run a task on a background thread to check the storage for unsent messages and deliver them. However, more is needed to solve the problem. We cannot have a transaction that spans the two resources at play. It also introduces a new undesirable side effect: if the endpoint is scaled horizontally, multiple background threads will look at the same storage for undispatched messages. All of them will find messages to dispatch. To coordinate, they need a distributed transaction. Otherwise, we'd have to accept that they might send multiple copies of the same message.

## The incoming message is our best friend

It's in that context that an incoming message is beneficial. We can use incoming messages as resource coordinators. Why is that? Primarily because message identifiers are stable over time. If an endpoint retries the same message multiple times, it'll have the same message id. If the queuing infrastructure is "at least once," it could deliver multiple copies of the same message. All copies will have the same message-id.

With an incoming message when the endpoint receives it, we could perform the following steps:

1. Start a local transaction and store the message id in the outbox storage.
  * The storage has a unique index on the message identifier.
2. Handle the message from the business logic perspective, for example:
  * Store some business data enlisting in the same local transaction
  * Send a couple of messages (remember that these are dispatch intentions stored in the same storage enlisting in the same local transaction)
3. Commit the local transaction making sure that:
  * Data are safely stored.
  * Messages we want to send are in the outbox storage.
  * The incoming message id is in the database too.
4. Send messages we want to send and mark them as sent (outside the original local transaction).
5. Acknowledge the incoming message, deleting it from the queue.

If anything between 1 and 3 fails, the local transaction gets rolled back, no changes are applied, and the endpoint will retry the incoming message.

If what fails are either steps 4 or 5, the endpoint picks up the message again. The outbox already contains the message identifier, stored at the first step and committed at step three. The outbox treats it as an "already processed message for which something went wrong." In this mode, the endpoint skips invoking the users' business logic and jumps to step 4, sending outgoing messages, marking them as sent, and finally acknowledging the incoming message.

As you can imagine, this can happen repeatedly—the outbox guarantees, in most scenarios, an exactly once processing behavior. The same message can be delivered multiple times, no matter the reason, and the outbox protects the endpoint from processing it more than once.

In that sense, the outbox behaves as an inbox too. Storing the incoming message identifier is what allows the message deduplication process.

## Hold on! Did you say in most scenarios?

Unfortunately, we cannot solve all scenarios using an outbox-like approach. For example, let's imagine the message being a payment processing request. The payment processor is a remote third-party service we invoke via HTTP, and we're using Amazon SQS or RabbitMQ, which support "at least once" delivery. That means we need an outbox to deduplicate incoming messages and guarantee consistency when delivering and storing data. In essence, we want to charge users' credit cards only once.

HTTP is an ugly beast. The worst nightmare is when the response times out. The message handler processing the "charge the credit card" message successfully issues the HTTP request to the remote web endpoint, but the response times out. Now what? Did it succeed? Did it not? An outbox doesn't help answer those questions.

If the remote HTTP endpoint was idempotent, we needed no deduplication support. If it's not idempotent, HTTP invalidates any attempt to deduplicate incoming messages.

What can we do? Very little. [Disable retries and get over it by designing a process that tries only once](https://milestone.topics.it/2021/01/30/transactions-none-for-me-thanks.html).

## I don't have an incoming message. Am I without hope?

As we said, the outbox solves two problems—incoming messages deduplication and outgoing and storage operations consistency. It sounds like incoming messages are beneficial to the outbox implementation. What if we're not so lucky and don't have an incoming message?

<div class="mermaid">
graph LR
    HC[HTTP Client] -- HTTP Request --> E[HTTP Endpoint]
    E -- store data --> DB[(database)]
    E -- send messages --> Q[Queuing system]
</div>

We could be doing the same thing for the "regular" inbox/outbox scenario with an incoming message with a few tweaks. Let's recap the outbox steps first:

1. Start a local transaction and store the message id in the outbox storage.
2. Handle the message from the business logic perspective and store any message dispatch intent.
3. Commit the local transaction.
4. Send messages we want to send and mark them as sent (outside the original local transaction).
5. Acknowledge the incoming message, deleting it from the queue.

Not having an incoming message changes things a bit. We need a way to start a local transaction to store data and dispatch intentions. If we cannot use the incoming message to trigger the local transaction, we could use an ASP.NET middleware that begins the local transaction when the HTTP request starts. We can use the same middleware to decide when to commit the transaction, and that is when the HTTP request finishes. With that set, we can tweak the endpoint steps in the following way:

1. When the HTTP request starts, start a local transaction.
2. Handle the request and store any message dispatch intent.
3. Commit the local transaction.
4. Send messages we want to send and mark them as sent (outside the original local transaction).

Now, what if we fail at step four? We're in trouble because we need something to hook on to retry. There is no incoming message. If step four fails, the HTTP request fails. Theoretically, we could retry the incoming HTTP request, but that's only an in-memory retry logic. What if step four "fails" because we never reach step four, and the web application crashes right after committing the local transaction?

We could borrow some of the "outbox with an incoming message" logic and do the following:

1. The middleware starts a local transaction when the HTTP request starts.
2. Handle the request and store any message dispatch intent.
3. Send a control message to ourselves.
4. Commit the local transaction.
5. Send messages we want to send and mark them as sent (outside the local transaction opened at step one).

In step three, the endpoint sends a control message to itself. When received, the role of the control message is to check if step five succeeded in dispatching and marking messages as dispatched. If not, it'll deliver messages. At this point of the flow, we're in the same scenario of an "outbox with an incoming message." If the control message is faster than the local transaction commit phase, it'll find nothing, the regular message retry logic will kick in, and it'll eventually succeed.

Now, let's look again at failure scenarios for other steps of the process:

- Step one, two, or three fail: We do nothing; the HTTP request's endpoint allows the exception to bubble up to the HTTP client, for example, with an HTTP 500. It's a common synchronous request/response failing scenario. Since it happens inside a transaction, the endpoint rolls back every change, and the system remains consistent and will dispatch no messages.
- Step four fails: Similar to the previous scenario, if the endpoint fails in committing the local transaction, everything is left unchanged, and an error will bubble up to the client. However, the control message will arrive at the local queue. It'll find nothing because there were no changes. It'll retry a few times and eventually end up in the error queue, where it can be safely discarded.
- Step five fails: The control message will retry dispatching outgoing messages. As we saw earlier, it's a regular outbox at this point.

## Conclusion

When using a queueing system and at the same time storing data, sometimes we need to guarantee consistency. We don't want to store data and fail in dispatching messages, nor do we wish to deliver messages and fail in storing data. We relied on distributed transactions for a long time to achieve the desired goal. However, most queuing infrastructures and cloud-enabled storages don't support distributed transactions. It takes a lot of work to implement, especially if there is a need to support multiple storage options and queuing systems. That's one of the reasons to rely upon a dedicated toolkit. For more information, please refer to the following articles:

- [NServiceBus Outbox](https://docs.particular.net/nservicebus/outbox/)
- [NServiceBus Transactional session](https://docs.particular.net/nservicebus/transactional-session/)

---

Photo by <a href="https://unsplash.com/ko/@dele_oke?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Dele Oke</a> on <a href="https://unsplash.com/photos/P1I67ke0bAU?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
