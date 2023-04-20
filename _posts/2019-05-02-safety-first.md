---
typora-copy-images-to: ..\img\posts\safety-first
typora-root-url: ..
layout: post
header_image: /img/posts/safety-first/header.jpg
title: "Safety first!"
author: Mauro Servienti
synopsis: "In a distributed system, communication reliability is a key aspect. Orchestrating multiple HTTP calls is generally a bad idea; it's very hard, if not impossible, to be reliable. This is when messaging and patterns like the Outbox come into play."
enable_mermaid: true
tags:
- soa
- messaging
---

*Today's post will be more about reliable communication than ViewModel Composition, so it won't be part of the [ViewModel Composition category](/categories/view-model-composition).*

When talking about ViewModel Decomposition, in [The fine art of dismantling](/view-model-composition/2019/04/18/the-fine-art-of-dismantling.html), I intentionally oversimplified the communication mechanism between client and back-end services, in order to reduce complexity.

"The fine art of dismantling" ended stating that ***not all that glitters is gold***:

> Sending data to a backend is not as easy at it seems at first glance. The incoming request is HTTP and there are, in this sample, three different handlers that try to handle part of the request. What if one of them fails? We need to find a way to deal with the fact that HTTP has no transaction support. The next article will be focused on what we can do when things go wrong.

HTTP doesn't support transactions. However we need some sort of transactional behavior, otherwise there is a high chance of ending up with a corrupted system.

## Not all failures are born equal

I like to distinguish between a business failure and an infrastructure failure. [A business failure is not really a failure, it's a scenario](https://milestone.topics.it/2019/09/10/businesses-dont-fail-they-make-mistakes.html). When *something* happens, and *something else* is in specific state, then the attempted operation cannot be performed: exception!

Such an exception should never surface as-is to users; there should be a human-readable error message instead, making the scenario a business use case.

Then there are infrastructure failures: When *something* happens...BSOD.

In our sample case, if *something* is an incoming HTTP request we might have the following scenario:

<div class="mermaid">
sequenceDiagram
    participant Client
    participant Composition Gateway
    participant Backend Service(s)
    Client->>Composition Gateway: HTTP Request
    Composition Gateway->>Backend Service(s): First outgoing request
    Composition Gateway->>Backend Service(s): Second outgoing request
    Composition Gateway->>Client: HTTP Response
</div>

The outgoing requests could be whatever we like, they could be two HTTP requests, or they could be a call to the Azure Table Storage trying to insert data and a SQL statement trying to update some data.

In the case of an infrastructure failure, we might end up in the following undesirable scenario:

<div class="mermaid">
sequenceDiagram
    participant Client
    participant Composition Gateway
    participant Backend Service(s)
    Client->>Composition Gateway: HTTP Request
    Composition Gateway->>Backend Service(s): First outgoing request
    Note over Composition Gateway,Backend Service(s): BSOD
</div>

In this scenario, if the first outgoing request succeeded, and then the machine crashes, there is no external transaction coordinator that can help. We have a corrupted system.

### Idempotent, you must be!

Idempotency is generally used a solution to this class of problems. Idempotency can be a solution, with a couple of footnotes:

- no one tells the truth about how hard it can be
- third-party systems we deal with might not be idempotent, and there is nothing we can do about it.

Idempotency to me also sounds like passing the buck to far down into the system:

> Hey, I failed! But you know what? *We* are idempotent, you can retry!

Emphasis on the *we*. All the back-end services must be idempotent, we don't know what failed and what succeeded, they all must be retried.

### Messaging to the rescue

In most cases, users are simply looking for feedback. A response like:

> We received your request, we got your back.

is more than enough. Then our UX people can step in and build feedback mechanisms and notification areas to report the status of their requests back to users. If this is the case we can go fully asynchronous and modify the above scenario to:

<div class="mermaid">
sequenceDiagram
    participant Client
    participant Composition Gateway
    participant Queuing System
    Client->>Composition Gateway: HTTP Request
    Composition Gateway->>Queuing System: send a first message on a queue
    Composition Gateway->>Queuing System: send a second message on a queue
    Composition Gateway->>Client: HTTP Response
</div>

However we just reduced to amount of time spent in that process, reducing the risk of a catastrophic failure hitting us. We haven't really solved the problem. But...because there is always a but, we could do something like:

<div class="mermaid">
sequenceDiagram
    participant Client
    participant Composition Gateway
    participant Queuing System
    Client->>Composition Gateway: HTTP Request
    Composition Gateway->>+Queuing System: send HTTP Request as message payload
    Queuing System-->>-Composition Gateway: handle the message
    Composition Gateway->>Client: HTTP Response
</div>

This operation is known as send-local. What we have now is a 1-to-1 relationship between an incoming HTTP request and a messaging operation:

- the locally sent message is handled by two different handlers
  - Handler A sends a first message
  - Handler B sends a second message

If one of the two handlers fails, the incoming message is retried, both handlers will be invoked once again, and eventually they succeed. However if the first one succeeds and then there is a catastrophic failure then they'll both be retried (on a different node) and *Handler A* will send a duplicate message. This is when patterns like the [Outbox](https://docs.particular.net/nservicebus/outbox/) come into play to provide *exactly-once-processing* (note: processing, not delivery).

## Conclusion

Don't try to orchestrate multiple HTTP requests, there is a very high chance of ending up with a corrupted system. If from the UX perspective a fully asynchronous experience is doable, then asynchronous messaging is likely to be the solution we're looking for. Idempotency is still needed, but its complexity can be delegated to the infrastructure using the Outbox pattern and a messaging framework.

*Disclaimer I work for Particular Software, the makers of NServiceBus*.

---
Header image: Photo by [Pop & Zebra](https://unsplash.com/photos/wp81DxKUd1E?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/safety?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
