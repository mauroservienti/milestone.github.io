---
layout: post
title: "How does the 4+1 architectural view model help shape distributed systems?"
author: Mauro Servienti
synopsis: "The 4+1 architectural view model is a guiding star for some and a complete unknown for many others. That's fine in many scenarios. When designing complex distributed systems, it becomes crucial. What is it, and how can it help us?"
header_image: /img/posts/four-plus-one-views/header.jpg
enable_mermaid: true
related:
- 2022-01-25-lets-get-logical.md
- 2026-11-05-distributed-last.md
- 2023-01-19-pitfalls-of-request-response-over-messaging.md
tags:
- soa
- distributed-systems
- architecture
- logical-vs-physical
---

Logical services. Physical components. Service instances. Endpoints. If you've been around distributed systems for a while, you've heard people use all these terms, sometimes in the same sentence. I'm not immune to that either.

If that's confusing, I feel your pain. It's been confusing for me too.

The reason for those distinctions lies in the 4+1 architectural view model. Before diving into what it is, let me describe a few business requirements we'll use throughout the post. I always find it simpler to use examples to understand high-level, sometimes philosophical, concepts.

The system needs to process payments:

- Users must be able to input credit card details to pay later for what they ordered.
- Users must be able to add or edit credit card details at any time.
- When Fulfillment ships orders, the system needs to charge credit cards.

## What's the 4+1 architectural view model?

Let's start with the definition. [The following is from Wikipedia](https://en.wikipedia.org/wiki/4%2B1_architectural_view_model):

> 4+1 is a view model used for "describing the architecture of software-intensive systems, based on the use of multiple, concurrent views". The views are used to describe the system from the viewpoint of different stakeholders, such as end-users, developers, system engineers, and project managers. The four views of the model are logical, development, process and physical. In addition, selected use cases or scenarios are used to illustrate the architecture serving as the "plus one" view. Hence, the model contains 4+1 views

Philippe Kruchten introduced the model in 1995, in a paper titled ["Architectural Blueprints: The '4+1' View Model of Software Architecture"](https://www.cs.ubc.ca/~gregor/teaching/papers/4+1view-architecture.pdf). In short, the five views are:

- **Logical view:** the functionality the system provides to end users.
- **Process view:** the system's runtime behavior: processes, how they communicate, concurrency, distribution, performance, and scalability.
- **Development view:** the system from a programmer's perspective: how the code is organized and managed. It's also known as the implementation view.
- **Physical view:** the system from a system engineer's perspective: the topology of components in production and the connections between them. It's also known as the deployment view.
- **Scenarios:** a small set of use cases that illustrate and validate the architecture. They're the "+1."

Wikipedia lists the UML diagrams suited for each view. I'll stick to boxes and arrows.

That's indeed helpful. Let's see how it could shape the way we design the above requirements.

## Where do we start?

It's never easy to decide where to start. Shall we begin with the development view? Or with the process view? There is no correct answer. I also believe that every view will be reworked and refactored over time as we gain more understanding of the business.

> I had the opportunity to discuss the differences between logical and physical architectures at the beginning of 2022 in ["Let's get logical! On logical and physical architectural views"](https://milestone.topics.it/2022/01/25/lets-get-logical.html). That article was about ViewModel Composition, and it only touched two of the four views.

## Let's get logical, again

That said, I find it easier to start from the logical view. Given the above description, we're dealing with two logical services. Let's call them Finance and Fulfillment. We can also state that Fulfillment is only a trigger for a process, or a policy, in Finance:

> When Fulfillment ships orders, the system needs to charge credit cards.

Finance is the main character in this script. Fulfillment is merely an external party publishing an event to which Finance reacts.

Within Finance, we can identify a few components:

- **A payment processor** responsible for authorizing and charging credit cards.
- **A payment methods component** that allows users to input new credit card details and edit existing ones.
- **A validation component** designed to validate the aforementioned credit card details.
- **A vault** to securely store payment methods' sensitive details.

Those are logical components. At this stage, we don't know, and don't care much, how they interact technically with each other or how they'll look in production. They all belong to Finance, which defines the logical boundaries. A component belonging to Finance is subject to different rules when interacting with components inside the boundaries than with components outside of them. For example, [coupling has a different weight if it happens inside or across a service's boundaries](https://milestone.topics.it/2021/03/10/not-all-changes-are-born-equal.html).

## How do components talk to each other?

The process view describes how components and services interact with each other at runtime. This is when things get interesting, in my opinion.

The payment processor is a good candidate for a background kind of component. It charges credit cards when Fulfillment ships orders. That's an asynchronous reaction to a trigger, and messaging is a very good solution. The payment processor listens for messages in its queue, and Fulfillment publishes an `OrderShipped` event:

<div class="mermaid">
flowchart LR
  subgraph Fulfillment
    FS[Shipping]
  end
  subgraph Finance
    PP[Payment processor]
  end
  FS -- OrderShipped --> PP
</div>

Fulfillment doesn't know who is listening, and it doesn't care. If tomorrow Finance decides to charge credit cards in a different way, nothing changes in Fulfillment.

Different is when Finance needs to interact with the credit card provider. The credit card provider is a remote service that we don't control. Usually, credit card providers expose a payment flow based on HTTP interactions. We don't want issues at the provider to propagate into our system, with the risk of creating a snowball effect. To mitigate that, we isolate the communication with the credit card provider in a credit card gateway, and the payment processor talks to the gateway via messaging.

<!-- TODO: the original draft had the payment processor read the card details from the vault. I moved that to the gateway so card details never leave the vault/gateway pair and never travel in messages ("We don't want to move around the system's credit card details"). Revert if that's not what you meant. -->

When charging a credit card, the gateway needs the card details. We don't want to move credit card details around the system. We store them in the vault and use the vault ID everywhere else. The payment processor sends a `ChargeCreditCard` command containing the vault ID, and the gateway is the only component that reads the actual card details from the vault, right before calling the provider. It'll use a synchronous request to access the vault. There is no need for asynchrony there. The two are coupled anyway, and [request/response over messaging is tricky](https://milestone.topics.it/2023/01/19/pitfalls-of-request-response-over-messaging.html).

<div class="mermaid">
flowchart LR
  subgraph Finance
    PP[Payment processor]
    G[Credit card gateway]
    V[(Vault)]
  end
  CCP[[Credit card provider]]
  PP -- ChargeCreditCard --> G
  G -- CreditCardCharged / CreditCardDeclined --> PP
  G -- read card details --> V
  G -- HTTP --> CCP
</div>

Wait, isn't the exchange between the payment processor and the gateway request/response over messaging too? It is. The difference is that nobody is sitting there waiting for the reply. The payment processor sends a command and moves on. When the reply arrives, it's handled like any other message. If the provider is slow or down, messages wait in the gateway queue, and retries kick in. The rest of the system doesn't notice.

The payment methods component allows users to add new credit cards or edit existing ones. Here, we're dealing with a multifaceted component. The system needs to allow users to edit data and to store it securely. For example, during checkout, users can select an existing payment method or add a new one. Adding new payment methods or editing existing ones requires:

- A user interface component that lives in the application user interface.
- A back end component that talks to the vault and stores additional data, like "credit card ending with 1234," in a separate storage.

The user interface component is, almost certainly, synchronous with its back end counterpart. Users press the save button and expect to know that something happened. The card details must also go to the vault right away, synchronously. We don't want them sitting in a queue. However, given that we don't immediately need the new payment method, the back end can offload whatever else needs to be done to itself, through a message on a queue. That's where the validation component comes into play:

<div class="mermaid">
flowchart LR
  subgraph Finance
    UI[Payment methods UI]
    API[Payment methods back end]
    V[(Vault)]
    PMDB[(Payment methods)]
    VAL[Validation]
  end
  UI -- HTTP POST/PATCH --> API
  API -- store card details --> V
  API -- store display details --> PMDB
  API -- ValidatePaymentMethod --> VAL
  VAL -- update status --> PMDB
</div>

<!-- TODO: what happens when validation fails? Notify the user (email, UI notification), or flag the payment method so checkout can't select it? -->

Notice that the logical view had four components. The process view already has more moving parts: a gateway that wasn't there before, a user interface piece, and a back end piece. That's expected. Each view answers a different question.

## Who works on what? The development view

The development view looks at the system from a programmer's perspective. Where does the code live? How is it organized? Who can change what?

In ["Let's get logical!"](https://milestone.topics.it/2022/01/25/lets-get-logical.html), I wrote that in real-world systems, each service's codebase lives in its own repositories, and services know little to nothing about each other. Our example is no exception:

- Finance owns its repositories. The payment processor, the gateway, the payment methods back end, and the validation component are Finance code, maintained by the Finance team.
- The vault is a special case. Given its sensitivity, it might live in a separate repository with stricter access rules and a different review process. That's a development view decision driven by security, not by the logical design.
- The payment methods user interface component is Finance code too, even if it ends up in the application user interface. The application shell hosts it, but Finance owns it.
- The only thing Finance needs from Fulfillment is the `OrderShipped` event contract. Fulfillment owns it and publishes it, for example, as a package. Finance references that, and nothing else.

<!-- TODO: add a sentence on how you'd distribute the payment methods UI component to the application (package, micro frontend, composition)? Related idea card: "Continuous delivery when a service's components are compiled into other teams' container images". -->

The last point is where the development view helps the most. Looking at code dependencies tells us immediately whether logical boundaries are respected. If a Finance project references a Fulfillment project that isn't a contract, something is off.

## Where does it all run? The physical view

The physical view, also known as the deployment view, describes what runs where. Let's look at one possible deployment:

<div class="mermaid">
flowchart LR
  subgraph Web[Web application]
    UI[Payment methods UI]
  end
  subgraph API[Finance API host]
    PMB[Payment methods back end]
  end
  subgraph BE[Finance back end host]
    PP[Payment processor]
    VAL[Validation]
  end
  subgraph GW[Gateway host]
    G[Credit card gateway]
  end
  subgraph Secure[Isolated network segment]
    V[(Vault)]
  end
  UI --> PMB
  PMB --> V
  PP --> G
  G --> V
</div>

A few things stand out:

- **One logical component, many physical ones.** The payment methods component is a user interface piece running in the web application and a back end piece running in the Finance API host.
- **Many logical components, one physical host.** The payment processor and the validation component run in the same process. They don't need to scale or fail independently, at least not today.
- **Some components get their own host for a reason.** The gateway runs separately so that provider issues don't take down anything else, and so it can be scaled on its own. The vault lives in an isolated network segment because compliance requirements, like PCI DSS, demand it.

None of these choices changes the logical view. If payments volume grows and the payment processor needs more instances, we can move it to its own host, and the logical design stays the same. As I wrote in ["What I'm sure of is that it's distributed last"](https://milestone.topics.it/2026/11/05/distributed-last.html), physical distribution is a knob we turn when there is a reason to pay for it.

## Aren't microservices SOA done right?

I don't think microservices are SOA done right. The microservices theory has one big drawback: it conflates the logical and physical views into one, making it look like the logical unit is also the deployment unit. That's absolutely not the case. In our example, Finance is one logical service deployed as five physical pieces, and two of its components happily share a process.

In the past, SOA had many attempts to provide an out-of-the-box implementation, and they all failed. But that's fine. It would be like building a framework whose promise is to enable you to do Domain-Driven Design.

If microservices are where you come from, the 4+1 architectural view model is one of the things worth looking into. Keeping the views separate is what allows us to decide on deployment units without redesigning services.

## The plus one: does it hold up?

Scenarios tie everything together. They're the "+1" view: a small set of use cases we walk through to check that the other four views work together. Let's try one: a user adds a new credit card at checkout, and the next day Fulfillment ships the order.

<div class="mermaid">
sequenceDiagram
  participant U as User
  participant PM as Payment methods
  participant V as Vault
  participant F as Fulfillment
  participant PP as Payment processor
  participant G as Credit card gateway
  participant CCP as Credit card provider
  U->>PM: Add credit card
  PM->>V: Store card details
  V-->>PM: Vault ID
  PM-->>U: Card ending with 1234 saved
  Note over F: The next day
  F-)PP: OrderShipped
  PP-)G: ChargeCreditCard (vault ID)
  G->>V: Read card details
  G->>CCP: Charge
  CCP-->>G: Charged
  G-)PP: CreditCardCharged
</div>

The happy path works. However, scenarios are most useful when things go wrong. What if the credit card provider is down? Messages wait in the gateway queue, and retries take care of it. What if validation fails after the user has already selected the card at checkout? What if the card is declined after the order has shipped?

The requirements we started from say nothing about the last two. That's precisely the point. Walking through scenarios surfaces questions that none of the other views asks. And those are questions for the business, not for developers.

<!-- TODO: optionally show how a declined charge flows back (CreditCardDeclined → who tells the user? Who decides whether to cancel or retry?). -->

## Conclusion

The 4+1 architectural view model isn't a set of documents we must produce. It's a set of lenses. Each view answers a different question: what the system does, how its parts talk to each other at runtime, how the code is organized, where it runs, and whether all that holds up against real use cases.

One of the biggest benefits is vocabulary. When someone says "service," are we talking about a logical boundary, a repository, a process, or a container? Knowing which view we're in makes conversations a lot less confusing. And it's what allows us to say that the payment processor and the validation component can share a process today and be split tomorrow, without anything changing in the design ;-)

---

<!-- TODO: header image (/img/posts/four-plus-one-views/header.jpg) and its Unsplash credit. -->
