---
layout: post
header_image: /img/posts/lets-get-logical/header.jpg
title: "Let's get Logical! On logical and physical architectural views"
author: Mauro Servienti
synopsis: "Having a deep understanding of the differences between physical and logical boundaries can help shed light on the way we architect systems. Usually, it leads to simpler solutions."
enable_mermaid: true
tags:
- viewmodel-composition
- soa
- architecture
- logical-vs-physical
---

I was born in 1973, and Olivia Newton-John took part in framing my adolescence. Songs like "Let's Get Physical" or "You're The One That I Want," from Grease are part of my background.

<iframe width="560" height="315" src="https://www.youtube.com/embed/6zwPVU92-XQ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Enough talking

If you have been reading my articles about [ViewModel composition](https://milestone.topics.it/categories/view-model-composition) or watched my talks on the topic, you know that all my demos and samples use the following approach:

<div class="mermaid">
flowchart LR
  A[[Client]] --> Gateway
  H --> W[[Rest / Web API]]
  W --> DB[(Storage)]
  subgraph Gateway
    direction LR
    H[Composition handlers]
  end
</div>

> Recordings for both ["All our aggregates are wrong"](https://milestone.topics.it/talks/all-our-aggregates-are-wrong.html) and ["Designing a UI for Microservices"](https://milestone.topics.it/talks/designing-ui-for-microservices.html) talks are available.

If all that is new for you, let me briefly describe what we are talking about: We are in the context of distributed systems, and each service stores data in separate storage.
Clients need to compose data to provide a consistent, unique view to users accessing the system.
For example, if a product price is owned and stored by Sales and a product description by Marketing, we want to show users accessing the system a page with the product price and description. That is because users think about products, not prices and descriptions. A client application can use ViewModel composition techniques to address the data separation issue.

The presented diagram is a synthetic view of what ViewModel composition is. Clients interact with a composition gateway that behaves like a reverse proxy. The composition gateway dispatches incoming requests to handlers that in some way retrieve data from backend services.

Today's culprit is that "some way."

## So, let's get logical!

[Mark's comment](https://milestone.topics.it/view-model-composition/2021/11/23/on-working-with-viewmodel-composition-based-system.html#comment-5626920802) is a good starting point:

> I opted for logical service per repository, mostly because I also opted to remove the service's rest api and instead allow the composition components to talk directly to the logical service's data components (DB, blob storage, etc).
> This has a "con" that couples those composition components to the data schema, meaning a change to schema results in a change not only to backend components that would naturally work directly with a data store but also the viewmodel components. Hence, one repository to encapsulate the coupled change dependencies.
> Side note, I opted for VM component->DB rather than VM component->API->DB for performance (no extra network hop) and security reasons. The latter being that I usually implement token user delegation for API hops so as not to surface downstream oauth "scopes" to users.

Among other things, Mark decided to use an approach that looks like the following:

<div class="mermaid">
flowchart LR
  A[[Client]] --> Gateway
  H --> DB[(Storage)]
  subgraph Gateway
    direction LR
    H[Composition handlers]
  end
</div>

Mark solves the composition problem using a shorter, all-in-all better approach. As you can see, instead of having composition handlers calling a remote web API that mediates the communication with the database, in Mark's case, handlers talk directly with the database. There is one less hop, less latency, and less I/O because, for example, there is no need to serialize and deserialize data flowing from web APIs to handlers.

## You might ask why am I using a different approach?

For a convenient reason. My code is for demos and samples purposes. Samples and demos are built to be auto-contained, easy to run, and scoped to one topic. They are mono-repo and based on a single Visual Studio solution. In such a scenario, I need to find a way to highlight service boundaries, and the easiest thing to do is build artificial physical ones. The client application is hosted separately from the composition gateway that hosts handlers. And the gateway lives in a different process than backend services that access data.

Reality is quite different, though. In a real-world distributed system, services codebases live in their repositories. They know little to nothing about each other. In many cases, one service can be multiple Visual Studio solutions, and developers may store code files in many source code repositories.

That is how developers view the architecture of the system. If that smells of ["4+1 Architectural View Model"](https://en.wikipedia.org/wiki/4%2B1_architectural_view_model), you're right. It's the Development View.

## Coupling

In his comment, Mark mentions that his choice comes with coupling as a downside:

> This has a "con" that couples those composition components to the data schema, meaning a change to schema results in a change not only to backend components that would naturally work directly with a data store but also the viewmodel components.

That's correct, and that's fine.

### "Whatcha talkin bout Mauro?"

All the pieces in my and Mark's architecture belong to the same logical service. Let's apply Mark's approach to the products use case mentioned above:

<div class="mermaid">
flowchart LR
  A[[Client]] --GET: product ABC page--> Gateway
  subgraph Gateway
    direction LR
    SPH[Sales price handler]
    MDH[Marketing description handler]
  end
  SPH --SELECT: ABC price--> SDB[(Sales prices)]
  MDH --SELECT: ABC description--> MDB[(Marketing descriptions)]
</div>

To understand why this approach is superior, even if it sounds more coupled, we have to be fully aware of the distinction between physical and logical architecture.

## Use cases

I bet that everyone reading this article bought goods or services from an online store at least once in their lives. You paid for your purchases through a credit card or another payment system like PayPal. In some online stores, we input the payment method every time. In others, we can store the payment details to reuse them later. When doing so, we can select one of the stored payment methods to complete the purchase process.

So far, we've identified at least three different requirements:

1. Users need to be able to pay for what they are buying
2. Users may want to store the payment method details 
3. At checkout, users need to be able to select a stored payment method

There are more that are not visible to users:

1. The system validates user-stored payment methods 
2. The system uses a fraud-detection algorithm to prevent fraud  
3. The system must store payment method details in a vault 

Do the presented requirements belong to different services? I bet not. They are all part of the Payments service (for lack of a better name). Logically, they are cohesive and, maybe in some cases, coupled too. That's not a problem because they are all owned by Payments. Remember, coupling implies that what changes together stays together.

There is some cohesiveness at play. Logically, Payments is a monolithic service that satisfies the presented requirements. For example, we need a fraud detection mechanism to allow users to pay. To store payment details, the vault is mandatory. However, in the realm of the physical, the vault and the fraud detection system don't need to know each other. They are not coupled.

In contrast, if payment details like credit card information are stored in a vault, a different set of information needs to be stored, allowing users to select a previously saved credit card at payment time without accessing the vault. This information is coupled: it needs to change simultaneously in the vault and this other part of the system.

To make it clear why coupling is at play here, let's dig a bit into the process of storing payment details. When we're presented with a screen to input payment details, for example, credit card information, there is an option to save the details for later usage. If the option is selected, the system will contact the payment gateway to process the payment and the vault to store the card details.

That's not enough. Next time we purchase, we cannot look in the vault to select previously-stored payment options. If the user interface accessed the vault, it poses a security risk. Usually, we are presented with a screen that displays something like "credit card ending with ...1234". That information doesn't come from the vault. It comes from a different part of the Payments service. This latter component is the one that reacted to the events published by the vault when the credit card details were stored. The component captured the payment method identifier, and the textual information later used to present the information to users.

## Logical vs. Physical

If we look at the presented scenario from the logical perspective, only a component allows storing and retrieving payment details. However, there is a vault to store data securely from a physical standpoint. A separate part keeps human-readable payment details information, and, finally, a composition handler responsible for retrieving those to present to users at payment time. And that doesn't take into account the user interface portion, which is another part of the logical component, or the web API accepting post and patch requests to add and update credit card information.

What is represented by a single component in the logical view becomes multiple components in the physical one. Some of them are coupled in nature. When users store credit card information in the vault, the system's portion that keeps the related human-readable data must be updated.

Given that "what changes together stays together" and that all the presented physical components belong to the same logical service, there is no point in adding a layer to mediate, for example, between composition handlers and the database. We don't need to protect composition handlers from changes happening in the database.

There are scenarios in which a mediation layer might be beneficial. That's not the point of this article, though. Mastering the distinction between the logical and the physical architecture allows understanding where logical boundaries require a mediation layer (ACL, Anti Corruption Layer, in Domain Driven Design terms).

## Conclusion

This article scratches the surface of the "4+1 architectural views". Instead, I preferred to focus on the distinction between logical and physical architecture, which I previously touched on in [You don't have to be cool to rule my world, KISS](https://milestone.topics.it/2019/05/08/dont-have-to-be-cool-to-rule-my-world.html). This exercise aims to reduce the overall complexity of the systems we develop and manage. Distributed systems already come with many moving parts, and there is no need to complicate things further where it is not needed.

---

Photo by <a href="https://unsplash.com/@szvmanski?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">pawel szvmanski</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
