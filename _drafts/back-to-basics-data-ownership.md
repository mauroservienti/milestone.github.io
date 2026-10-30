---
layout: post
title: "Back to Basics: who owns the data?"
author: Mauro Servienti
synopsis: "When you're involved with something for a very long time, it's easy to fall into the trap of taking many concepts for granted. Let's go back to the basics and build a common foundation. Today's topic is data ownership."
header_image: /img/posts/back-to-basics-data-ownership/header.jpg
tags:
- soa
- architecture
- back-to-basics
---

In ["What I'm sure of is that it's distributed last"](https://milestone.topics.it/2026/11/05/distributed-last.html), I wrote that each service owns its data. I wrote it as a bullet point, as if it were obvious.

It isn't.

"Owning data" is one of those expressions that everyone nods at and few people define. Does it mean the data lives in the service's database? That nobody else can see it? That nobody else can have a copy? Let's go back to the basics and try to answer.

> This article is the third in the Back to Basics series. The first two covered [service boundaries, autonomous components, and coupling](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html) and [commands, events, and messages](https://milestone.topics.it/2023/05/25/back-to-basics-messages.html).

## What does owning data mean?

Owning data isn't about where the data is stored. It's about authority.

The owner of a piece of data is:

- **The only one allowed to change it.** There is a single writer. Changes come from within the service boundary, for example, from the service's own part of the user interface sending a command to its back end. Other services can't change the data, and they can't command the owner to change it either. At most, they announce that something happened, and the owner decides what to do about it.
- **The authority on its meaning.** The owner decides what the data means, which values are valid, and which business rules apply to it.
- **The authority on its shape.** The owner decides how the data is stored and structured, and it can change that whenever it wants without asking anyone.

The last point is the one that hurts most when it's violated. If another service reads our tables, we can't rename a column without breaking it. The table structure became a contract, and nobody signed it.

## Who owns the product?

Let's look at an example. An online store sells products. The first, natural reaction is to model a `Product` entity like the following:

```csharp
class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public decimal Price { get; set; }
    public int QuantityInStock { get; set; }
    public decimal WeightInKg { get; set; }
}
```

Who owns the product? The honest answer is: nobody, and everybody.

- Marketing owns the name and the description.
- Sales owns the price.
- Inventory owns the quantity in stock.
- Shipping owns the weight, because it needs it to calculate shipping costs.

There is no product service. There are four services, each owning a slice of what users think of as a product. As I discussed in ["Do not trust the user mental model"](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html), the entity is a still image that users carry in their heads. It's not necessarily a good way to split responsibilities.

The only thing they all share is the identifier. Product 42 is product 42 for everyone. Identifiers are the glue that allows us to put the pieces back together when needed.

## Sharing data without sharing data

If each service owns only its slice, how does the system work as a whole? A product page needs the name, the description, the price, and the availability. A checkout needs the price and the weight.

There are a few options, and they're not born equal.

### Compose at the edges

When users need to see data owned by multiple services, the data is composed in the user interface or in a composition gateway. Each service provides its slice, and the page gets the whole picture. That's what [ViewModel Composition](https://milestone.topics.it/series/view-model-composition.html) is about. Services don't need to know about each other's data to display a product page.

### Share identifiers and facts, not state

Services communicate through messages. Commands stay within a service boundary, from the service's own components to its back end. Across boundaries, services publish events announcing that something happened. Ideally, events carry identifiers and facts, not the owner's internal state.

`OrderPlaced` with an order identifier is a fact. `ProductUpdated` with the whole product inside is a database replication mechanism dressed up as an event. As I wrote in ["Someone says event, and magically, coupling goes away"](https://milestone.topics.it/2024/02/16/events-magic.html), events don't remove coupling by themselves.

### What about copies?

Sometimes another service needs the data to make a decision. For example, Shipping wants to offer free shipping on orders above a certain amount. It needs the order total, which is Sales data.

The tempting solution is for Shipping to keep a copy of prices and calculate the total itself. Now there are two places that know how to calculate an order total, and they will disagree sooner or later. Discounts, coupons, and taxes are all Sales rules, and Shipping will reimplement them, poorly.

When a service needs another service's data to make a decision, it's worth asking whether the decision is in the right place. Who owns the "free shipping" policy? If it's a marketing promotion based on the order value, maybe Sales should decide whether an order qualifies and announce it, for example, with an event carrying a flag. Shipping only needs to know the outcome.

Copies aren't forbidden. A read-only copy of reference data that rarely changes, used for display purposes, is often fine. The problem starts when the copy is used to make decisions that belong to someone else.

Keep in mind, though, that a copy is a cache, and caches come with their own set of problems: invalidation, staleness, and, most importantly, ownership. Who owns the copy? Who decides when it's stale? I discussed it in ["Own the cache!"](https://milestone.topics.it/2021/07/15/own-the-cache.html).

## What about the database?

Owning data doesn't mean each service needs its own database server. Ownership is a logical concept. Physically, multiple services can store their data in the same database instance, for example, in separate schemas.

What matters is respecting the rules as if they were in separate databases:

- No queries joining tables owned by different services.
- No foreign keys across services.
- No transactions spanning data owned by different services.
- No service reading another service's tables "only for reading."

If those rules are respected, moving a service's data to its own database later is an operational task. If they aren't, it's a redesign.

> What about reporting and business intelligence? Reports often need data from many services, and that's a topic that deserves its own article.

## How do we know if we got it wrong?

A few smells to watch for:

- **Two services write to the same table or the same column.** There are two owners, which means there is none.
- **A `Common`, `Shared`, or `Core` service owns the main entities.** It usually ends up being the place where every change has to happen.
- **Changing a column requires a coordinated release of multiple services.** Someone is reading data they don't own.
- **Events carry the full state of an entity.** Subscribers are probably using it to make decisions that belong to the publisher.
- **A business rule is implemented in more than one place.** Data that should change together lives in different services.

## Conclusion

Data ownership is about authority, not storage. Each piece of data has exactly one owner, the only one allowed to change it and the one that decides what it means and how it's shaped. Everyone else gets identifiers, facts, and, at the edges, a composed view.

It sounds restrictive, and in a way, it is. It's also what allows services to evolve independently. Without clear ownership, service boundaries are fences with holes in them, and coupling walks right through.

---

Photo by <a href="https://unsplash.com/@purzlbaum?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Claudio Schwarz</a> on <a href="https://unsplash.com/photos/data-word-and-star-on-glass-fyeOxvYvIyY?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
