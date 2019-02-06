---
typora-root-url: ..
typora-copy-images-to: ../img/posts/what-is-services-viewmodel-composition-again

layout: post
header_image: /img/posts/what-is-services-viewmodel-composition-again/header.jpg
title: "What is Services ViewModel Composition, again?"
author: Mauro Servienti
synopsis: "Building distributed systems requires facing an interesting challenge: there is a dichotomy between the way behaviors and data are decomposed at the backend and the way users expect to consume them using a frontend application. Services ViewModel Composition techniques ae designed to help us overocming this dichotomy."
tags:
- SOA
- Services ViewModel Composition
---
Building distributed systems requires facing an interesting challenge: there is a dichotomy between the way behaviors and data are decomposed at the backend and the way users expect to consume them using a frontend application.

For example, when designing a product from the backend perspective we need to deal with:

* name and description
* price
* availability
* shipping options

...and many more probably. The aforementioned concept (data) have different owners, for example we could identify them as follows:

- marketing owns name and description
- sales owns price
- warehouse owns availability
- shipping owns shipping options

In a distributed system architecture this means that those 4 concepts are fully owned by 4 different services, marketing, sales, warehouse and shipping.

## Please welcome the user

