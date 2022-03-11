---
layout: post
author: Mauro Servienti
title: "Where we’re going, we don’t need service discovery"
synopsis: "Too many times technology is used to solve problems that, to begin with, should not be considered problems. Service discovery, in many occasions, is a solution in search of a problem."
header_image: /img/posts/where-we-are-going/header.jpg
tags:
- distributed-systems
- soa
---

From where I live to Milan is about 25 kilometers. There is a nice suburban train that runs every 15 minutes. It's a train that more or less behaves like a subway. People buy a ticket, board the train, pick an available seat (or stand up during rush hour), and "enjoy" the ride.


On the other hand, I can board a high-speed train from Milan to Rome. It "flies" at about 350 km an hour and can bring me to Rome in under 3 hours. The process is a bit more involved. People usually buy tickets in advance. Tickets are bound to a specific date/time and come with a reserved or system-assigned seat.

If seats were (micro)services, the suburban train is a massive cluster of competing consumers instances, and the high-speed train is a cluster of addressable instances.

## Competing for passengers

The AWS SQS (Amazon Web Services Simple Queue Service) infrastructure is similar to a suburban train. For the sake of the example, assuming SQS queues can handle one message at a time, a queue is like a train seat. AWS hosts SQS queues on nodes that live in clusters, the train. Clients sending and receiving are unaware of the cluster topology. They talk to the "train."

A message gets delivered to the queuing system. Messages are physically sent to a specific queue on a particular node at delivery time. From the sender and receiver perspective, whatever queue instance on which node is irrelevant. In our analogy, the queuing infrastructure is the train, messages or payloads are passengers, and queue instances are train seats.

In this scenario, queues are competing for incoming messages. We usually refer to competing consumers from the recipient of a message. Multiple instances of a recipient compete to consume messages from an input queue. We can look at the same thing from the queue perspective. Queue instances compete on accepting messages from one or more senders.

## Waiting for passengers

A high-speed train, on the contrary, is much more similar to a cluster of nodes exposing an API that uses an RPC (remote procedure call) style.
A payload must use a specific addressable instance.

> Sure, we could put a load balancer in front of the RPC-style cluster of nodes. Still, there is a need to address the balancer. More on this later.

For high-speed trains, tickets must come with "address" details to allow passengers to identify the reserved car and seat. Not to mention the reservation date and time.

If seats are (micro)services, tickets are the service discovery infrastructure. They allow payloads to identify which specific service they need to fulfill the business requirement.

If the system we're designing requires addressing instances, it suffers from spatial coupling.

## Spatial coupling

Spatial coupling is a form of coupling that surfaces in a design when two or more components, supposed to be autonomous, need to know "where" they are to operate. For example, connection strings to database servers are a form of spatial coupling. [SQL Server offers aliases](https://docs.microsoft.com/en-us/sql/tools/configuration-manager/aliases-sql-server-configuration-manager?view=sql-server-ver15). In a network of computers [DNS servers A and CNAME records](https://www.namecheap.com/guru-guides/dns-records/) masquerade the machines' physical addresses.

If we take a closer look, they are all a form of service discovery. We need to connect to a database server or request data from a remote HTTP API. We depend on an external service, e.g. the alias mechanism or the DNS server, to reach the designated resource.


## Why are balancers not enough?

One could argue that a balancer in front of resources may solve the generated spatial coupling.

When it comes to system resources, we might not need to connect to a specific node known in advance. We need one of the nodes. For example, if the requirement is to generate an invoice and the system offers a cluster of nodes that can create invoices, we need one, not a specific one. The "invoice creators" cluster could be proxied by a balancer that presents it as a single node and route requests internally.

Still, we need to address the balancer. And we need service discovery.

More importantly, we cannot group behind the same balancer different logical nodes. There cannot be an "invoice creator" node and an "order manager" node, both proxied by the same balancer. Well...we could, but then we also need a way to tell the balancer how to route requests behind the scenes.

We're moving the cheese around. Spatial coupling changed its shape, but spatial coupling remains.

If we wanted to use the train seat analogy, it would be like buying first-class or second-class tickets with no assigned seat. The train car is the balancer. Passengers will be required to find first or second-class cars and then pick a random free seat. The train coach is the load balancer. We cannot mix first and second-class tickets in the same carriage. It'll be a mess.

## Back to the drawing board

So far, we have learned a couple of things:

- Spatial coupling is a problem we need to keep under control.
- Load balancers partially address the identified issue.

We can build on that. Unless there is a clear need for addressing instances, we can move away from a balancer/service discovery infrastructure to a queue-based infrastructure.

The change is substantial. Senders will stop addressing instances. Instead, they'll dispatch messages to the queuing infrastructure along with the destination queue. Internally to the infrastructure, there will be a lot of addressing and, maybe, services discovery to route the message to the destination correctly. However, it won't surface as coupling to the system we're designing.

## Why we might accept the spatial coupling

There might be rare occasions in which addressing a specific instance is needed. For example, if the system partitions data using a data shard strategy, not all services instances can access all the data. A subset of the instances will access a subset of the data. In such a scenario, when communicating with those instances, we'll need to address a subset based on the way data are partitioned. I'm not sure there will be a need for a service discovery mechanism; however, some address is needed. And with addresses come spatial coupling.

## Conclusion

Service discovery sounds like a very cool thing. We might need it. However, if service discovery presents itself as a good solution in many cases, we might want to go back to the drawing board and review why addressing instances is required.

---

Photo by <a href="https://unsplash.com/@unarchive?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Jeremy Bezanger</a> on <a href="https://unsplash.com/s/photos/discovery?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
