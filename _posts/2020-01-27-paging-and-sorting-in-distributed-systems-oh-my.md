---
layout: post
header_image: /img/posts/paging-and-sorting-in-distributed-systems-oh-my/header.jpg
title: "Paging and sorting in distributed systems, oh my!"
author: Mauro Servienti
synopsis: "Paging and sorting sound like a controversial and complex topic when it comes to displaying data; however, they don't need to be, even in distributed systems."
tags:
- soa
- viewmodel-composition
category: view-model-composition
---
Paging and sorting sound like a controversial and complex topic when it comes to displaying data; however, they don't need to be, even in distributed systems.

In the [blog posts series about ViewModel Composition](/categories/view-model-composition) we used as a sample domain model a list of products composed by the following services:

* *Marketing* owns name and description
* *Sales* owns price
* *Warehouse* owns availability
* *Shipping* owns shipping options

When we faced for the first time [the darkness of ViewModels Lists Composition](/view-model-composition/2019/02/28/into-the-darkness-of-viewmodel-lists-composition.html), we said:

>"we could say that *Marketing/Product Catalog* is the one that makes decisions about the existence of a Product. Which means that from the business perspective, *Marketing* owns the concept of a Product."

In that article, we briefly identified what the process of composing a list is:

* *Marketing* loads the products list that, in the simplest case, is only a list of IDs.
* *Marketing* publishes an event to notify interested services that they can proceed with the composition process.

>Note: More details about the entire composition process are available in [The ViewModels Lists Composition Dance](/view-model-composition/2019/03/21/the-viewmodels-lists-composition-dance.html) article.

## Paging
If *Marketing* is the logical owner of products and is also the one responsible for loading the product list, *Marketing* can easily be responsible for paging too.

When a request, such as `/products?pageIndex=0&pageSize=10`, comes in, *Marketing* uses the paging information to restrict the number of IDs loaded, and if required, to calculate the total amount of pages.

In the event raised by *Marketing*, all the other services receive an already-paged/trimmed list of products. In other words, they do not need to be aware of any paging concern at all.

## Sorting
Sorting, unfortunately, it's not as easy as paging. For simple sorting scenarios, like the one in which we need to sort by a single property, the approach might be straightforward. Might be.

When a request like `/products?orderBy=price` comes in what could happen is that:

* *Marketing* behaves the usual way, loading product IDs and publishing the corresponding event.
* All other services but *Sales* react as usual, loading data by product ID and composing the product list.
* *Sales* loads products' prices, and once its part of the composition is complete, it sorts the list by price. *Sales* is the one that can handle the `orderBy` query string parameter when the value is `price`.

Unfortunately, such a simple approach immediately fails if services are invoked in parallel, like in our case. A service cannot directly change the order of something that is simultaneously touched by other services.

If the request coming in is like `/products?orderBy=price,description` then sorting is not so easy, even if we were allowed to sort the list directly. The problem in this second scenario is that *Sales* can sort by price, *Marketing* can sort by description, but what the request is asking for is different:

>I want products sorted by price and then by description.

In essence, this creates a kind of circular dependency between *Sales* and *Marketing*. *Marketing* must execute after *Sales*. Worse, it needs to know who already sorted data and how because of the "and then by" sort dependency. There is no way we can achieve this as the *Marketing* endpoint, being the logical owner, has already executed.

The trick is to have a post-composition step in the composition pipeline designed to post-process the composition result.

In the end, what we want to do is as simple as:

```csharp
var sortedProducts = composedProducts
        .OrderBy(p=>p.Price)
        .ThenBy(p=>p.Description);

return sortedProducts;
```

## Can that LINQ expression be composed at runtime?

If the ViewModel Composition engine was to expose a post-composition step like the following:

```csharp
interface ICompositionPostProcessor
{
   Task<dynamic> PostProcess(dynamic viewModel, HttpRequest request, ...);
}
```

We could inject an implementation like (pseudo-code):

```csharp
class CompositionPostProcessor : ...
{
   public Task<dynamic> PostProcess(dynamic viewModel, ...)
   {
      var sortedProducts = ((IEnumerable)viewModel).Cast<dynamic>();
      var sortCriteria = request.Query["orderBy"].Split(',');
      var isFirst = true;
      foreach(sortCriterion in sortCriteria)
      {
         //allSorters is IDictionary<string, IApplySorting>, e.g. injected via DI
         if(allSorters.TryGetValue(sortCriterion, out IApplySorting sorter))
         {
            sortedProducts = sorter.ApplySort(sortedProducts, isFirst);
            isFirst = false;
         }
      }

      return Task.FromResult(sortedProducts)
   }
}
```

A `sorter` is a class that implements an interface similar to the following:

```csharp
interface IApplySorting
{
   string OrderByCriterion{get;}
   IEnumerable<dynamic> ApplySort(IEnumerable<dynamic> data, bool executedFirst);
}
```

And *Sales*, for example, could have the `ApplySort` implementation as follows:

```csharp
IEnumerable<dynamic> ApplySort(IEnumerable<dynamic> data, bool executedFirst)
{
   if(executedFirst)
   {
      return data.OrderBy(item=>item.Price);
   }
   return data.ThenBy(item=>item.Price)
}
```

> The pseudo-code implementation uses in-memory LINQ to sort the composed list and uses the `executedFirst` argument to determine how to apply the sorting.

## Conclusion

The composition process and the composition engine [are transparent to the way data are composed](/view-model-composition/2019/04/09/slice-it.html), so they have to be the way paging and sorting affect the composed data.

As we've seen, it's easy to implement paging by looking for the logical owner of the incoming request.

With sorting, things are not so easy. However, if the composition engine exposes the ability to plug-in a post-composition processor, there is an opportunity to design a sorting mechanism that preserves the services' isolation and autonomy, and also is entirely transparent to the engine itself.

---

Header image: by [Kolar.io](https://unsplash.com/@jankolar?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/s/photos/sort?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
