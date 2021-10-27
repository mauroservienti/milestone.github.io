---
typora-copy-images-to: ..\img\posts\the-quest-for-better-search
typora-root-url: ..
layout: post
header_image: /img/posts/the-quest-for-better-search/header.jpg
title: "The Quest for better Search"
author: Mauro Servienti
synopsis: "There is search and then there is search. And despite having the same name their meaning, and thus their technical implications, is shaped by the business we are in. Let's have a look at what search in a distributed system is and what problems brings to the table."
tags:
- soa
- search
category: soa-search
redirect_from: /soa-search/2019/05/15/the-quest-for-a-better-search.html
---

As a developer if there is one thing I should blame Google for it's the distortion they inflicted on the search experience for users. When customer requirements list things like “Google-like search capabilities” my comment is generally along the lines of:

> Give me the Google budget, and you’ll have the Google search.

Last week I was on a call with my colleague [Tomek](https://twitter.com/Masternak) to discuss search capabilities in a distributed system. The very first distinction that we made was:

> You are Google, you are not Google.

Most of the times the “you are not Google” mantra is used to say that if you’re not at the scale of Google, something (technology or architecture choices) is not worth it. The comment is not about the scale but rather about the business domain. For example, Amazon is not Google in the sense that search is not at the center of their business.

How does this reflect in the architecture? In a service-oriented architecture (SOA):

> a Service is the technical authority for a specific business capability.

If searching is not a business capability, then it’s not a service in the SOA definition. Amazon, for example, lets you search only in product names and descriptions; it looks like a Google-like search, but it’s not. Search requests are routed to the Product Catalog service, and handled there.

## Hold on, folks! What about facets?

You’re right, this is not the entire story. Whenever a search is performed, two types of results are presented:

- A list of matching items/goods
- A set of facets, usually in the left sidebar, designed to narrow the results set.

![1557912046187](/img/posts/the-quest-for-better-search/1557912046187.png){:class="img-fluid mx-auto d-block"}

From the above screenshot it’s pretty clear that those faceted results are coming from different services, not only from Product Catalog.

There are even more complex scenarios when it comes to searches. Think about hotel reservation systems. Users need to search by location and availability (if not even more criteria) and then possibly narrow the results by stars, rating, or amenities like a fitness room, or a spa.

![1557912425551](/img/posts/the-quest-for-better-search/1557912425551.png){:class="img-fluid mx-auto d-block"}

In this scenario there are at least two services that participate in the search, let’s call them Hotel Catalog and Reservations. And then there are other services involved in the facets generation, for example Marketing to handle ratings, and again Hotel Catalog to handle amenities.

### How can we design something like that?

The simplest solution would be for all services involved in every type of supported search to:

- Deliver data to a common place, for example a SQL database or an Elasticsearch instance
- Have the search logic backed into the aforementioned storage

It works, and it’s doable, but it violates boundaries. Is it a problem? It’s up to you to decide, it’s the typical “it depends” consultant answer.

I’d say that in a small system, with a small team, with a low data change rate, and with near zero data schema evolution it’s not a problem at all. As I said: it works and brilliantly solves the problem.

However it’s a huge source of coupling. As soon as the system grows, or the team gets larger, or there is higher data or data schema change rate, the hodgepodge becomes a source of pain.

Multiple services, and thus teams, will find themselves fighting with each other to evolve document schema, to change query structure, to invalidate document sections, etc. All these will surface also as deployment and development constraints.

## Conclusion

In this article [Tomek](https://twitter.com/Masternak) and myself focused our attention on the high level problem that search in a distributed system brings to the table. This is just the beginning, obviously. There will be at least two more articles, one discussing the architecture of a distributed search, and another one showing a possible implementation using the Hotel Reservations scenario discussed above.
