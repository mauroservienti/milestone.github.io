---
layout: post
header_image: /img/posts/do-not-trust-the-user-mental-model/header.jpg
title: "Do not trust the user mental model: Model behaviors, not data"
author: Mauro Servienti
synopsis: ""
tags:
- Distributed Systems
- Behaviors modeling
- Data modeling
---

One of the critical aspects when designing a relational database is the data model. What is the data layout that the tables and schema structure are going to use? On the other hand, when modeling a No-SQL database, the focus is on the query model. What are the query patterns that the database needs to satisfy?

When designing systems, people talk a lot about the user mental model and how important it is to model the system following the user mental model. In my experience, this approach is very similar to the one used when modeling relational databases. Nonetheless, it works. However, it's not necessarily always the right choice.

When dealing with distributed systems, the effort should not be on data modeling but rather on behavior modeling. Like No-SQL databases, we are much more interested in how users interact with data, not in the data itself. 

## What does this even mean?

It's easier to look at the problems that a traditional data model-based design approach raises when used in the context of a distributed system.

> There are many cases in which a data model-based design works flawlessly. Don't get me wrong; I'm not implying that data model-based design approaches are a mistake. There is nothing wrong with building an application that uses something like "Active Record," whose foundations are within a data model-based design.

Let's use the well-known and sometimes abused e-commerce domain. In the e-commerce domain, there is the concept of Customers. Customers want to browse for Products to select what best suits their needs.

A data model-based design would quickly end up with the following entities:

```
entity Customer
{
   string Name;
   string Address;
}

entity Product
{
   string Name;
   string Description;
   decimal Price;
}
``` 

The resulting model is also relational database-friendly; it's simple to translate the model into tables. More importantly, it also seems to be well-aligned with the user mental model.

Human beings store information as "still images." It's easier to remember something stable and well-known, rather than continually changing and not easy to classify. With this in mind, let's dive into an exciting yet very simple use-case: Premium customers get a 5% discount on their purchases.

Given that we already have a model, the natural reaction is to fit the new requirement into the existing model:

```
entity Customer
{
   string Name;
   string Address;
   bool IsPremium;
}
```

Adding the attribute to the Customer entity sounds like an innocent and trivial change. At checkout time, the system will check if the customer is a premium one and apply the discount according to the rule.

## Please welcome Service Boundaries

Let's take the above-defined model and move it in the context of a distributed system. We'll probably end up saying that Customers belong to a different service than Products, for example:

- The Customer Relations service owns the Customer concept
- the Sales service owns the Product concept.

> Don't hang up too much on names. They are not the point of the article.

Assuming the above is correct, we immediately have a problem. To satisfy the new requirement, a hypothetical page showing products to our customers needs to query the Customer Relations service to gather the "IsPremium" attribute to determine the discount to apply to the displayed products' prices. The same applies if we move the discount calculation in the shopping cart or during the checkout phase.

Regardless of where the discount calculation happens, we need to couple it to the Customer Relations service.

## Reboot

First, let's remove the names we assigned to the entities and start using fantasy names, such as colors. This will help us remove any preconceived notion of the data model. And instead of calling them entities, let's use the word service since the intention is to identify a set of attributes that makes sense together in the context of an owner, the service.

```
service Yellow
{
   string CustomerName;
   string CustomerAddress;
   bool IsCustomerPremium;
}

service Green
{
   string ProductName;
   string ProductDescription;
   decimal ProductPrice;
}
``` 

At this point, what we can do is regroup attributes based on transactional boundaries. Another overloaded usage of the word transaction, sorry about that :-). The use case mentioned above and all the others we have in a real-world project are our guiding stars. Similarly to query patterns to satisfy when modeling No-SQL databases data structures, we can use behaviors described by requirements to group together attributes that interact and change together. They belong to the same transactional boundary.

In the model that we're describing, based on the behaviors we need to implement, it's clear that there is no relationship between the customer name and the fact that it is a premium customer or not. The same applies to products; the product description doesn't influence the product price, and neither the other way around is correct. Although the product price indeed depends on the fact that a customer is a premium customer. Based on this observation, we can rearrange our clusters of attributes in the following way:

```
service Yellow
{
   string CustomerName;
   string CustomerAddress;
}

service Green
{
   string ProductName;
   string ProductDescription;
}

service Red
{
   bool IsCustomerPremium;
   decimal ProductPrice;
}
```

For the sake of the discussion, let's reapply names based on the user mental model to the above clusters. Yellow is still a customer, and Green is always a product. It's hard for Red to find a meaningful name; it could be something like "product price based on customer status." It's not a very good entity or table name; this is because it represents the set of data required by the described behavior, which changes over time and depends on the context.

To make the point, we can try adding another requirement, a somewhat esoteric one. Customers get an additional 5% discount on their birthday.

It's the red service that needs the birthday date:

```
service Red
{
   Date CustomerBirthday;
   bool IsCustomerPremium;
   decimal ProductPrice;
}
```

We could go all-in and realize that to satisfy the requirement the birthday year is not necessary:

```
service Red
{
   int CustomerBirthdayDay;
   int CustomerBirthdayMonth;
   bool IsCustomerPremium;
   decimal ProductPrice;
}
```

We don't care how old they are; we need to know when it's their birthday.

## OK, cool. But I don't want a class named Red in my codebase

Here is the essence of the problem with the user mental model based on data and not behaviors. Users tend to describe the data before and after a behavior happens. Most of the time, the action that changes the data is in between the lines.

The "product price based on customer status" sentence describes a business transaction, and luckily businesses already have a name for such a thing. They are usually called policies; in the described scenario, we can call the Red entity the "Discount Policy." We have now identified three meaningful business concepts that are still using the business jargon but are not all data-bound:

- Customers (data, owned by service A)
- Products (data, owned by service B)
- Discount policies (behavior + data, held by service C)

So far, so good. We have correctly identified service boundaries. A question, at this point, could be: How do we display data to users now?
The original requirement stated:

> Customers want to browse for Products to select what best suits their needs.

It's indeed a legit question. Data are now scattered across multiple entities and need to be regrouped to provide a coherent view to users. I wrote a set of articles on the topic; they are available in the [ViewModel Composition series](https://milestone.topics.it/categories/view-model-composition).

## Conclusion

When designing a distributed system, at the very least, behaviors are first-class citizens like data. I'd even push myself to say that behaviors probably matter more than data in the service boundaries discovery process. One of the things we need to be aware of is that the user mental model can trick us into dead-ends. Be careful, listen to users and ask questions aimed at discovering behaviors and not only data.

---

<span>Photo by <a href="https://unsplash.com/@florianklauer?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Florian Klauer</a> on <a href="https://unsplash.com/?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></span>
