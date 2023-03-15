---
layout: post
title: "How many (micro)services do I need?"
author: Mauro Servienti
synopsis: "Microservices, microservices everywhere. But how many of them do we need? It's easy to be trapped by the micro thing and end up with thousands of them. Let's try to provide some guidance."
enable_mermaid: true
header_image: /img/posts/how-many-services/header.jpg
tags:
- soa
- architecture
- messaging
- nservicebus
---

When it comes to microservices architecture, it's easy to fall into the trap of going all in and designing a system composed of thousands of services. A microservice to enable users. One to add an item to the shopping cart. One to remove items from the shopping cart. Another to update the shipping address. And one to create it. You name it. Every little thing becomes a microservice—a nightmare that comes true.

As I said multiple times, I don't like the term microservice. It focuses too much on the size of the thing. I'd instead prefer service or, better yet, endpoint.

> Note: I consider endpoint and service synonyms for this post. In the larger, distributed systems architecture world, they are not. However, for this article, this simplification is good enough.

Let's start by defining an endpoint: A collection of handlers sharing common attributes. It might be a logical endpoint and, thus, a logical group of handlers. Or physical, also known as endpoint instance, in which case it's also a physical grouping of handlers.

> On the differences between logical and physical architecture, I wrote ["Let's get logical! On logical and physical architectural views"](https://milestone.topics.it/2022/01/25/lets-get-logical.html). The article dives into the nitty gritty details of logical and physical architecture differences.

## Still cryptic, right?

Let's try with an example. The system provides information about hotel bookings to users reserving rooms online. For the sake of the sample, all requests related to bookings are a logical group. They relate to the same business concern.

A different request handler manages each request, regardless of how the request reaches the system. There is a handler to get the status of a room, a handler to cancel bookings, one to update the status, etc.

Moving into the physical space, we could expose an HTTP endpoint that handles requests. If we implement the solution using ASP.NET, the endpoint is a controller., e.g., `BookingsController`, and handlers are controller actions. An action to respond to HTTP requests trying to retrieve the booking status, and so on. If we're using messages and queues, an endpoint is a process that sends and receives messages, and handlers are classes or methods responsible for handling incoming messages.

Handlers belonging to the same endpoint share the same business concerns. Similarly, handlers deployed in the same endpoint instance share a few attributes. For example, controller actions share the same base route address. Message handlers in an endpoint instance share the same queue.

## So? How many endpoints do I need?

For the impatient like me, the minimum number of endpoints should match the [identified logical service boundaries](https://milestone.topics.it/2022/01/25/lets-get-logical.html). Let's continue using the simple hotel booking system example.

Users can search for vacant rooms within a date range and location. Once they've found the desired destination, they can book it by inputting their credit card number and customer's details, such as name and address. Upon booking, the system authorizes the required amount on the credit card to hold the money. And at hotel check-in time, it'll charge the final amount.

Without diving too deeply into the whys, we could identify Reservations, Finance, Customers Management, and Check-in/Check-out as logical services. Good, four logical endpoints, and to begin with, four distinct endpoint instances.

### Into the physical world

It's fair to assume that each identified logical endpoint contains business logic and a way to interact with the endpoint. For example, Reservations has:

- Web pages to show hotels, rooms, amenities, and availability.
- Business logic to handle bookings, unavailable rooms, and cancellations.
- An HTTP API to query data. For example, to perform room searches.
- A queue to receive messages from the rest of the system. For example, the information that a payment method has been denied and a room reservation canceled.

All that can be deployed in a web application hosted by a web server. The application handles incoming HTTP requests and messages. A similar approach works for all the other identified endpoints. With that in mind, we could say that by default _n_ number of logical endpoints corresponds to the same number of physical endpoints.

## Large endpoints and large teams

As functionalities grow, it's legitimate to expect teams to get larger. Or that the same group having more work to do will wear multiple hats. For example, the Reservations team responsible for the system's web and business logic parts starts working at a different pace in a different context. The web part evolves faster than the business one causing some headaches when deploying. Unfinished business work hinders web evolution.

The team could split it into multiple endpoints. For example, the part responsible for handling HTTP requests could be a different endpoint from the one handling messages received from the rest of the system.

## Too many handlers

Using the same approach, if the endpoint handling messages gets big enough to cause headaches, they could split it into multiple endpoints, listening to different input queues. In this second scenario, splitting is not necessarily for performance reasons, for which we could also be scaling out the same endpoint to multiple instances.

It's worth spending a few words on performance issues. Let's imagine an endpoint with ten handlers. Some of them do CPU-intensive work. At a certain point, the team realizes that the system throughput suffers because the handlers are battling for CPU resources.

The easiest option at this point could be to scale out the endpoint. The CPU remains a shared precious resource by having multiple instances of the same endpoint on different nodes, but we've split the load into various nodes/CPUs. And that can be a way to kick the can down the road for a while.

A proper solution could be to split handlers into different endpoints. That results in sharding the handlers rather than scaling them out. For example, if there are four CPU-intensive handlers, each could be deployed separately in a different endpoint to remove any possible battling on resources.

Sharding also helps in solving queue length issues. Clients are issuing requests, and receivers cannot keep up. They process requests at a lower rate than they're coming in. If requests were HTTP requests, they would result in many timeouts. We want queues to be able to pile up incoming requests and eventually process them. However, from the system point of view, an increase in queue length signals that the available resources are not enough to process the current load. Again, scaling out endpoints is a quick solution that might temporarily alleviate the issue.

### So, when does sharding become helpful?

Scaling out endpoints might be a palliative when facing the queue length issue. Let's imagine the receiver handles two message types: A and B. A is a simple, low-resource message for which there is little throughput. The second, B, requires many resources, and the system processes many of them. If both handlers are in the same endpoint, and the message ratio is one to ten (one A for each ten Bs), there is a high chance that scaling out the processing endpoint has little value. All scaled-out instances might be busy processing Bs allocating little time to As. It's a scenario in which sharding is helpful. We want to have two different endpoints, one processing message A and a different one processing message type B.

However, sharding an endpoint might come with some cons. For example, if we're already in production, we might need to change message senders due to spatial coupling. Senders were previously dispatching messages to a queue that is now different since the functionality is directly handled by another endpoint listening to a separate queue.

### Triage endpoints

A workaround to avoid changing senders due to receivers sharding is to use a triage endpoint. We could keep the original endpoint, so we don't need to update senders. The original endpoint takes on the role of inspecting the incoming message and deciding where to send it. If it's message A, it'll forward it to the endpoint shard for As, otherwise to the one for Bs. It's a slight overhead in exchange for no spatial coupling issues.

We can use the following diagrams to summarize the described scenarios. Everything starts with two physical endpoints matching the logical ones:

<div class="mermaid">
graph LR
   subgraph Receiver
    h1[Handler A]
    h2[Handler B]
   end
   S[Sender] -- message A --> h1
   S -- message B --> h2
</div>

As said, scaling out is an option. In that case, the endpoints themselves don't change. We add more instances:

<div class="mermaid">
graph LR
   subgraph Receiver
     subgraph Instance 1
         h1i1[Handler A]
         h2i1[Handler B]
     end
     subgraph Instance 2
         h1i2[Handler A]
         h2i2[Handler B]
     end
   end
   S[Sender] -- message A --> h1i1
   S -- message B --> h2i2
</div>

When we use a shard-based approach, the topology changes like in the following diagram:

<div class="mermaid">
graph LR
   subgraph Receiver A
    h1[Handler A]
   end
   subgraph Receiver B
    h2[Handler B]
   end
   S[Sender] -- message A --> h1
   S -- message B --> h2
</div>

The topology change is disruptive—it breaks senders too. We can alleviate the issue by introducing a triage endpoint:

<div class="mermaid">
graph LR
   subgraph Receiver A
    h1[Handler A]
   end
   subgraph Receiver B
    h2[Handler B]
   end
   R[Receiver Triage] -- message A --> h1
   R  -- message B --> h2
   S[Sender] -- message A --> R
   S -- message B --> R
</div>

## Configuration incompatibilities 

So far, the reason for splitting endpoints has been performance-related. A different reason leading to similar needs are endpoint configuration differences making handlers incompatible.

As far as I can tell, in an ASP.NET Core web application, there can be only one inversion of control (IOC) container. One shared base address and one HTTP pipeline handle all incoming requests.

The same applies to messaging endpoints; some characteristics are endpoint-defined, and all handlers share them in the same endpoint. For example, the transaction settings are endpoint-defined. If the endpoint is configured to receive messages using [`sends with atomic receive`](https://docs.particular.net/transports/transactions) and, for [some reason](https://milestone.topics.it/2021/01/30/transactions-none-for-me-thanks.html), one handler needs a different setting, that handler cannot be deployed in the same endpoint, and a different one is required.

## Conclusion

As a general rule of thumb, starting easy and setting some alarm to react to unexpected behaviors is better. Let's start with services matching the number of logical service boundaries and evolve from there based on the identified need. Adding unneeded services comes with unneeded complexity that will only cause unneeded headaches. Too many things we don't need ;-)

---

Photo by <a href="https://unsplash.com/ko/@andreuuuw?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Andrew Wulf</a> on <a href="https://unsplash.com/photos/59yg_LpcvzQ?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
