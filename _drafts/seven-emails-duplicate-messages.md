---
layout: post
title: "Seven emails later: duplicate messages are not a theoretical problem"
author: Mauro Servienti
synopsis: "Duplicate messages are often dismissed as a corner case. My inbox disagrees. Let's look at how duplicates happen, sent, received, or processed more than once, and what we can do about them."
header_image: /img/posts/seven-emails-duplicate-messages/header.jpg
tags:
- messaging
- distributed-systems
---

Whenever I discuss duplicate messages with people new to distributed systems, the usual reaction is that it's more theoretical than common. "Sure, in theory. But how often can it really happen?"

Often enough to land in my inbox.

![ShippyPro screenshot](/img/posts/seven-emails-duplicate-messages/shippypro-inbox.png){:class="img-fluid mx-auto d-block w-75"}

The above screenshot is from my inbox. I'm a bike rider, and a couple of years ago, I bought a new pair of Favero power meters. For those unfamiliar, they look like regular MTB pedals, but they measure the power your legs generate while pedaling, along with several other, more or less interesting metrics. Enough said about bike pedals with power meters.

What matters is what happened after the order. I received seven emails, one every few minutes, all related to the same shipment. On the surface, they all looked identical. Examining the SMTP headers made it clear they were different messages, sent one after the other.

Nothing terrible happened. I got slightly annoyed, archived six emails, and moved on. However, replace "send a shipping notification" with "charge a credit card" or "ship a pair of pedals", and the conversation changes.

## What's a duplicate message?

In distributed systems, a duplicate message is one that is sent, received, or processed more than once. Or all of that at once.

The distinction matters because each scenario has different causes and different remedies. Let's analyze them.

## Sent more than once

A sender might be sending the same message multiple times. In this scenario, two major things can happen.

### The trigger is processed more than once

The sender processes the same trigger more than once, resulting in duplicate messages with different message identifiers.

That might be cryptic; let's use an example to clarify.

A web application processes an HTTP request that should send a message. The web application sends the message, but then fails to respond to the HTTP client. Maybe the process crashes, maybe a load balancer times out, or maybe the network drops the response. From the client's perspective, the request failed, so it retries. The web application processes the request again and dispatches the message again. If the web application can't tell it's the same incoming HTTP request, it ends up sending two or more messages that are identical except for the message identifier. I discussed retries in the absence of an incoming message in ["Ooops, can I try again, please?"](https://milestone.topics.it/2021/01/21/ooops-can-I-try-again-please.html).

From the receiver's perspective, those are two legitimate, distinct messages. Nothing in the infrastructure can tell them apart.

### Non-atomic batches

The sender is designed to send multiple messages, but the underlying infrastructure doesn't support atomic batching. If one message fails, the sender resends all of them.

This may be less cryptic; let's discuss an example anyway.

Let's expand on the previous example. The web application sends the message it needs to send. The receiver handles it and, as a result, needs to send three messages. The system relies on Amazon SQS, which supports batching but not atomic batching. The receiver sends the three messages in a batch, and the infrastructure responds with two successes and one failure.

What now? The simplest option is to fail the whole operation and retry. The incoming message goes back to the queue; it's processed again, and the three messages are sent again. The two that succeeded the first time are now duplicates. Depending on how the outgoing messages are created, they may or may not share the identifiers of the first attempt.

## Received more than once

Most queuing systems offer at-least-once delivery guarantees. The keyword is "at least". The infrastructure promises to deliver the message; it doesn't promise it will deliver it only once. At-least-once delivery has interesting consequences on message ordering too, as I described in ["Isn't A supposed to come before B?"](https://milestone.topics.it/2021/10/20/isnt-a-supposed-to-come-before-b.html).

For example, a receiver gets a message from the queue and processes it. Before it can acknowledge the message, the connection to the broker drops, or, in the case of SQS, the visibility timeout expires. From the broker's perspective, the message was never handled, so it makes it available again. The same receiver, or another competing instance, gets it a second time.

The main difference from the email example is that these duplicate messages are identical, on the surface and under the hood. If the message has a message identifier, each duplicate will have the same identifier. That's good news, as we'll see shortly.

## Processed more than once

The last scenario is the sneakiest one. The message was received once, but processing ran more than once.

A handler receives a message, updates the database, sends an email, and then something fails: the database transaction can't commit, the acknowledgment fails, or the process crashes. The message is retried, as it should be, and the handler runs again. The database changes are rolled back, so from a data perspective, everything is fine. The email, however, is already out there. You can't roll back an email.

Retries are a feature: they are one of the main reasons to use messages and queues in the first place. But retries and non-transactional side effects don't mix well. Each retry is a chance to repeat whatever happened before the failure, and it can't be undone.

## What can we do about it?

First, accept that duplicates will happen. Designing as if they won't is a bet against the network, the infrastructure, and the laws of physics. The house always wins. We can make sure duplicates are harmless.

### Take control of the message identifier

If the sender can send the same message multiple times and doesn't use an outbox, take control of the identifier and keep it stable.

Instead of letting the infrastructure generate a new identifier for every send operation, derive it from something stable in the triggering context. For example, an idempotency key provided by the HTTP client, or a combination of business identifiers. With NServiceBus, it could look like the following:

```cs
var options = new SendOptions();
options.SetMessageId($"shipment-{shipmentId}-notification");

await messageSession.Send(new SendShipmentNotification(shipmentId), options);
```

Now, if the HTTP request is retried, the message is sent again, but with the same identifier. We moved from duplicates indistinguishable from legitimate messages to duplicates that are identical. We turned the "sent more than once" problem into a "received more than once" problem, and we know how to solve that.

### Use an outbox

The outbox pattern stores outgoing messages in the same transaction as the business data, and dispatches them afterward. It solves the non-atomic batch problem: messages are dispatched from the outbox until all succeed, with stable identifiers, and no business logic runs twice. I wrote about it in more detail in ["What's an Outbox and why do we need it?"](https://milestone.topics.it/2023/02/07/outbox-what-and-why.html).

On the receiving side, the outbox also tracks processed message identifiers. When a message with an already-processed identifier arrives, the business logic is skipped, and the system re-dispatches outgoing messages only if needed. That's how "received more than once" becomes harmless.

When the trigger is an HTTP request rather than an incoming message, the [NServiceBus transactional session](https://docs.particular.net/nservicebus/transactional-session/) brings the same guarantees to the sending side. I recently built [Zusammen](https://milestone.topics.it/2026/10/21/zusammen.html), a transactional session for Node.js. It's a good reminder that dispatch is still at-least-once: receivers must be idempotent unless they have outbox support.

### Make the business logic idempotent

Deduplication based on message identifiers only works when duplicates share the same identifier. When they don't, the only option left is to look at the business data.

Is there already a notification for this shipment? Then don't send another one. Is this order already in the "shipped" state? Then shipping it again is a no-op. Often, designing operations to set state ("the order is shipped") rather than to apply changes ("ship the order once more") makes idempotency come almost for free. More on idempotency, and its limits when third parties are involved, in ["Safety first!"](https://milestone.topics.it/2019/05/02/safety-first.html).

### Be careful with side effects

Emails, payments, and calls to third-party APIs are side effects that a database transaction can't roll back. For each one, you have a choice: send it at most once, risking never sending it, or at least once, risking sending it multiple times. There is no free lunch. A common approach is to move the side effect into a dedicated handler that receives a message whose only job is to perform that side effect, record that it happened, and do nothing else. It narrows the window in which a failure can cause a duplicate, and makes it easier to reason about. In the worst case, this dedicated handler lives in a separate endpoint with no retries. If processing fails once, the failing message goes straight to the error queue, and an operator decides what to do about it. If the third party supports idempotency keys, like most payment gateways do, use them.

## Conclusion

I don't know what happened behind the scenes of my seven shipping notifications. It could have been a retried trigger, a redelivered message, or a handler retried after the email was already gone. Any of the scenarios described above can produce exactly what landed in my inbox.

I know duplicate messages aren't theoretical. They are a matter of when, not if. The difference between a well-designed system and a poorly designed one isn't the absence of duplicates; it's whether anyone notices them.

In my case, I noticed. Seven times.

## Additional resources

- ["Businesses don't fail, they make mistakes"](https://milestone.topics.it/2019/09/10/businesses-dont-fail-they-make-mistakes.html): sooner or later, failed messages end up in the error queue. This article discusses the difference between infrastructure failures and business failures, and why the latter shouldn't be handled like the former.
- ["Transactions? None for me, thanks"](https://milestone.topics.it/2021/01/30/transactions-none-for-me-thanks.html): queues are designed for reliability, but there are rare cases where unreliable message processing is the right choice. This article explores one of them, using an endpoint configured with no transport transactions.

---

Photo by <a href="https://unsplash.com/@dr_eigelb?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Benjamin Genz</a> on <a href="https://unsplash.com/photos/a-row-of-empty-chairs-sitting-in-a-parking-lot-EW--dYi6Z_A?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
