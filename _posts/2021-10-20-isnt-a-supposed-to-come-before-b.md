---
layout: post
header_image: /img/posts/isnt-a-supposed-to-come-before-b/header.jpg
title: "Isn't A supposed to come before B? On message ordering in distributed systems."
enable_mermaid: true
author: Mauro Servienti
synopsis: "We are used to lists, sequences, and procedural approaches. We are constantly under the impression that what we do is ordered. That's not the case. Why are we trying to replicate into software architectures a non-existent ordering?"
tags:
- soa
- distributed-systems
- message ordering
- FIFO
---

If we look at the micro-scale and investigate two correlated events, it's probably easy to spot that one comes before the other. There is a sequence: A comes before B. On the other end, if we look at the macro-scale investigating hundreds or thousands of events, the sequence is not a sequence anymore. It becomes chaos. And chaos always increases, as entropy does.

That's not helpful, though. I know. Even if we accept that order is not predictable or stable over time, we need to find a way to deal with it when designing systems.

The solution always starts with analyzing the problem and identifying smaller sub-problems that can be handled in isolation and are likely easier to solve.

Let's start analyzing why ordering is unlikely to be possible. Ordering is a consumer concern. The only option for a process that consumes incoming requests to guarantee that processing happens in the exact order requests are queued is to be single-threaded or use a single-signaled semaphore, which results in behavior similar to being single-threaded. The scenario is the same regardless of they are HTTP requests, gRPC, or messages on a queue. Let's imagine a publisher publishing three messages, A, B, and C.

<div class="mermaid">
graph LR
    S[[Sender]] --> A
    A --> B
    B --> C
</div>

We're assuming that messages will be delivered to the underlying transport in the same order the publisher intended. At this point, I might already have doubts about the feasibility. Let's assume that it's incredibly likely that the publishing order is guaranteed. We expect the following to happen: 

<div class="mermaid">
graph LR
    C --> B
    B --> A
    A --> R[[Receiver]]
</div>

In the above scenario, if the receiver is a web server and A, B, and C are HTTP requests, it's pretty apparent why the only way to guarantee the order is to be a single-threaded singleton consumer:

<div class="mermaid">
graph LR
    subgraph requests
    C
    B --> A
    end
    subgraph Receiver instances
    A --> R1[[Receiver:1]]
    R2[[Receiver:2]]
    C --> R3[[Receiver:3]]
    end
</div>

As we can see, each instance can consume one or more requests. Each instance handles a subset of the requests. From the perspective of the system, the order is not predictable.

Things get even trickier if the transport is a queuing system. Nowadays, most of the available queuing infrastructures offer "at-least-once" delivery guarantees. What does that mean? It means that the infrastructure guarantees that messages are delivered at least once, but it could be that some messages are delivered twice or more. That means the following scenario is possible:

<div class="mermaid">
graph LR
    B1[duplicate of B] --> A1[duplicate of A]
    A1 --> C0[C]
    C0 --> B0[B]
    B0 --> A0[A]
</div>

If you add instances to the above diagram, one instance might handle A and B, and another one takes C, the duplicate of A, and the copy of B. From the first instance perspective, the order is guaranteed. From the second one, it's not. Interestingly, the one instance that gets requests in the correct order is missing one of the messages.

Why is that happening? Clusters. Queuing infrastructures are deployed in clusters. Keeping the cluster consistent, for example, to offer an exactly-once delivery guarantee, requires distributed transactions across nodes. Distributed transactions have a high cost. On AWS, when using Amazon SQS (Simple Queuing Service), there is the option to configure a queue as [FIFO (First in, first out)](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics)). They cost more, they are slower, and the deduplication window is limited in time. It reminds me of transactions timeouts, right?

## It's a palliative that leads nowhere

The truth is that by enabling [FIFO queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html) on AWS or [session support](https://docs.microsoft.com/en-us/azure/service-bus-messaging/enable-message-sessions) on Azure Service Bus queues, we only solve a fraction of the puzzle.

Being able to guarantee message ordering in the input queue, even if for a limited amount of time and a couple more caveats, is worth nothing if we have multiple competing consumers. Like in the above-presented diagram, where various instances consume messages, there is no way to guarantee message ordering at the instance level.

_[update 2021-10-21]_ As pointed out by Sean's comment below, when using Azure Service Bus:

> "[...] A given session cannot be processed by multiple consumers, only one. And that ensures a session messages are all handled in order.

Which solves the ordering problem leaving us with a single point of failure.

## What can we do about it?

We need to stop looking at message ordering as a global solution. By carefully analyzing various scenarios, we can group message ordering needs into four macro categories.

### Last message wins

If you're old like me, you probably remember the Windows service packs era. Service packs were cumulative. If "Service pack 2" was available, it also contained "Service pack 1" updates. A similar logic applies to many business requirements. A message can carry all the data, including the updates that a previous message could have delivered. The only requirement for such a kind of message is to bring also a timestamp. The receiver can use the timestamp to detect if the incoming message is newer or older than its current status. If A and B are two messages, and the receiver handles B first, it stores the B data and timestamp. When taking A, which arrives out of order, the handler compares its latest handled timestamp and discards A because it already dealt with B, which was more recent.

A variation of this scenario is what I call the "history is irrelevant" approach. Suppose messages have a timestamp attribute, and the receiver cares about the latest values only and is not interested in all changes in between. In that case, they can immediately discard all messages whose timestamp is older than the already processed one. Let's imagine a functionality that allows updating addresses. If we're not interested in all changes but only in the most current value, we can use timestamps to discard all update requests that are older than the current value.

### Message versioning with retries

What if we are interested in history, or history matters from the business perspective? We might be in a situation where we need message ordering over a sequence of messages of the same type. In this case, a timestamp is not sufficient. A receiver won't be able to detect holes in the series using timestamps only. A possible approach is to configure senders to append a version attribute to messages they publish. A sender would send something like:

<div class="mermaid">
graph LR
    A4[A v4] --> A2[A v2]
    A2 --> A3[A v3]
    A3 --> A1[A v1]
</div>

Messages are unordered in the queue but come with an attribute, for example, a version number, allowing receivers to understand how to order them. Receivers will store the latest accepted version and reject messages whose version is not "latest stored + 1". Rejected messages will be queued again. Sooner or later, the consumption order will match the versioning.

An approach based on versioning + retries is easy to implement but comes with two significant drawbacks:

1. Receivers require message ordering, but the requirement virally propagates to senders creating coupling.
2. Retries are inefficient. The longer the sequence is, the riskier is that retries will take a significant amount of time

### Sagas

So far, we have based all solutions purely on messaging. If introducing a persistence mechanism is an option, we can leverage sagas to keep track of the processing status and build an in-saga pending queue. The saga knows the business logic and thus knows the expected sequence of messages. If the saga receives an out-of-order message, it can store it in the saga data and [schedule a timeout](https://milestone.topics.it/talks/got-the-time.html) to later evaluate if it can process the previously received out-of-order messages. A basic sample of this type of saga is available in the [official NServiceBus sagas tutorial](https://docs.particular.net/tutorials/nservicebus-sagas/1-saga-basics/). The tutorial handles the out-of-order receive of two messages, and as such, it doesn't need to store any message for later processing. We can model many business use cases using the demonstrated approach.

For more scenarios where sagas are a successful tool to handle message ordering needs, read the ["You don't need ordered delivery"](https://particular.net/blog/you-dont-need-ordered-delivery) article by [Dennis Van Der Stelt](https://twitter.com/dvdstelt).

## Conclusion

As you probably noticed, dear reader, we have two significant options. On the one hand, we could try to brute-force change reality to adapt it to the way we would like to design systems. Or, on the other hand, we could bend the business to adapt to the real world. We could move from a "hold on, you cannot order because you haven't paid" approach to a "thanks for your order, we'll take care of the payment details later." The latter scales, the first one doesn't scale so quickly. At the same time, the first one might be easier to implement at first glance.

There is no right or wrong solution. Instead, we have plenty of options at our disposal. In this article, we analyzed a few. Please, share your experience in the comments below if you're doing something different.

---

Photo by <a href="https://unsplash.com/@markusspiske?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Markus Spiske</a> on <a href="https://unsplash.com/s/photos/order?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
