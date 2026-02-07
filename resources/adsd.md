---
layout: page
permalink: /resources/adsd/
title: ADSD – Resources & Further Reading
---

# ADSD – Resources & Further Reading

A curated collection of resources aligned with the concepts and paradigms taught in Udi Dahan's **Advanced Distributed Systems Design** course. Organized by topic area for easy reference and deeper exploration. Each section includes external resources and related articles from [milestone.topics.it](https://milestone.topics.it).

---

## The Course Itself

- [Advanced Distributed Systems Design – Particular Software](https://particular.net/adsd) — The official ADSD course page with module descriptions and registration for both in-person and online formats.
- [ADSD Online Course](https://learn.particular.net/courses/adsd-online) — The full 33-hour online video course covering all modules.
- [Distributed Systems Design Fundamentals (Free)](https://learn.particular.net/courses/distributed-systems-design-fundamentals-online) — A free introductory course by Udi Dahan covering the foundational ideas (fallacies, coupling, messaging basics) that the full ADSD course expands upon.

---

## 1. Fallacies of Distributed Computing

The ADSD course opens with the fallacies of distributed and enterprise computing — the false assumptions developers make about networks, latency, bandwidth, and system maintainability.

- [Understanding the 8 Fallacies of Distributed Systems – Simple Oriented Architecture](https://simpleorientedarchitecture.com/8-fallacies-of-distributed-systems/) — A thorough walkthrough of each fallacy with practical implications and solutions, including aggregates, CQRS, and bounded contexts.
- [Fallacy #8: The Network is Homogeneous – Particular Software](https://particular.net/blog/the-network-is-homogeneous) — From the free DSDF course. Explores semantic interoperability: the real challenge isn't protocols but whether two systems truly understand each other's data.
- [Fallacies of Distributed Computing Explained – Arnon Rotem-Gal-Oz (PDF)](https://pages.cs.wisc.edu/~zuyu/files/fallacies.pdf) — The classic paper expanding on each of the original eight fallacies with real-world examples and consequences.

---

## 2. Coupling: Platform, Temporal & Spatial

Understanding the multiple dimensions of coupling is fundamental to ADSD. Udi identifies five dimensions and shows how reducing one may require accepting more of another.

- [ADSD Course Notes (GitHub Gist – Craig Phillips)](https://gist.github.com/craigtp/05a82b51557adc278acd71b5a2b88905) — Comprehensive community notes covering all ADSD modules, including detailed coverage of the coupling dimensions, messaging patterns, service boundaries, and domain modeling.
- [ADSD Course Summary – Conquer the Lawn](https://conquerthelawn.com/advanced-distributed-systems-design-course-summary/) — An excellent summary focusing on the shift from traditional design to SOA thinking, covering coupling, messaging, and the motivations behind the approach.

### From milestone.topics.it

- [Someone says event, and magically, coupling goes away](https://milestone.topics.it/2024/02/16/events-magic.html) (2024-02-16) — Events as a false cure for coupling; gold plating that fires back.
- [Back to Basics: service boundaries, autonomous components, and coupling](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html) (2023-05-17) — Foundation-building on what coupling means across service boundaries. *(Also relevant to §4 SOA and §5 Finding Service Boundaries.)*
- [Not all changes are born equal](https://milestone.topics.it/2021/03/10/not-all-changes-are-born-equal.html) (2021-03-10) — Good coupling vs. bad coupling, and understanding the impact of changes.
- [You don't need that abstraction](https://milestone.topics.it/2021/12/20/you-dont-need-that-abstraction.html) (2021-12-20) — Over-abstraction as a source of cognitive load and unnecessary coupling.

---

## 3. Messaging: Bus vs. Broker

The distinction between Bus and Broker architectural styles, and why "smart endpoints, dumb pipes" matters for autonomous services.

- [Loosely-Coupled Orchestration with Messaging – Udi Dahan (Particular Software)](https://particular.net/videos/loosely-coupled-orchestration-with-messaging) — A recorded talk by Udi on how to use messaging patterns for loosely-coupled orchestration, including pub/sub, sagas, and gradual adoption.
- [Enterprise Integration Patterns – Gregor Hohpe & Bobby Woolf](https://www.enterpriseintegrationpatterns.com/) — The canonical reference for messaging patterns: channels, routers, transformers, and endpoints. Essential companion to the messaging concepts in ADSD.
- [NServiceBus Documentation – Messaging Concepts](https://docs.particular.net/nservicebus/messaging/) — The NServiceBus docs are an excellent practical reference for the messaging patterns discussed in ADSD.

### From milestone.topics.it

- [Back to Basics: commands, events, and messages](https://milestone.topics.it/2023/05/25/back-to-basics-messages.html) (2023-05-25) — Clarifying the difference between commands, events, and messages on the wire.
- [The pitfalls of request/response over messaging](https://milestone.topics.it/2023/01/19/pitfalls-of-request-response-over-messaging.html) (2023-01-19) — Why request/response over a message bus introduces subtle problems.
- [Isn't A supposed to come before B? On message ordering in distributed systems](https://milestone.topics.it/2021/10/20/isnt-a-supposed-to-come-before-b.html) (2021-10-20) — Challenging the assumption that message ordering exists or matters.
- [Transactions? None for me, thanks](https://milestone.topics.it/2021/01/30/transactions-none-for-me-thanks.html) (2021-01-30) — Use cases for unreliable (non-transactional) message processing.
- [You don't have to be cool to rule my world, KISS](https://milestone.topics.it/2019/05/08/dont-have-to-be-cool-to-rule-my-world.html) (2019-05-08) — HTTP vs. messaging: shedding light on the system's logical architecture.
- [AsyncAPI, a specification for defining asynchronous APIs](https://milestone.topics.it/2022/02/23/asyncapi-tool-in-our-toolbox.html) (2022-02-23) — Governance for events that cross service boundaries; not all events are born equal.
- [Distributed systems evolution: message contracts](https://milestone.topics.it/2022/07/04/messages-evolution.html) (2022-07-04) — Evolving message contracts: inside-out approach, receivers before senders, strong typing vs. flexibility. *(Also relevant to §10 Evolving from a Big Ball of Mud.)*

---

## 4. Service-Oriented Architecture (SOA)

The core of ADSD: services as "the technical authority for a specific business capability." Services own all their data, business rules, and UI from top to bottom.

- [Udi Dahan on Defining Service Boundaries – InfoQ](https://www.infoq.com/news/2015/02/service-boundaries-healthcare/) — Summary of Udi's NDC London talk on finding service boundaries using the healthcare domain. Key takeaway: services aren't wrappers around entities or functions — they encapsulate entire business capabilities.
- [On That Microservices Thing – Udi Dahan](https://udidahan.com/2014/03/31/on-that-microservices-thing/) — Udi's critique of microservices: they're often too fine-grained and miss the critical concerns of real boundaries and UI ownership.
- [Services, Microservices, Bounded Context, Actors.. The Lot – Hemant Kumar](https://hemantkumar.net/services-microservices-bounded-context.html) — Reflections on the DDD Exchange panel with Udi Dahan and Eric Evans, exploring the definitions of services vs. microservices and what boundaries truly mean.
- [What Is A Microservice Architecture? – James Michael Hickey](https://www.jamesmichaelhickey.com/microservices-architecture/) — Discusses how Udi's approach to SOA differs from common microservice thinking, emphasizing data ownership and UI encapsulation.

### From milestone.topics.it

- [How many (micro)services do I need?](https://milestone.topics.it/2023/03/15/how-many-services.html) (2023-03-15) — Guidance on service granularity; avoiding the "thousands of microservices" trap.
- [Autonomy probably doesn't mean what you think it means](https://milestone.topics.it/2022/09/05/autonomy.html) (2022-09-05) — Different meanings of "autonomous" depending on context and observer.
- [Where we're going, we don't need service discovery](https://milestone.topics.it/2022/03/12/where-we-are-going.html) (2022-03-12) — Service discovery as a solution in search of a problem in proper SOA.
- [What is the deal with security and distributed systems?](https://milestone.topics.it/2022/11/01/security-and-soa.html) (2022-11-01) — Security as authentication, authorization, and users & rights management in SOA; security is not a service.
- [Is it complex? Break it down!](https://milestone.topics.it/2022/01/03/is-it-complex-break-it-down.html) (2022-01-03) — Choosing technology based on perceived complexity vs. looking deeper at the problem.
- [To API, or not to API. Is this a real problem?](https://milestone.topics.it/2021/03/24/to-api-or-to-not-api.html) (2021-03-24) — Many API versioning headaches stem from APIs that shouldn't exist.
- [There is no such thing as orchestration](https://milestone.topics.it/2021/07/08/no-orchstration.html) (2021-07-08) — Orchestration as a subtle form of coupling in long-running processes. *(Also relevant to §8 Sagas.)*
- [Let's get logical! On logical and physical architectural views](https://milestone.topics.it/2022/01/25/lets-get-logical.html) (2022-01-25) — Logical vs. physical boundaries; understanding leads to simpler solutions.

---

## 5. Finding Service Boundaries

One of the hardest and most valuable skills taught in ADSD: identifying the correct service boundaries by looking at data volatility, business capabilities, and what changes together.

- [Finding Service Boundaries – Illustrated in Healthcare (NDC London) – Udi Dahan](https://udidahan.com/2015/02/02/finding-service-boundaries-illustrated-in-healthcare/) — Blog post linking to the recorded NDC presentation where Udi works through the healthcare domain to demonstrate boundary identification.
- [All Our Aggregates Are Wrong – Mauro Servienti (Particular Software)](https://particular.net/webinars/all-our-aggregates-are-wrong) — A deep dive into how traditional aggregate design breaks down when you start examining real business requirements, and how data that appears to belong together often doesn't.
- [All Our Aggregates Are Wrong – NDC Talk (Class Central)](https://www.classcentral.com/course/youtube-all-our-aggregates-are-wrong-mauro-servienti-140502) — The NDC conference recording of the same talk: an excellent 58-minute exploration of why we need to decompose aggregates by looking at what data truly changes together.
- [Udi Dahan – The Biggest Mistakes Teams Make When Applying DDD – Gojko Adzic](https://gojko.net/2010/06/11/udi-dahan-the-biggest-mistakes-teams-make-when-applying-ddd/) — Summary of Udi's DDD Exchange talk on common DDD mistakes: confusing layers with tiers, assuming race conditions are business logic, and how naming conventions mislead service boundary identification.

### From milestone.topics.it

- [Do not trust the user mental model: Model behaviors, not data](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html) (2021-02-02) — The user mental model isn't always the right guide for decomposition; model behaviors instead. *(Also relevant to §9 Domain Modeling.)*
- [Tales of a reservation](https://milestone.topics.it/2021/05/05/tales-of-a-reservation.html) (2021-05-05) — How business requirements shape system design; invariants and trust in distributed systems. *(Also relevant to §9 Domain Modeling.)*
- [Own the cache!](https://milestone.topics.it/2021/07/15/own-the-cache.html) (2021-07-15) — Data ownership extends to caches; who owns the cache matters for boundaries.
- [A thorough UX analysis is part of the solution](https://milestone.topics.it/2021/04/02/a-thorough-ux-analysis-is-part-of-the-solution.html) (2021-04-02) — Decomposing a monolith leads to task-based UIs; UX analysis, not technology, is the answer.

---

## 6. UI Composition

In ADSD, each service owns its slice of the UI. Screens are composed from multiple services, each contributing their own data and widgets.

- [UI Composition Techniques for Correct Service Boundaries – Udi Dahan](https://udidahan.com/2012/06/23/ui-composition-techniques-for-correct-service-boundaries/) — How to handle forms and screens that collect data belonging to multiple services, using the Marriott reservation system as an example.
- [UI Composition vs. Server-side Orchestration – Udi Dahan](https://udidahan.com/2012/07/09/ui-composition-vs-server-side-orchestration/) — Addresses the objection that UI composition just moves orchestration to the client side, and explains the fundamental architectural difference.
- [Particular Software Workshop (GitHub)](https://github.com/Particular/Workshop) — Hands-on exercises including UI composition, based on the SOA Done Right workshop that builds on ADSD concepts.

### From milestone.topics.it — ViewModel Composition Series (in reading order)

- [What is Services ViewModel Composition, again?](https://milestone.topics.it/2019/02/06/what-is-services-viewmodel-composition-again.html) (2019-02-06) — The dichotomy between backend decomposition and frontend user expectations.
- [The Services ViewModel Composition maze](https://milestone.topics.it/2019/02/20/viewmodel-composition-maze.html) (2019-02-20) — Single Item and Lists Composition as two fundamental patterns.
- [Into the darkness of ViewModels Lists Composition](https://milestone.topics.it/2019/02/28/into-the-darkness-of-viewmodel-lists-composition.html) (2019-02-28) — Lists composition without flooding servers; requests ≤ number of services.
- [ViewModel Composition: show me the code!](https://milestone.topics.it/2019/03/06/viewmodel-composition-show-me-the-code.html) (2019-03-06) — Single Item Composition in C# code with IHandleRequests.
- [There is no such thing as cross-service ViewModel Composition](https://milestone.topics.it/2019/03/13/there-is-no-such-thing-as-cross-services-composition.html) (2019-03-13) — Don't use composition to let services share data; that's a distributed monolith.
- [The ViewModels Lists Composition Dance](https://milestone.topics.it/2019/03/21/the-viewmodels-lists-composition-dance.html) (2019-03-21) — Choreography of multiple components producing a composed list.
- [Read models: a knot to untie](https://milestone.topics.it/2019/03/26/read-models-a-knot-to-untie.html) (2019-03-26) — Read models as a tempting but costly alternative to composition.
- [Turn on the motors](https://milestone.topics.it/2019/04/03/turn-on-the-motors.html) (2019-04-03) — Inside the Composition Gateway: ASP.NET Core routing to composition engine.
- [Slice it!](https://milestone.topics.it/2019/04/09/slice-it.html) (2019-04-09) — Front-end autonomy through composition; no orchestration needed.
- [The fine art of dismantling](https://milestone.topics.it/2019/04/18/the-fine-art-of-dismantling.html) (2019-04-18) — ViewModel Decomposition: writing data back to multiple services.
- [Safety first!](https://milestone.topics.it/2019/05/02/safety-first.html) (2019-05-02) — Reliable decomposition with messaging and the Outbox pattern. *(Also relevant to §3 Messaging.)*
- [The Quest for better Search](https://milestone.topics.it/soa-search/2019/05/15/the-quest-for-better-search.html) (2019-05-15) — Search in distributed systems: what it means and the problems it raises.
- [Search is a Team Effort](https://milestone.topics.it/soa-search/2019/05/22/search-is-a-team-effort.html) (2019-05-22) — Designing search across service boundaries; like a pit stop crew.
- [The Price of Freedom](https://milestone.topics.it/2019/06/13/the-price-of-freedom.html) (2019-06-13) — UI design choices in distributed systems; flexibility vs. anarchy.
- [Paging and sorting in distributed systems, oh my!](https://milestone.topics.it/2020/01/27/paging-and-sorting-in-distributed-systems-oh-my.html) (2020-01-27) — Paging and sorting don't have to be controversial, even in distributed systems.
- [OK Mauro, but I want to do paging AND sorting](https://milestone.topics.it/2020/03/06/ok-mauro-but-i-want-to-do-paging-and-sorting.html) (2020-03-06) — Combining paging and sorting; exponential coordination vs. search-like techniques.
- [On ViewModel Composition and UI Composition](https://milestone.topics.it/2021/04/20/on-viewmodel-composition-and-ui-composition.html) (2021-04-20) — They are not the same thing; different problems, best used together.
- [On working with a ViewModel Composition based system](https://milestone.topics.it/2021/11/23/on-working-with-viewmodel-composition-based-system.html) (2021-11-23) — Real-world practicalities: repositories, CI/CD, team competencies, and when not to use it.
- [You want to compose emails, right?](https://milestone.topics.it/2021/07/02/you-want-to-compose-emails-right.html) (2021-07-02) — Email composition has the same challenges as ViewModel Composition.
- [Update me, please](https://milestone.topics.it/2021/08/03/update-me-please.html) (2021-08-03) — Notifications infrastructure in distributed systems using composition techniques.

### From milestone.topics.it — ServiceComposer (the framework)

- [ServiceComposer contract-less composition request handlers](https://milestone.topics.it/2025/04/23/contract-less-handlers.html) (2025-04-23) — New ASP.NET controller-like syntax for composition handlers.
- [All the new goodies in ServiceComposer](https://milestone.topics.it/2025/01/08/all-new-goodies-in-servicecomposer.html) (2025-01-08) — Endpoint filters, improved event handling, declarative model binding.
- [Please welcome Attribute Routing to ServiceComposer](https://milestone.topics.it/2021/02/11/please-welcome-attribute-routing-to-servicecomposer.html) (2021-02-11) — Attribute routing via ASP.NET Endpoints; decentralized route configuration.
- [Please welcome Model Binding and Formatters to ServiceComposer](https://milestone.topics.it/2021/04/14/please-welcome-model-binding-formatters-to-servicecomposer.html) (2021-04-14) — Model binding support to reduce infrastructure code.

---

## 7. CQRS (Command Query Responsibility Segregation)

ADSD connects CQRS to collaborative domains, task-based UIs, and the saga pattern. CQRS isn't about separate databases — it's about recognizing that reads and writes have fundamentally different needs.

- [Race Conditions Don't Exist – Udi Dahan](https://udidahan.com/2010/08/31/race-conditions-dont-exist/) — The foundational blog post arguing that apparent race conditions are symptoms of insufficient domain understanding. If you think you have a race condition, go back to the business.
- [Clarified CQRS – Udi Dahan](https://udidahan.com/2009/12/09/clarified-cqrs/) — Udi's clarification of CQRS, separating it from event sourcing and explaining when and why it's appropriate.
- [CQRS Documents – Greg Young](https://cqrs.files.wordpress.com/2010/11/cqrs_documents.pdf) — Greg Young's seminal document on CQRS, covering commands, events, and the relationship between CQRS and event sourcing.

### From milestone.topics.it

- [I gotta tell you: CQRS doesn't imply Event Sourcing](https://milestone.topics.it/2024/01/27/cqrs-and-es.html) (2024-01-27) — Debunking the assumption that CQRS requires Event Sourcing.
- [Can we predict the future?](https://milestone.topics.it/2021/06/02/can-we-predict-the-future.html) (2021-06-02) — Eventual consistency and UI options when data isn't immediately consistent.
- [Ehi! What's up? Feedback to users' requests in distributed systems](https://milestone.topics.it/2021/01/12/feedback-to-users-requests-in-distributed-systems.html) (2021-01-12) — How to provide feedback when request handling is async and results are eventually consistent.
- [What if my command was rejected?](https://milestone.topics.it/2023/06/27/reject-commands.html) (2023-06-27) — A different mindset for dealing with async processes and failures; maybe we can avoid rejecting that command. *(Also relevant to §8 Sagas.)*
- [Append-only models: The why, the when, and the how](https://milestone.topics.it/2023/09/22/append-only.html) (2023-09-22) — When to use insert-only persistence; relationship with projections and read models. *(Also relevant to §9 Domain Modeling.)*

---

## 8. Long-Running Processes & Sagas

Sagas in ADSD are not just a database pattern — they are the domain model. Business processes that span time are modeled as sagas (or "policies") rather than traditional aggregates.

- [NServiceBus Sagas Documentation](https://docs.particular.net/nservicebus/sagas/) — Official documentation covering saga implementation, auto-correlation, timeouts, and concurrency handling.
- [Saga Concurrency – NServiceBus Docs](https://docs.particular.net/nservicebus/sagas/concurrency) — Deep dive into how NServiceBus handles concurrent messages for the same saga instance using optimistic and pessimistic concurrency.
- [Workflows: Choreography vs. Orchestration – NServiceBus Architecture Docs](https://docs.particular.net/architecture/workflows) — How to choose between choreographed (event-driven pub/sub) and orchestrated (saga-managed) workflows, and when to combine them.
- [Consistency Patterns – NServiceBus Architecture Docs](https://docs.particular.net/architecture/consistency) — Covers the transactional outbox pattern, idempotency, deduplication, and compensating actions for achieving consistency in distributed systems.

### From milestone.topics.it

- [Compensation is all around us](https://milestone.topics.it/2023/11/28/compensation.html) (2023-11-28) — Compensating changes in message-based systems; real life compensates every day.
- [The power of timeouts to compensate for failures and other tales](https://milestone.topics.it/2023/10/18/timeouts-power.html) (2023-10-18) — Using timeouts to untangle chatty service relationships and compensate for failures.
- [What's an Outbox and why do we need it?](https://milestone.topics.it/2023/02/07/outbox-what-and-why.html) (2023-02-07) — The Outbox pattern for data integrity: deduplication, exactly-once processing, and failure scenarios.
- [Don't keep a saga in both camps](https://milestone.topics.it/2021/07/28/dont-keep-a-saga-in-both-camps.html) (2021-07-28) — Orchestration as subtle coupling; sagas, outbox, and transactional boundaries.
- [Got the time](https://milestone.topics.it/2021/03/05/got-the-time.html) (2021-03-05) — Modeling time in sagas: the ticking time bomb model vs. batch jobs; duplicate and out-of-order messages.
- [I'll be back](https://milestone.topics.it/2021/02/08/ill-be-back.html) (2021-02-08) — Modeling the passage of time: clock drift, design choices, and saga timeouts.
- [Ooops, can I try again, please?](https://milestone.topics.it/2021/01/21/ooops-can-I-try-again-please.html) (2021-01-21) — Retrying subsets of a process; not all failures are born equal.

---

## 9. Domain Modeling in SOA Context

ADSD reframes domain modeling: model processes, not entities. Find the smallest possible consistency boundaries and let behaviors define how data is grouped.

- [Udi Dahan's ADSD with SOA & DDD – Thoughts and Revelations (Google Groups)](https://groups.google.com/g/dddcqrs/c/K5PbX5HoQZo) — A practitioner's post-course reflections on the revelation that sagas and aggregates are essentially synonymous in Udi's approach, and why modeling processes instead of entities yields smaller, better consistency boundaries.
- [What I Learned from the $2500 Udi Dahan Course – Michał Białecki](https://www.michalbialecki.com/2020/06/23/what-i-learned-from-2500-udi-dahan-course/) — Practical takeaways including the "don't mimic the real world" insight for domain modeling, the importance of service boundaries, and the "use whatever fits the problem best" philosophy.
- [Domain-Driven Design: Tackling Complexity in the Heart of Software – Eric Evans](https://www.domainlanguage.com/ddd/) — The foundational DDD book. While ADSD challenges some traditional DDD patterns (especially around aggregates), the concepts of bounded contexts, ubiquitous language, and strategic design are deeply complementary.

### From milestone.topics.it

- [Do not trust the user mental model: Model behaviors, not data](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html) (2021-02-02) — The user mental model isn't always the right guide for decomposition; model behaviors instead. *(Primary listing under §5.)*
- [Tales of a reservation](https://milestone.topics.it/2021/05/05/tales-of-a-reservation.html) (2021-05-05) — How business requirements shape system design; invariants and trust in distributed systems. *(Primary listing under §5.)*
- [Append-only models: The why, the when, and the how](https://milestone.topics.it/2023/09/22/append-only.html) (2023-09-22) — When to use insert-only persistence; deeply tied to modeling persistence for distributed domains. *(Primary listing under §7.)*

---

## 10. Evolving from a Big Ball of Mud

ADSD devotes significant time to the practical transition from a monolithic "big ball of mud" to SOA, using a phased approach.

- [Live Q&A with Udi – Particular Software](https://particular.net/webinars/2020-live-qna-with-udi) — Udi answers questions about service boundaries, data ownership, and how to practically evolve existing systems. Addresses the tension between enterprise-level and system-level SOA.
- [Azure & DevOps Podcast: Udi Dahan on Microservices – Episode 32](https://azuredevopspodcast.clear-measure.com/udi-dahan-on-microservices) — Udi's advice on moving from legacy monoliths to distributed systems without starting from scratch, including how big a microservice should really be.

### From milestone.topics.it — Distributed Systems Evolution Series

- [Distributed systems evolution challenges](https://milestone.topics.it/2022/06/11/distributed-systems-evolution-challenges.html) (2022-06-11) — Series overview: messages, data structures, I/O devices, in-flight messages, retroactive changes, deployment.
- [Distributed systems evolution: message contracts](https://milestone.topics.it/2022/07/04/messages-evolution.html) (2022-07-04) — Inside-out evolution, receivers before senders, strong typing tradeoffs. *(Also listed under §3 Messaging.)*
- [Distributed systems evolution: processes state](https://milestone.topics.it/2022/07/12/processes-state-evolution.html) (2022-07-12) — Evolving persisted saga state and running processes.
- [Distributed systems evolution: topology changes](https://milestone.topics.it/2022/07/25/topology-changes.html) (2022-07-25) — Deployments as a source of evolution challenges: endpoint splitting, routing changes, competing consumers.

---

## 11. Cross-Cutting: Observability & Governance

These resources relate to operational concerns discussed across the ADSD course.

### From milestone.topics.it

- [We need insights, not data](https://milestone.topics.it/2022/04/19/we-need-insights-not-data.html) (2022-04-19) — Raw data vs. actionable insights; monitoring belongs to vendors, analysis belongs to the business.
- [Do we need to debug distributed systems?](https://milestone.topics.it/2022/05/23/do-we-need-to-debug-distributed-systems.html) (2022-05-23) — Challenging the instinct to debug distributed systems the way we debug monoliths.

---

## 12. NServiceBus Tooling & Implementation

Practical resources on the NServiceBus stack that support ADSD concepts in code.

### From milestone.topics.it

- [Mattox: simple, pre-configured NServiceBus endpoints](https://milestone.topics.it/2024/01/08/mattox-endpoints.html) (2024-01-08) — Microsoft configuration extensions for NServiceBus endpoint setup.
- [A small ServiceControl maintenance utility](https://milestone.topics.it/2024/04/09/service-control-ghost-endpoints.html) (2024-04-09) — Open-source tool for ServiceControl maintenance tasks.
- [NServiceBus.IntegrationTesting baby steps](https://milestone.topics.it/2021/04/07/nservicebus-integrationtesting-baby-steps.html) (2021-04-07) — Integration testing for NServiceBus endpoints.
- [I built a thing, well...two](https://milestone.topics.it/2019/06/19/i-built-a-thing-well-two.html) (2019-06-19) — NServiceBus routing engine tooling.

---

## 13. Foundational Papers & Books

These complement the ADSD curriculum and are frequently referenced by Udi and the distributed systems community.

### Papers

- [Life Beyond Distributed Transactions: An Apostate's Opinion – Pat Helland (ACM Queue)](https://queue.acm.org/detail.cfm?id=3025012) — Essential reading. Helland describes how to build scalable systems without distributed transactions using entities, activities, and messaging. Directly underpins ADSD's approach to consistency boundaries.
- [Life Beyond Distributed Transactions – Original Paper (PDF)](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — The original 2007 CIDR paper by Pat Helland.
- [Life Beyond Distributed Transactions: Implementation Primer – Jimmy Bogard](https://www.jimmybogard.com/life-beyond-transactions-implementation-primer/) — A practical walkthrough of implementing Helland's ideas in code with real examples.
- [Original 1987 Sagas Paper – Hector Garcia-Molina & Kenneth Salem (PDF)](https://www.cs.cornell.edu/andru/cs711/2002fa/reading/sagas.pdf) — The database-community paper that coined the term "saga" for long-lived transactions. Understanding the origin helps contextualize how ADSD extends the concept.

### Books

- **Enterprise Integration Patterns** – Gregor Hohpe & Bobby Woolf — [enterpriseintegrationpatterns.com](https://www.enterpriseintegrationpatterns.com/) — The definitive reference for messaging patterns. Many ADSD concepts map directly to patterns in this book.
- **Domain-Driven Design** – Eric Evans — [domainlanguage.com/ddd](https://www.domainlanguage.com/ddd/) — Strategic DDD concepts (bounded contexts, context mapping) are foundational to ADSD's approach to service boundaries.
- **Implementing Domain-Driven Design** – Vaughn Vernon — Provides practical implementation guidance that bridges DDD and messaging/event-driven architectures.
- **Designing Data-Intensive Applications** – Martin Kleppmann — Covers distributed systems fundamentals (replication, partitioning, consistency, transactions) with exceptional clarity. Excellent technical companion to ADSD's more architectural focus.

---

## 14. Talks, Webinars & Videos

### Udi Dahan

- [Q&A on Advanced Distributed Systems with Udi Dahan (2021)](https://particular.net/videos/ndeva-qa-with-udi) — 85-minute Q&A covering service boundaries, distributed monoliths, data ownership, and front-end composition.
- [Fireside Chat with Udi Dahan (2021)](https://particular.net/videos/fireside-chat-with-udi-dahan) — Wide-ranging discussion on DDD, SOA, CQRS, sagas, event sourcing, microservices, and the historical context of the saga pattern from its 1987 origins.
- [Udi Dahan – DDD Europe 2017 Speaker Page](https://2017.dddeurope.com/speakers/udi-dahan/) — Links to Udi's DDD Europe talks on race conditions, CQRS, long-running processes, and microservices workshops.

### Mauro Servienti

- [Mauro Servienti — Conference Talks (YouTube Playlist)](https://www.youtube.com/playlist?list=PLhm595Y7ah_E42m_EwnSvqeMLVCD2EMb5) — Collection of conference presentations covering service boundaries, UI composition, and sagas.
- [All Our Aggregates Are Wrong (NDC)](https://www.youtube.com/watch?v=KkzvQSuYd5I) — Analyzes a seemingly straightforward e-commerce shopping cart, showing how evolving requirements expose incorrect aggregate boundaries and how decomposing by business need leads to better design. *(See also §5.)*
- [Designing a UI for Microservices](https://particular.net/videos/designing-a-ui-for-microservices) — Building a .NET Core composite UI from scratch: ViewModel Composition, the composition gateway, and how services each contribute their own slice of the front-end. *(See also §6.)*
- [Welcome to the (State) Machine](https://particular.net/videos/welcome-to-the-state-machine) — Busts the "stateless is always better" myth. Covers sagas as the way to model collaborative domains, compensating actions, timeouts, and distributed business processes without orchestration. *(See also §8.)*
- [Tales from the Trenches: Creating Complex Distributed Systems](https://particular.net/webinars/tales-from-the-trenches-creating-complex-distributed-systems) — Interview with Neel Shah (Strasz Assessment Systems) about real-world challenges applying ADSD principles with NServiceBus.

### Adam Ralph

- [Finding Your Service Boundaries: A Practical Guide](https://www.youtube.com/watch?v=9ix0vVL34-M) — Practical advice on discovering hidden boundaries in your systems. Adam teases out the natural separation of concerns in a sample business domain, covering fat events, what a service is (and isn't), and how to avoid the path to "the big rewrite." *(See also §5.)*
- [Finding Your Service Boundaries: A Practical Guide (Webinar)](https://www.youtube.com/watch?v=jdliXz70NtM) — Particular Software webinar version of the same topic with live Q&A, hosted by Mauro Servienti. Includes audience questions on UI composition, team organization, and adopting ADSD concepts incrementally.

### Dennis van der Stelt

- [Death of the Batch Job](https://youtu.be/jTz74m1KbBs) — How NServiceBus sagas replace fragile nightly batch jobs with event-driven, saga-based workflows using durable timeouts, compensation, and the saga pattern for preferred-customer-status scenarios. *(See also §8.)*
- [Autonomous Microservices Don't Share Data. Period. (NDC Porto 2023)](https://www.youtube.com/watch?v=_UN50hNZlx4) — A journey through the evolution of software architecture — from procedural to SOA to microservices — landing on why data ownership and clear service boundaries are non-negotiable. Covers composite UIs, event-driven communication, and vertical service pillars. *(See also §4 and §5.)*
- [Autonomous Microservices Don't Share Data. Period. (Øredev 2023)](https://www.youtube.com/watch?v=Zkj7R4Q1thw) — Conference version of the same talk at Øredev, with Dennis's signature Lessig-style 400+ slide presentation.
- [DSDF Course Q&A (Particular Software)](https://particular.net/webinars/dsdf-course-questions-answered-live) — Follow-up Q&A for the free Distributed Systems Design Fundamentals course, covering practical questions on messaging, sagas, priority queues, and adoption strategies.

### Tomer Gabel

- [Microservices: A Retrospective (Øredev 2019)](https://youtu.be/7kHnuO7JzoE) — Now that the microservices hype has settled, what have we actually learned? Tomer analyzes the lessons hammered into us through adoption, and takes a hard look at the challenges we still struggle with as an industry. A thoughtful complement to the ADSD perspective on service decomposition. *(See also §4.)*

### Laila Bougria

- [Orchestration vs. Choreography: The Good, the Bad, and the Trade-offs](https://www.youtube.com/watch?v=U8Aame0akl4) — Uses a mortgage-application analogy to explore when to orchestrate vs. choreograph, hidden assumptions in the "orchestrate within, choreograph across" rule of thumb, and why getting service boundaries right matters more than picking a pattern. *(See also §8.)*
- [Messaging: The Fine Line Between Awesome and Awful](https://www.youtube.com/watch?v=pImwOEsQkQo) — The real-world challenges of adopting messaging: structuring code for messaging, duplicate messages, ordering issues, communication patterns (commands, events, pub/sub), and techniques for system consistency. *(See also §3.)*
- [Message Processing Failed... But What's the Root Cause?](https://www.youtube.com/watch?v=nWPk7rellM0) — Debugging distributed systems when there's no single call stack. Covers OpenTelemetry instrumentation, distributed tracing, modeling techniques, and integration testing to find the proverbial needle in a haystack. *(See also §11.)*
- [Fireside Chat: Orchestration and Choreography with Laila Bougria & Udi Dahan](https://particular.net/webinars/2023-orchestration-choreography-qa) — Virtual DDD panel exploring how orchestration and choreography relate to bounded contexts, maintainability, and the trade-offs involved in choosing between them.

### Caitie McCaffrey

- [Applying the Saga Pattern](https://www.youtube.com/watch?v=ZMbqbXxRthE) — Fundamentals of the saga pattern for long-lived transactions and distributed coordination without 2PC. Includes how Halo 4 services used sagas for processing game statistics in production. A highly recommended complement to the 1987 Sagas paper (§13). *(See also §8.)*

### General

- [Particular Software Videos & Presentations](https://particular.net/videos) — Full archive of talks from Udi Dahan, Laila Bougria, Adam Ralph, Dennis van der Stelt, and other Particular team members on distributed systems topics.

---

## 15. Course Reviews & Community Notes

These provide different perspectives on the ADSD material and can help reinforce or clarify concepts.

- [ADSD Course Notes – Craig Phillips (GitHub Gist)](https://gist.github.com/craigtp/05a82b51557adc278acd71b5a2b88905) — The most comprehensive community notes available. Covers every module with detailed notes on coupling dimensions, Bus vs. Broker, SOA building blocks, IT/Ops services, CQRS, sagas, and the migration phases.
- [Review of ADSD Online Course – Dmytro Khmara](https://www.dmytrokhmara.com/blog/advanced-distributed-system-design-review) — Detailed review covering course structure, format options, cost, and an overview of all topics.
- [ADSD Course Summary – Conquer the Lawn](https://conquerthelawn.com/advanced-distributed-systems-design-course-summary/) — Highlights four main takeaways: fallacies, implicit coupling in traditional design, SOA as an alternative, and CQRS/sagas.
- [ADSD Course Review – ieva.dev](https://www.ieva.dev/reviews/udi_dahan_adsd.html) — Honest review including the challenge of the "two bucket services" (IT/Ops and Branding) and the difficulty of applying the concepts in practice.
- [ADSD Part 4: Go Forth and Make Things Simple – Tom Cabanski](https://tom.cabanski.com/2012/01/28/advanced-distributed-system-design-with-udi-dahan-part-4-go-forth-and-make-things-simple/) — A four-part series covering the in-person course experience, including the hotel service boundary exercise and web-tier scalability discussion.
- [What I Learned from the $2500 Udi Dahan Course – Michał Białecki](https://www.michalbialecki.com/2020/06/23/what-i-learned-from-2500-udi-dahan-course/) — Key lessons: messaging over RPC, don't use one approach for everything, service boundaries matter, and domain models shouldn't mimic the real world.

---

## 16. Related Blogs

- [Udi Dahan's blog](https://udidahan.com/?blog=true) — The full blog archive from the ADSD course creator. Key posts include topics on service boundaries, entity ownership, the problems with layered architectures, and why services are not remotely callable components.
- [Daniel Marbach's blog](https://www.planetgeek.ch/author/danielmarbach/) — Daniel Marbach (Particular Software) writes in-depth technical content focused on Azure Service Bus and NServiceBus internals. His standout series is the *Azure Service Bus .NET SDK Deep Dive*, covering topics like message deduplication, sessions, dead-letter queues, send-via transactions, sender-side batching, atomic sends, pub/sub with topics, forwarding, topologies, and runtime information. Earlier posts explored NServiceBus transport comparisons (MSMQ vs. RabbitMQ vs. ActiveMQ), dependency injection integration (Ninject), unit of work patterns, and high-throughput message processing optimizations. The blog is particularly valuable for understanding the low-level mechanics of Azure Service Bus and how NServiceBus leverages them.
- [Dennis van der Stelt's blog](https://bloggingabout.net/) — Dennis van der Stelt (Particular Software) blogs about distributed systems, messaging, and software architecture. Recent posts include an explanation of the Two Generals' Problem using a Star Wars analogy, a piece on why shared databases are problematic with microservices, and thoughts on AI pair programming. Earlier content includes NServiceBus tutorials on publish/subscribe, an explanation of what a service bus is, message priority handling strategies, and his *Death of the Batch Job* saga presentation. The blog has been active since 2004 (originally a community blogging platform) and blends practical NServiceBus guidance with architectural thinking and the occasional fun cultural tangent.

---

## 17. Samples & Demos

- [distributed-systems-101](https://github.com/mauroservienti/distributed-systems-101) — A progressive, hands-on workshop that teaches distributed systems fundamentals using RabbitMQ. It walks through 12 incremental demos in a Dev Container environment: basic send, request/response, request with multiple responses, basic pub/sub, pub/sub with multiple subscribers, commands and events, recoverability, sagas, timeouts, composition, decomposition, and a shopping cart lifecycle. Also includes JavaScript versions of the demos. *(See also §3 and §8.)*
- [all-our-aggregates-are-wrong-demos](https://github.com/mauroservienti/all-our-aggregates-are-wrong-demos) — Companion demos for the "All Our Aggregates Are Wrong" talk. Implements a microservices-powered e-commerce shopping cart built on SOA principles, demonstrating how traditional aggregate design leads to coupling and how proper service boundary decomposition results in each service owning its slice of the data independently. *(See also §5 and §14.)*
- [welcome-to-the-state-machine-demos](https://github.com/mauroservienti/welcome-to-the-state-machine-demos) — Companion demos for the "Welcome to the (State) Machine" talk. Demonstrates how to model long-running business processes using sagas as state machines, including timeout handling, compensating actions, and coordination across service boundaries without introducing coupling. *(See also §8 and §14.)*
- [designing-a-ui-for-microservices-demos](https://github.com/mauroservienti/designing-a-ui-for-microservices-demos) — Companion demos for the "Designing a UI for Microservices" talk. Shows how to build composite UIs where each service owns its piece of the user interface, using ViewModel Composition to assemble data from multiple autonomous services into a single view without creating a shared API or monolithic frontend. *(See also §6 and §14.)*

---

## 18. Dynamic Consistency Boundaries (DCB)

Dynamic Consistency Boundary (DCB) is a pattern introduced by Sara Pellegrini (during her time @ AxonIQ, later she joined Particular Software) in her "Kill Aggregate!" talk and blog series. The core idea is to move away from fixed aggregate-to-stream mappings in event-sourced systems. Instead, each command handler dynamically selects only the events it needs (via tagging/filtering) to enforce its invariants, making consistency boundaries flexible and per-operation rather than per-entity. While DCB originates in the event sourcing community, its thinking about consistency, boundaries, and aggregate design connects directly to ADSD themes around service decomposition and data ownership.

### Talks

- [Kill Aggregate! — Sara Pellegrini (Avanscoperta, April 2023)](https://www.youtube.com/watch?v=DhhxKoOpJe0) — The original presentation introducing DCB, in Italian with English subtitles starting at 2:38. Sara and Milan Savic subsequently presented English variations at DDD FR, JAX Mainz, Spring I/O Barcelona, Voxxed Days Brussels, AxonIQ Conference 2023, and KanDDDinsky.

### Blog posts & articles

- [Chapter 10 — The Aggregate is dead (sara.event-thinking.io)](https://sara.event-thinking.io/2023/04/kill-aggregate-chapter-10-the-aggregate-is-dead.html) — The culminating chapter of Sara's multi-part "Kill Aggregate" blog series, walking through the course subscription example and demonstrating how command handlers build ad-hoc models on the fly from a tagged event store without needing isolated aggregates.
- [Dynamic Consistency Boundaries — Milan Savic (milan.event-thinking.io)](https://milan.event-thinking.io/2025/05/dynamic-consistency-boundaries.html) — Detailed writeup explaining DCB as moving consistency granularity from event streams (aggregates) to individual events, with code samples and a companion [GitHub repository](https://github.com/m1l4n54v1c/event-store). Broadens DCB applicability to any append-only messaging system.
- [Kill Aggregate? An Interview on Dynamic Consistency Boundaries (EventSourcingDB)](https://docs.eventsourcingdb.io/blog/2025/12/15/kill-aggregate-an-interview-on-dynamic-consistency-boundaries/) — Interview with Bastian Waidelich on the practical implementation, ecosystem, misconceptions, and technical requirements of DCB-compliant event stores.
- [Rethinking microservices architecture through Dynamic Consistency Boundaries (AxonIQ)](https://www.axoniq.io/blog/rethinking-microservices-architecture-through-dynamic-consistency-boundaries) — Contextualizes DCB within microservices and bounded contexts, explaining how flexible transactional consistency within a single bounded context improves performance and scalability.
- [Dynamic consistency boundaries (JAVAPRO)](https://javapro.io/2025/10/28/dynamic-consistency-boundaries/) — Article by Milan Savic with code samples exploring how DCB redefines consistency granularity for event stores, moving from streams to individual events.

### Specification & community

- [dcb.events](https://dcb.events/) — The official DCB hub maintained by Bastian Waidelich and Sara Pellegrini. Includes the [specification](https://dcb.events/specification/), [examples](https://dcb.events/examples/) (course subscriptions, unique username, sequential invoice numbering, idempotency), and a [FAQ](https://dcb.events/faq/).

### Implementations

- [bwaidelich/dcb-eventstore](https://github.com/bwaidelich/dcb-eventstore) — PHP implementation of a DCB-compliant event store, with a [course subscription example](https://github.com/bwaidelich/dcb-example-courses).
- [umadb-io/umadb](https://github.com/umadb-io/umadb) — High-performance open-source event store built to the DCB specification (co-authored by Bastian Waidelich, Sara Pellegrini, and Paul Grimshaw).
- [Disintegrate](https://lib.rs/crates/disintegrate) — A Rust library inspired by Kill Aggregate! for building event-sourced applications with flexible consistency boundaries.

---

*Last updated: February 2026*
