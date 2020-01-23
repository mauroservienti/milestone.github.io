---
layout: post
header_image: /img/posts/so-you-want-to-talk-about-sorting-and-paging/header.jpg
title: "So you want to talk about sorting and paging"
author: Mauro Servienti
synopsis: ""
tags:
- SOA
- Services ViewModel Composition
category: view-model-composition
---
Paging and sorting sound like a controversial and complex topic when it comes to distributed systems; however, as not all that glitters is gold, not necessarily paging and sorting need to be complicated, even in distributed systems.

In the blog posts series about ViewModel Composition we used as a sample domain model a list of products composed by the following services:
marketing owns name and description
sales owns price
warehouse owns availability
shipping owns shipping options
When we faced for the first time [the darkness of ViewModels Lists Composition](/view-model-composition/2019/02/28/into-the-darkness-of-viewmodel-lists-composition.html), we said:

>"we could say that Marketing/Product Catalog is the one that makes decisions about the existence of a Product. Which means that from the business perspective, Marketing owns the concept of a Product."

In that article, we briefly identified what the process of composing a list is:
Marketing loads the products list that, in the simplest case, is only a list of IDs.
Marketing publishes an event to notify interested services that they can proceed with the composition process.

>Note: More details are available in [The ViewModels Lists Composition Dance](/view-model-composition/2019/03/21/the-viewmodels-lists-composition-dance.html) article.

## Paging
If Marketing is the logical owner of products and is also the one responsible for loading the products list, Marketing can easily be responsible for paging too.

When a request, such as `/products?pageIndex=0&pageSize=10`, comes in Marketing uses the paging information to restrict the number of IDs loaded, and if required, to calculate the total amount of pages.

All the other services receive, in the event raised by Marketing, an already paged list of products, making so that they do not need to be aware of any paging concern at all.

## Sorting
Sorting, unfortunately, it's not so easy as paging. Well, it depends.
For simple sorting scenarios, like the one in which we need to sort by a single property, the approach is straightforward.

When a request like `/products?orderBy=price` comes in what could happen is that:
Marketing behaves the usual way, loading product IDs and publishing the corresponding event.
All other services, but Sales, react as usual loading data by product ID and composing the products list.
Sales loads products' prices, and once its part of the composition is complete, it sorts the list by price. Sales is the one that can handle the `orderBy` query string parameter when the value is `price`.
If the request coming in is like `/products?orderBy=price,description` then sorting is not anymore so easy. The problem is that Sales can sort by price, Marketing can sort by description, but what the request is asking for is a different thing:

>I want products sorted by price and then by description.

Which, in essence, creates a kind of circular dependency between Sales and Marketing. Marketing must execute after Sales. Worse, it needs to know who already sorted data and how because of the "and then by" sort dependency. There is no way we can achieve this as Marketing, being the logical owner, is already executed first.

The trick is to have a post-composition step in the composition pipeline designed to post-process the composition result.

In the end, what we'd want to do is as simple as being able to do something like:
```csharp
var sortedProducts = composedProducts
        .OrderBy(p=>p.Price)
        .ThenBy(p=>p.Description);

return sortedProducts;
```
Can that LINQ expression be composed at runtime?
If ViewModel Composition engine was to expose a the post-composition step like the following:
```csharp
interface ICompositionPostProcessor
{
   Task<dynamic> PostProcess(dynamic viewModel, RouteData routeData, HttpRequest request);
}
```
We could inject an implementation like (pseudo code):
```csharp
class CompositionPostProcessor : ...
{
   public Task<dynamic> PostProcess(dynamic viewModel, ...)
   {
      var sortCriteria = request.Query["orderBy"].Split(',');

      //allSorters is IEnumerable<IApplySorting>, injected via DI
      var sorters = allSorters
            .Where(sorter=>sortCriteria.Any(criteria=>criteria==sorter.OrderBy))
            .OrderBy(sortCriteria);

      var sortedProducts = ((IEnumerable)viewModel).Cast<dynamic>()
      var isFirst = true;
      foreach(sorter in sorters)
      {
            sortedProducts = sorter.ApplySort(sortedProducts, isFirst);
            isFirst = false;
      }
      return Task.FromResult(sortedProducts)
   }
}
```
A "sorter" is a class that implements an interface like the following:
```csharp
interface IApplySorting
{
   string OrderBy{get;}
   IEnumerable<dynamic> ApplySort(IEnumerable<dynamic> data, bool executedFirst);
}
```
And Sales, for example, could have the `ApplySort` implementation as simple as:
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
The implementation uses in-memory LINQ to sort the composed list, and uses the `executedFirst` argument to determine how to apply the sorting.

## Conclusion



Header image: by [Kolar.io](https://unsplash.com/@jankolar?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/s/photos/sort?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)