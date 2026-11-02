---
layout: post
title: "What I'm sure of is that it's distributed last"
author: Mauro Servienti
synopsis: "Monolith first or microservices first? Both answers describe how the system is deployed, not how it's designed. What comes first is finding the logical boundaries. Distribution is a physical decision, and it should be the last one we make."
header_image: /img/posts/distributed-last/header.jpg
enable_mermaid: true
tags:
- architecture
- distributed-systems
- soa
- logical-vs-physical
---

In a newsletter installment, ["Monolith-First - are you sure?"](https://www.architecture-weekly.com/p/monolith-first-are-you-sure), Oskar Dudycz raises concerns about how good we are at unthinkingly following a swinging technical pendulum. A few years ago, it was all about microservices; then, it was all about modular monoliths. Nowadays, it's all about AI; tomorrow, who knows?

I don't have much to say about Oskar's comments other than I agree. What caught my attention and made me think was the title.

Monolith first? Am I sure? No, I'm not. What I'm sure of is that it's distributed last.

## Isn't that the same question?

"Monolith first" and "microservices first" look like opposite answers to the same question. They are. The problem is the question.

Both describe the system's physical architecture: how many processes we run, how many deployment units we ship, and where the network sits. Neither says anything about how the system is designed.

I wrote about the difference between logical and physical architecture in ["Let's get logical!"](https://milestone.topics.it/2022/01/25/lets-get-logical.html). The logical architecture describes services: what they own, what they are responsible for, and how they relate to each other. The physical architecture describes where all that runs. The two are related, but one doesn't dictate the other.

> In this article, I use the term service in the SOA sense: a logical boundary owning data and behavior. Not a deployment unit, and certainly not a _micro_ one.

A single logical service can be deployed as many physical components: a web API, a couple of [NServiceBus](https://docs.particular.net/nservicebus/) message endpoints, a background job, and some composition handlers in a [ServiceComposer](https://github.com/ServiceComposer/ServiceComposer.AspNetCore) gateway. In the other direction, [multiple logical services can run in a single process](https://docs.particular.net/nservicebus/hosting/core-hosting#hosting-multiple-endpoints). Neither is wrong per se.

The pendulum keeps swinging because we make the physical decision first and then try to retrofit a design onto it. Choose microservices first, and the network becomes the boundary, whether it's in the right place or not. Choose a monolith first, and boundaries become folders. Folders are very easy to ignore.

## So, what comes first?

[Boundaries](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html). Which data belongs together? Which business capabilities change together? Who owns the product price, and who owns its description? None of these questions requires deciding how many processes we'll have.

Boundaries are hard to find. [Anti-requirements](https://particular.net/blog/antirequirements) are a technique that helps: invent a rule that ties two pieces of data together and present it to business stakeholders. If they laugh, the data probably doesn't belong together. Boundaries are also the most expensive decision to get wrong. A misplaced boundary splits data that should change together, and every change turns into a coordination exercise. That's true whether the two sides of the wrong boundary are separated by a namespace or by the network. The network only makes it hurt more.

That's why I find "modular first," which is where Oskar's article lands too, a much better answer than either "monolith first" or "microservices first." I'd go one step further, though. Having modules is not enough. Modules need to behave as if they were already distributed.

## Designing as if it were distributed

Oskar describes very well how modular monoliths erode. One module calls another module's repository directly because it's faster. A transaction spans two modules because it's convenient. A query joins tables from different schemas because the data is right there. Each shortcut is small. Together, they turn a modular monolith into a monolith with more folders.

What do those shortcuts have in common? They would be impossible if the modules were deployed separately. We can't open a database transaction across two processes owning separate storage, at least not without distributed transactions. We can't call a repository that lives in another process. The network enforces boundaries that the compiler doesn't.

So the trick is to design and build as if the network were already there, even when it isn't:

- **Each service owns its data.** No shared tables, no cross-service queries, no cross-service transactions, even if everything lives in the same database instance today.
- **Services interact through messages.** Commands and events describe what happens between services. A message-based contract is the same whether sender and receiver run in the same process or on different continents.
- **Consistency across services is eventual.** Within a service, use transactions. Across services, design for eventual consistency, and use tools like the [outbox](https://milestone.topics.it/2023/02/07/outbox-what-and-why.html) to keep data and messages consistent.
- **Composition happens at the edges.** When users need data from multiple services, compose it in the user interface or in a [composition gateway](https://milestone.topics.it/series/view-model-composition.html). Services don't query each other.

> Messaging doesn't require a broker on day one. The new NServiceBus [Non-Durable transport](https://docs.particular.net/transports/non-durable/) exchanges messages in memory between endpoints hosted in the same process. It brings in messaging patterns without forcing additional infrastructure at the beginning. Messages are lost when the process stops, though, so it's a starting point, not a destination. When durability matters, or when an endpoint moves to its own process, we switch to a durable transport.

Designed that way, the system is logically distributed from day one. Physically, it can still be a single deployment unit.

## Why last?

Because distribution is expensive, and we pay its costs every day the system runs.

Every network hop adds latency and a new way to fail. The network isn't reliable, and [duplicate messages aren't a theoretical problem](https://milestone.topics.it/2026/10/24/seven-emails-duplicate-messages.html). Topology changes. Deployments get more complex, and observability needs more effort. Debugging a request that crosses five processes is a different sport from debugging one that crosses five classes. The [fallacies of distributed computing](https://particular.net/blog/the-network-is-reliable) are all still there.

Those costs are worth paying when there is a reason. And there are many good reasons to split a deployment:

- A part of the system needs to scale differently from the rest.
- A part of the system needs to be isolated for security or compliance reasons, like the payment details vault in the "Let's get logical!" example.
- A part of the system needs to fail independently: a memory leak or a crash in one component must not take everything else down.
- Teams need to deploy at different cadences, and coordinating releases has become the bottleneck.
- A component needs a different technology stack or runtime.

Notice anything? None of them is a design reason. They are operational, organizational, or non-functional reasons. Most of them only become visible once the system runs in production and we can observe it. That's what makes distribution a decision to take last, when we have data, rather than first, when we only have assumptions.

## Last doesn't mean never

Let's look at an example. An online store has three services: Sales, Shipping, and Payments. Each owns its data and its message handlers. When a customer places an order, Sales publishes an `OrderPlaced` event. Shipping and Payments react to it. Initially, everything runs in a single host:

<div class="mermaid">
flowchart LR
  subgraph Host
    direction LR
    S[Sales] -- OrderPlaced --> SH[Shipping]
    S -- OrderPlaced --> P[Payments]
  end
  S --> SDB[(Sales data)]
  SH --> SHDB[(Shipping data)]
  P --> PDB[(Payments data)]
</div>

Black Friday comes, and Payments struggles under the load. On top of that, the security team wants payment processing isolated from everything else. Time to pay the cost of distribution. Payments moves to its own host:

<div class="mermaid">
flowchart LR
  subgraph Host
    direction LR
    S[Sales] -- OrderPlaced --> SH[Shipping]
  end
  subgraph PH[Payments host]
    P[Payments]
  end
  S -- OrderPlaced --> P
  S --> SDB[(Sales data)]
  SH --> SHDB[(Shipping data)]
  P --> PDB[(Payments data)]
</div>

What changed? The `OrderPlaced` event didn't. The handlers didn't. The business logic didn't. What changed is where Payments runs and how messages reach it. Moving a component to its own process is a deployment change, not a rewrite.

Now imagine Payments reading the orders table owned by Sales, inside the same transaction that stores the order. Moving Payments out is no longer a deployment change. It's a redesign, done under pressure, on Black Friday.

It works the other way around, too. If a split doesn't pay off, the two components can be deployed together again. Physical boundaries become a knob we can turn as requirements evolve, rather than a bet we place at the beginning of the project and live with forever.

The opposite isn't true. If logical boundaries are wrong, no deployment strategy will save us. Splitting the wrong boundaries across processes gives us a distributed monolith: all the costs of distribution and none of the benefits.

## Conclusion

Monolith first or microservices first? I don't know, and, to be honest, I don't think it matters much at the beginning. Both answer a question that comes too early.

Logical boundaries first, designed as if they were distributed. Physical distribution last, when there's a reason to pay for it. That's what I'm sure of ;-)

---

Photo by <a href="https://unsplash.com/@gogostevie?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Stephen Harlan</a> on <a href="https://unsplash.com/photos/white-question-mark-painted-on-concrete-pavement-vZVeQt3yit0?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
