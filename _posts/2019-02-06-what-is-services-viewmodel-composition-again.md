---
typora-root-url: ..
typora-copy-images-to: ../img/posts/what-is-services-viewmodel-composition-again

layout: post
header_image: /img/posts/what-is-services-viewmodel-composition-again/header.jpg
title: "What is Services ViewModel Composition, again?"
author: Mauro Servienti
synopsis: "Building distributed systems requires facing an interesting challenge: there is a dichotomy between the way behaviors and data are decomposed at the backend and the way users expect to consume them from the frontend. Services ViewModel Composition techniques are designed to help us overcoming this dichotomy."
tags:
- SOA
- Services ViewModel Composition
category: view-model-composition
redirect_from: /2019/02/06/what-is-services-viewmodel-composition-again.html
---
Building distributed systems requires facing an interesting challenge: there is a dichotomy between the way behaviors and data are decomposed at the backend and the way users expect to consume them from the frontend.

## Backend meanderings

When designing a distributed system backend it's usually decomposed into services, and data are segregated into services by ownership, or if you will by transactional boundaries: what changes together stays together.

For example, when designing a product from the backend perspective we need to deal with:

* name and description
* price
* availability
* shipping options

...and many more probably. The aforementioned concepts (data) have different owners, for example we could identify them as follows:

- *marketing* owns name and description
- *sales* owns price
- *warehouse* owns availability
- *shipping* owns shipping options

> don't focus too much on the business scenario, it's a trivial sample meant to give you an idea of the problem we have to face.

In a distributed system architecture data ownership means that those 4 concepts are segregated into 4 different services: marketing, sales, warehouse and shipping. Each service will have its own storage to store data they own.

## Please welcome the user

At this point we face an interesting challenge. Users expect to be able to look at a *Product*, not at name and description, price, availability, and shipping options. The user mental model defines products as an entity that has a clear meaning for them. However this doesn't really play well with the way data are divided at backend.

## Services ViewModel Composition

`ViewModel Composition` techniques are designed to solve the dichotomy. In the next set of articles we'll investigate different possible solutions, their pros and cons. Finally we'll understand what kind of relationship there is, if any, between `ViewModel Composition` and `UI Composition`.

Stay tuned!
