---
layout: post
title: "Idempotent, you must be. A deep dive into idempotency"
author: Mauro Servienti
synopsis: "Duplicate messages are a fact of life, and idempotency is the usual answer. But what does idempotent really mean, and why is it harder than checking whether we've already done something? Let's dive in."
header_image: /img/posts/idempotency-deep-dive/header.jpg
tags:
- messaging
- distributed-systems
---

In 2019, in ["Safety first!"](https://milestone.topics.it/2019/05/02/safety-first.html), I wrote that idempotency comes with a couple of footnotes. The first one was: "no one tells the truth about how hard it can be."

Seven years later, it's time to tell the truth.

In ["Seven emails later"](https://milestone.topics.it/2026/10/24/seven-emails-duplicate-messages.html), I described how duplicate messages happen: sent, received, or processed more than once. The conclusion was that duplicates are a matter of when, not if, and that the goal is to make them harmless. Idempotency is how we make them harmless. Idempotency is mentioned in many of my posts, yet it never had a post of its own. Let's fix that.

## What does idempotent mean, really?

The math definition says that an operation is idempotent if applying it multiple times has the same effect as applying it once. Pressing the elevator call button is idempotent. Pressing it ten times doesn't bring ten elevators, no matter what impatient people think.

In a message-based system, the definition needs a small but critical extension. Processing the same message multiple times must:

- leave the system in the same state as processing it once;
- produce the same observable effects as processing it once.

The second point is the one we tend to forget. Observable effects include outgoing messages, emails, calls to third-party systems, and anything else that leaves the boundaries of the handler. A handler that correctly avoids storing the same data twice, but publishes the same event twice, isn't idempotent. It moved the problem downstream.

## Some operations are idempotent by nature

Let's start with the good news. Some operations are naturally idempotent:

- "Set the product price to 120" is idempotent. Doing it twice results in a price of 120.
- "Increase the product price by 10" isn't. Doing it twice results in a price increased by 20.

The difference is in how the message is designed. Messages that carry absolute values, or that describe a desired state, tend to result in naturally idempotent handlers. Messages that carry deltas, or that describe an action to apply, tend to require extra work.

That's a good design principle. However, it's not always possible. Charging a credit card, shipping a parcel, and sending an email are actions, and there is no way to express them as a state. Even when it's possible, as we'll see shortly, naturally idempotent isn't always safe.

## The "check, then act" trap

When an operation isn't naturally idempotent, the usual approach is to check whether we've already done it. Let's look at a handler shipping orders:

```csharp
public async Task Handle(ShipOrder message, IMessageHandlerContext context)
{
    var alreadyShipped = await db.Shipments.AnyAsync(s => s.OrderId == message.OrderId);
    if (alreadyShipped)
    {
        return;
    }

    db.Shipments.Add(new Shipment(message.OrderId));
    await db.SaveChangesAsync();

    await context.Publish(new OrderShipped(message.OrderId));
}
```

It looks reasonable. If the order is already shipped, the handler does nothing. What could possibly go wrong?

Concurrency. Most systems scale out by running multiple instances of the same endpoint, competing for messages on the same queue. If two copies of the same message are delivered at about the same time, two instances can run the check at the same time. Both find no shipment. Both create one.

The check and the act must be atomic. The database is usually the best tool for the job:

- **A unique constraint.** If the `Shipments` table has a unique index on `OrderId`, the second insert fails. The message is retried, and the retry finds the existing shipment.
- **Optimistic concurrency.** If the handler updates an existing record, a version column makes the second concurrent update fail.
- **Conditional writes.** Many document databases and key-value stores support writes that succeed only if a condition holds, for example, if the document doesn't exist yet.

In all cases, the losing attempt fails, the message goes back to the queue, and the retry takes the "already done" path. Retries are our friends here.

## Don't forget the outgoing messages

Let's assume the unique constraint is in place. There is still a problem with the above handler. Let's look at the following sequence:

1. The handler stores the shipment, and the transaction commits.
2. The process crashes before publishing `OrderShipped`.
3. The message is retried.
4. The handler finds the shipment and returns.

Nobody will ever know the order was shipped. The billing service won't send the invoice, and the customer won't get a notification. Skipping the business logic on a duplicate is correct. Skipping the outgoing messages isn't.

When a handler detects it already processed a message, it must still produce the same outgoing messages. Ideally, with the same message identifiers, so that receivers can recognize them as duplicates. With NServiceBus, it could look like the following:

```csharp
public async Task Handle(ShipOrder message, IMessageHandlerContext context)
{
    var alreadyShipped = await db.Shipments.AnyAsync(s => s.OrderId == message.OrderId);
    if (!alreadyShipped)
    {
        db.Shipments.Add(new Shipment(message.OrderId));
        await db.SaveChangesAsync();
    }

    var options = new PublishOptions();
    options.SetMessageId($"order-shipped-{message.OrderId}");

    await context.Publish(new OrderShipped(message.OrderId), options);
}
```

Now, regardless of how many times the message is processed, the system ends up with one shipment and one `OrderShipped` event identity. Receivers might get the event more than once, but always with the same identifier, and they can deduplicate it.

If this sounds like a lot of work for every handler, it's because it is. That's precisely what the outbox pattern automates. It stores outgoing messages in the same transaction as the business data, deduplicates incoming messages by identifier, and re-dispatches the stored outgoing messages if needed. I described how it works in ["What's an Outbox and why do we need it?"](https://milestone.topics.it/2023/02/07/outbox-what-and-why.html).

## Naturally idempotent isn't always safe

Let's go back to the good news. "Set the price to 120" is idempotent. Is it safe? Let's look at another sequence:

1. Sales sends "set the price to 100", and the handler processes it.
2. The broker redelivers the message later, for example, because the acknowledgment got lost.
3. In the meantime, Sales sends "set the price to 120", and the handler processes it.
4. The redelivered "set the price to 100" message arrives and is processed again.

The price is now 100. Each message, taken individually, is idempotent. The combination of duplicates and out-of-order delivery isn't. I discussed message ordering in ["Isn't A supposed to come before B?"](https://milestone.topics.it/2021/10/20/isnt-a-supposed-to-come-before-b.html), and this is one of the scenarios where it bites.

A common solution is to version the data. The owner increments a version every time the price changes and includes it in the message. The receiver ignores messages carrying a version older than, or equal to, the one it already has:

```csharp
public async Task Handle(ProductPriceChanged message, IMessageHandlerContext context)
{
    var price = await db.Prices.SingleAsync(p => p.ProductId == message.ProductId);
    if (message.Version <= price.Version)
    {
        return;
    }

    price.Amount = message.Amount;
    price.Version = message.Version;
    await db.SaveChangesAsync();
}
```

Duplicates and stale messages are now harmless. The same optimistic concurrency considerations apply: the version check and the update must be atomic.

## Deduplication doesn't last forever

Deduplication based on message identifiers requires storing the identifiers of processed messages. Storage isn't infinite, so identifiers are kept for a while and then removed. With NServiceBus, for example, the [outbox expiration duration](https://docs.particular.net/nservicebus/outbox/#outbox-expiration-duration) depends on the chosen persistence and can be configured.

What happens when a duplicate arrives after its identifier has been removed? It's processed as a brand-new message. That can happen, for example, when an operator retries a failed message from the error queue after a few weeks.

The retention period must be longer than the longest time a message can be retried. And for the operations where a duplicate is costly, it's worth having business-level idempotency as a second line of defense. The unique constraint on `OrderId` doesn't expire.

## Idempotency at the edges

Everything so far assumes there is an incoming message. What about HTTP requests?

The same principles apply, but the client must help. HTTP clients retrying a `POST` can't be distinguished from clients sending a new request, unless they send an identifier. That's the purpose of idempotency keys: the client generates a unique key for each logical operation and sends it, for example, in an `Idempotency-Key` header. There's an [IETF draft standardizing the header](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/). The server stores the key with the outcome of the first request and returns the same outcome for subsequent requests with the same key.

The key can then become the stable message identifier for any message the request sends, turning the "sent more than once" problem into a "received more than once" problem, as discussed in ["Seven emails later"](https://milestone.topics.it/2026/10/24/seven-emails-duplicate-messages.html).

The same applies when we're the client. When calling a third-party service, such as a payment gateway, pass our own idempotency key if the third party supports it. If it doesn't, there is nothing we can do to make the call idempotent, and we're back to choosing between at-most-once and at-least-once.

## Conclusion

Idempotency isn't a checkbox. It's a property of the whole message-handling process: state, outgoing messages, and side effects. Checking whether something has already been done is a starting point, but it isn't enough on its own. The check must be atomic with the action, duplicates must still produce the same outgoing messages, and stale messages must be told apart from new ones.

The good news is that we don't have to do it all by hand. Designing messages to describe state, versioning data, and relying on an outbox remove most of the burden. What remains, side effects that can't be undone, needs explicit design.

Idempotent, you must be. Now you know why it's hard ;-)

---

TODO: header image and credits
