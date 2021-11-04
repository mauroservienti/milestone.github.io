---
layout: post
header_image: /img/posts/on-working-with-viewmodel-composition-based-system/header.jpg
title: "On working with a ViewModel Composition based system"
enable_mermaid: true
author: Mauro Servienti
synopsis: "What is it like to work with a ViewModel Composition-based system? And is it always the right choice? So far, we have touched on the architectural part. It's time to answer those fundamental questions."
tags:
- soa
- viewmodel-composition
category: view-model-composition
---

One of the frequently asked questions is what it is like to work on a system that implements a frontend based on ViewModel Composition techniques. I covered the [ViewModel Composition](https://milestone.topics.it/categories/view-model-composition) theory and the technical part from A to Z, but I never touched on what it means to do it effectively.

> This article won't be one of those "real world" kinds of articles that usually have nothing to do with the real world. It's near to impossible to represent the real world in an article. Maybe a book can aim to do it. Maybe.

ViewModel Composition and UI Composition, or micro-frontends if you prefer, are challenging. They require a deep understanding of the architectural concepts, underlying technologies and technical stacks, and deployment pipelines and tools.

> For a detailed description of ViewModel and UI Composition differences, have a look at my ["On ViewModel Composition and UI Composition"](https://milestone.topics.it/view-model-composition/2021/04/20/on-viewmodel-composition-and-ui-composition.html) article.

Instead of modeling a real-world scenario, I'll use a trivial one that comes with all the challenges anyway. And hopefully, it'll be detailed enough to provide insights on designing a real system using ViewModel Composition techniques.

## Architecture view models

Imagine a trivial scenario where we're composing data from two services in one ViewModel to serve the frontend:

<div class="mermaid">
graph LR
    subgraph Webserver A
        A[[Rest API]]
    end
    subgraph Webserver B
        B[[Rest API]]
    end
    subgraph Composition Gateway
        A --> AH[[Composition Handler A]]
        B --> BH[[Composition Handler B]]
        AH --> VM[ViewModel]
        BH --> VM[ViewModel]
    end
    subgraph Browser
        VM-->F[[Frontend]]
    end
</div>

If we're building a distributed system, we're probably also following, more or less intentionally, the [4+1 architecture view model](https://en.wikipedia.org/wiki/4%2B1_architectural_view_model).

The presented diagram is a mix of the physical and process views. It's strictly neither of the two. However, it's useful for our discussion because, in some way, it's the final state: Whatever we're doing, the system, when deployed in production, needs to look like that.

The logical view, however, is quite different:

<div class="mermaid">
graph LR
    subgraph Logical service A
        A((Data))
        A --> AH[Composition Handler A]
    end
    subgraph Logical service B
        B((Data))
        B --> BH[Composition Handler B]
    end
    subgraph Branding service
        AH --> VM[ViewModel]
        BH --> VM
        VM-->F[Presentation]
    end
</div>

> I'm intentionally skipping UI Composition/micro-frontends. It can only be more complex. Please, leave a comment below if you think UI Composition aspects need any further in-depth analysis.

In between the logical and physical/process view of the system sits the development view. The development view enables the logical view to get to life. At the same time, it mediates and adapts from the logical view to the runtime needs respecting the non-functional requirements imposed by the tool-chain in use.

Let's think about the development phase of service A. It's composed of two components: the restful API mediating the data access. The composition handler allows data to flow from the restful API to the view model owned by branding.

## A repository for each logical service

If service A is developed using .NET, it'll be a class library for the composition handler and a web application for the restful API. They could both be in the same solution and repository. We simplify the development and testing phase with the risk of making the deployment a bit more complex. Let's investigate why.

There is coupling between the composition handler and the web API, but there isn't tight coupling. There might be cases in which one component changes without forcing any other in the logical service to change. If that's the case, it means that every deployment of one component doesn't correspond to the deployment of the others. Or in other words, they can be versioned separately. However, if they reside in the same repository, it'll be harder to have different CI/CD pipelines for the various components. Usually, there is a one-to-one relationship between a repository and CI/CD pipelines.
We could compromise and decide to release all the components in the same repository whenever we deploy one. Fine, but consider that there will be "wasted" version numbers, or call them empty releases, for all the non-touched elements, which might result in maintenance issues.

To recap, if we're going down the route of a single repository for each logical service, there will be pros and cons:

- Pros: the overall development process will be smoother
- Pros: multiple components integration testing will be straightforward
- Cons: more complex CI/CD pipelines
- Cons: each release will release all components, even though some might be released with no changes

What else can we do?

## A repository per component 

We could have a different repository for each component: A repository for the restful APIs, one for each composition handler, another for the composed ViewModel, and a last one for the frontend.

CI/CD pipelines would be much easier. The restful API can be deployed independently from other components, and the same goes for all the components. Composition handlers could be deployed as Nuget packages, consumed by the composition gateway host at deployment time. Composition handlers and the fronted would also depend on the ViewModel package.

By doing so, we'd get fine-grained control over packages deployment and versioning. It would be much easier to set up and customize CI/CD pipelines for each component. And we won't waste any version number because each component would only be released when strictly necessary.

That begin said, it's not gold all that glitters. Setting up integration testing is way more complicated when using different repositories for each component. It's not impossible. However, we'll have to spend time designing custom components and tools specifically aimed at supporting integration tests.

Last but not least. Even if it's true that using a repository for each component is a cleaner approach, it'll introduce friction into the development process, especially at the early stages. Let's imagine that we're adding a new restful API. The first step is to change the restful API repository; then, we need to publish the changes so that downstream components can consume them. The development effort then moves onto composition handlers. Update the dependency on the restful API package to have integration tests fail or be able to create the new required tests. Adjust the composition handlers to support the new restful API and publish the package. Apply, if needed, a similar process to the frontend component.

> For more details about integration testing when using HTTP endpoints, take a look at ["You wanna test HTTP, right?"](https://milestone.topics.it/2021/04/28/you-wanna-test-http.html) and the latest [HTTP client and HTTP client factory in integration testing](link).

I wouldn't define the described process as smooth.

As for the previous approach, let's take a look at the pros and cons:

- Cons: the overall development process will come with more frictions
- Cons: multiple components integration testing will be more challenging
- Pros: simpler CI/CD pipelines
- Pros: each release will release only the changed components

Sounds like exactly the opposite of a repository for each logical service. 

From the structure perspective, a few other approaches might sit in the middle of what we described so far. I guess that they would also lead to a similar distribution of pros and cons.

## To conclude: Shall we blindly use ViewModel Composition?

The quick answer is obviously no. And not only for the technical challenges presented in this article.

There are many factors that we should consider before deciding to use ViewModel Composition. For example, the company size, team competencies, and the system's overall complexity are all good metrics to look at before making any final decision. ViewModel Composition will only make things more complex if the company or project is small and the team is not so experienced. It'd be better to design frontends using monolithic architecture. One frontend repository contains all the code and artifacts and knows how to communicate with the distributed systems backend.

It's probably fair to say that a composite UI is the last of the problems; not necessarily the least important, but the last to address.

We tend to think in terms of consequences. The reasoning usually goes like this: if we design that component in a suboptimal way when we'll fix it, it will hurt all these other components.

When it comes to user interfaces, that's not the case. There is no other component that we can break if we revolutionize the user interface or the frontend architecture. A user interface sits at the borders of a system, and no other part depends on it.

More importantly, given the already substantial cognitive load composite UIs carry, they require the least amount of moving parts to reduce the burden created by a system under active development. We want to make sure that we start designing the frontend when the massive changes of a system under heavy development are under control and we see the light at the end of the tunnel.

---

Photo by <a href="https://unsplash.com/@chatelp?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Pierre Châtel-Innocenti</a> on <a href="https://unsplash.com/s/photos/windows?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
