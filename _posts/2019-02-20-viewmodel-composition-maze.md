---
typora-copy-images-to: ..\img\posts\viewmodel-composition-maze
typora-root-url: ..
layout: post
header_image: /img/posts/viewmodel-composition-maze/header.jpg
title: "The Services ViewModel Composition maze"
author: Mauro Servienti
synopsis: "ViewModel Composition can be scary, at a first look. The real world, we deal with every day, is complex as the information we manage are complex. Do we need to manually craft dedicated solutions or can we extract reusable patterns? There is always an exit to the maze."
tags:
- SOA
- Services ViewModel Composition
category: view-model-composition
redirect_from: /2019/02/20/viewmodel-composition-maze.html
---

In [last instalment](/2019/02/06/what-is-services-viewmodel-composition-again.html) we had a first look at what ViewModel Composition is and what problem it is designed to solve. A product was used as a sample user mental model to show the dichotomy between its server side representation, in a distributed system, and its front-end representation when in need of showing information to users.

## Can be scary, at a first look

![a-product](/img/posts/viewmodel-composition-maze/a-product.jpg){:class="img-fluid"}

The product in the screenshot, if observed in [its original context](https://www.amazon.com/Benran-Outdoor-Travel-Protector-Storage/dp/B013QXJ3OQ/), is overwhelming. It's composed by a tremendous amount of information, coming for many different services. It's very easy to fall into the trap of concluding that ViewModel Composition should be manually crafted for every scenario as the complexity of the information we want to represent cannot be incapsulated into simpler patterns.

Luckily, the reality is different. ViewModel Composition can always be reconducted to 2 scenarios:

* Single Item Composition
* Lists Composition

The aforementioned product is a combination of the 2 mentioned scenarios. Single Item and Lists Composition can be combined to design whatever we need.

### Prerequisites

If data, required to build the ViewModel, are distributed across multiple services there is the need to correlate them in some way. It is not different to the problem we have when in need to compose data coming from different tables in a relational database. We need to be able to correlate data in some way: relational databases elegantly solve this problem by using the concept of shared keys. Data related to each other, but living in different tables, in some way share the same key.

> Databases further refine this concept by introducing, for example, foreign keys. Databases keys and strategies are outside the scope of this post.

Once there is a shared key, it can be used to issue a join request, still using the database metaphor.

Is there anything preventing us to apply the same concept to data owned by different services?

If, each service, other than storing its own data, also takes care of attaching a shared key to its own representation, we'll have a way to ask them to retrieve data connected to a specific key. That is not that different from the database join operation mentioned before.

This operation can be schematized like follows:

![a-composed-product](/img/posts/viewmodel-composition-maze/a-composed-product.jpg){:class="img-fluid"}

Given a key, `products/1`, we can now ask services to return data identified by the given key. All the retrieve operations can be run in parallel as the only shared, and required, piece of information is the key. Once all the data are on the client, whatever client means in this context, they can be composed as a ViewModel.

## Let's compose!

At this point there is nothing preventing us doing something as simple as merging data returned from different services to automatically generate the required ViewModel. In theory, if Marketing returns something like:

```
{
   key: 'products/1',
   name: 'Banana Protector',
   description: 'Benran Outdoor Travel Cute Banana Protector Storage Box (Pink, Green, Yellow, Pack of 3)'
}
```

And Sales something like:

```
{
   key: 'products/1',
   price: 7.99
}
```

We could blindly and transparently merge everything we have to a resulting ViewModel such as the following:

```
{
   key: 'products/1',
   name: 'Banana Protector',
   description: 'Benran Outdoor Travel Cute Banana Protector Storage Box (Pink, Green, Yellow, Pack of 3)',
   price: 7.99
}
```

We're still ignoring many nuances for sure, but this gives you a rough idea of what Single Item Composition is. Lists Composition is not so simple, but it's not that complex either. A good topic for the next article.

## Conclusions

At a first look it seems that ViewModel Composition needs to be manually and carefully crafted to solve every single scenario by using a dedicated solution. As we've seen we can reconduct all the composition scenarios to 2 main patterns: Single Item and Lists Composition. In this post we had a first look at the mechanics of Single Item Composition. Next one will dive into Lists Composition scenarios. Say tuned.
