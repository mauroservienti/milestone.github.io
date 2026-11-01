---
layout: post
title: "Back to Basics: scaling up and scaling out message-based systems"
author: Mauro Servienti
synopsis: "We often use terms like scale up and scale out. What do they mean, and how do they influence the way we design software systems? Let's go back to the basics and build a common foundation. Today's topic is scaling."
header_image: /img/posts/back-to-basics-scaling/header.jpg
tags:
- back-to-basics
- architecture
- distributed-systems
- messaging
series: back-to-basics
---

There is at least one more fundamental topic worth discussing in the [Back to Basics series](https://milestone.topics.it/series/back-to-basics.html): what does scaling mean, and what about its scale-up and scale-out variations?

> The series so far covered [service boundaries, autonomous components, and coupling](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html), [commands, events, and messages](https://milestone.topics.it/2023/05/25/back-to-basics-messages.html), and [data ownership](https://milestone.topics.it/2026/11/09/back-to-basics-data-ownership.html).

## What does scaling mean?

Let's start by defining scale, or the act of scaling. Scaling a system or a component means increasing the number of operations performed per unit of time. In essence, it's going faster at doing what we're doing.

We have two main options to increase performance: scale up and scale out. They are also known, respectively, as vertical scaling and horizontal scaling.

If, like me, you witnessed the Intel Pentium era, that was an excellent example of scaling up: single-core CPUs made faster by packing more transistors into the "same" package. Then, after the Pentium 4, the industry shifted to multi-core CPUs. Better performance came from parallelizing the work across more cores of the same type rather than from a faster single-core chip.

## Scaling up

When it comes to software systems, we can use a similar approach. The first and most straightforward one is to scale up a system by adding more resources. For example, we can use a more powerful host machine to get better performance. It's the most accessible approach because it requires no software changes. Running on faster hardware is transparent to the system. It only needs more money.

## Scaling out

To scale out, we can replicate the same system on multiple nodes, creating a cluster of identical nodes. We then find a way to, for example, randomly address requests to one of the nodes in the cluster.

Scaling out a software system might be trickier. If the system is stateful and subsequent requests depend on the state left by previous ones (for example, it uses machine-dependent web sessions), we cannot randomly pick a node on each request. The typical approach is a load balancer with sticky sessions: the balancer knows how to route requests from the same client to the same node. However, that might result in an uneven load across nodes, significantly reducing the benefits of running on multiple nodes.

## What about monoliths?

Scaling up a monolithic system is generally relatively easy. On the other hand, scaling it out might be challenging. Suppose the system uses web sessions or any other in-memory state. In that case, we must modify it to keep that state out of process, with a significant performance penalty: memory access is orders of magnitude faster than accessing an external resource over the network or the disk. We need to pay an incredibly high tax to gain performance. It might not be worth it.

The monolithic nature of the system comes with another impediment. We need to scale out the entire monolith, even if only a subset of it needs or benefits from the infrastructure changes.

Imagine a trivial accounting application that only provides invoicing and a customer and supplier registry. If invoicing needs scaling because it's slow and doesn't keep up with the requested throughput, the whole application must scale, including the customer and supplier registry. And there might be no blockers to scaling invoicing, but there are for other parts of the application. For example, the customer and supplier registry uses in-memory web sessions, making scaling out harder than needed.

## It's not only about code

Scaling isn't only a software concern. It might affect surrounding resources, such as databases. Using the accounting example, the invoicing problem might be the database. Once again, it's easy to scale up a database server, but it might be impossible to scale it out.

Effectively scaling out a database can, under certain conditions, require a multi-master setup. That requires a database that supports it, and likely code changes to support what could be a completely different paradigm. The problem is that a multi-master setup can lead to conflicts. If different application instances write to different database instances and touch the same subset of data, the datasets start diverging, and we must devise a reconciliation process. There are many ways to approach such a scenario, all food for follow-up articles.

Similar issues might happen at the infrastructure or networking levels: a router or load balancer that cannot keep up with the load, or a disk subsystem that cannot read or write data fast enough because the requested I/O exceeds the infrastructure's capabilities.

In all those scenarios, scaling up might be more manageable. A faster disk, a more robust network appliance, or a better machine for the database server are all solutions that don't require re-architecting the software system.

## When do we need to scale out?

The easy answer is when scaling up isn't worth it anymore. There will be a point when _throwing money at the problem_ by "vertically" increasing the available resources no longer improves performance at a reasonable cost: the return on investment (ROI) is too low. As we've seen, a load balancer in front of a cluster of identical nodes might be the most straightforward solution. But what if the system is stateful, or only a part of it needs to scale?

That is when a distributed architecture comes in handy.

## How does that relate to distributed systems?

Let's go back to the accounting application. If invoicing and the customer and supplier registry are separate services, with [clear boundaries](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html), each [owning its data](https://milestone.topics.it/2026/11/09/back-to-basics-data-ownership.html), and communicating through messages, they can be deployed independently. Invoicing can scale out while the registry keeps running on a single node, web sessions and all. Scaling a part of the system differently from the rest is one of the good reasons to split a deployment I listed in ["What I'm sure of is that it's distributed last"](https://milestone.topics.it/2026/11/05/distributed-last.html).

Messaging also changes how load is distributed. With a load balancer, requests are pushed to nodes, and the balancer must decide where each one goes. With queues, multiple instances of the same endpoint read from the same input queue and compete for messages: it's the [competing consumers](https://milestone.topics.it/2022/03/12/where-we-are-going.html) pattern. Each instance pulls the next message when it's ready, so a busy instance naturally takes less work, and there are no sticky sessions to worry about, as long as handlers don't rely on in-memory state.

Queues also absorb peaks. When messages arrive faster than they're processed, they pile up in the queue instead of turning into timeouts. A growing queue is a signal that we need more resources, and as I wrote in ["How many (micro)services do I need?"](https://milestone.topics.it/2023/03/15/how-many-services.html), scaling out the endpoint is a quick way to address it.

> Scaling out isn't a silver bullet, though. If the load keeps growing, more instances might only be [kicking the can down the road](https://milestone.topics.it/2022/07/25/topology-changes.html). And competing consumers come with a price: there is no way to guarantee [message ordering](https://milestone.topics.it/2021/10/20/isnt-a-supposed-to-come-before-b.html) across instances.

## What about logical and physical?

A question I often get is how scaling out affects commands and events. Commands are sent to one receiver, while events are published to zero or more subscribers. What happens when there are multiple instances of the receiver? Or of the publisher?

Nothing, from the design perspective. Scaling out doesn't change any of that, because it's a physical concern. If multiple instances of the same sender or publisher exist, there remains one logical sender or publisher. The same applies to receivers and subscribers. There can be numerous instances of the same receiver or subscriber, to scale out, load balance, or provide a highly available service. Logically, there is still one.

In practice, when an event is published, each logical subscriber gets one copy of it, and only one of that subscriber's instances processes it. A command sent to a logical receiver is processed by one of its instances. The [logical architecture](https://milestone.topics.it/2022/01/25/lets-get-logical.html) stays the same regardless of how many instances we deploy.

## What about high availability?

Scaling out has a nice side effect: availability. When multiple instances of the same endpoint compete for messages from the same queue, one of them failing or being redeployed doesn't stop processing. The remaining instances keep consuming messages, at a lower throughput.

And if all instances are down, messages wait in the queue. Senders don't fail because the receiver is unavailable; the work is delayed, not lost.


## Conclusion

Scaling up means adding resources to the same node. It's transparent to the system and the easiest option, until it's not worth the money anymore. Scaling out means adding more nodes. It requires the system, or at least the part that needs scaling, to be designed for it.

A message-based system with clear boundaries and services owning their data makes scaling out a deployment decision for each part of the system rather than a rewrite of the whole. Scaling out is a physical concern: no matter how many instances we deploy, the logical design, with its commands, events, senders, and receivers, doesn't change.

---

<!-- header image credits -->
