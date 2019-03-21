---
typora-copy-images-to: ..\img\posts\the-viewmodels-lists-composition-dance
typora-root-url: ..
layout: post
header_image: /img/posts/the-viewmodels-lists-composition-dance/header.jpg
title: "The ViewModels Lists Composition dance"
author: Mauro Servienti
synopsis: "Composing a list in an efficient way is complex. Multiple components need to interact with each other to produce the final result. It's not that different from a chorus, where each dancer performs the studied choreography so that the end result is an amazing ballet."
tags:
- SOA
- Services ViewModel Composition
---

We've recently had a [look at some pseudo code showing how Single Item Composition could work](https://milestone.topics.it/2019/03/06/viewmodel-composition-show-me-the-code.html). At the end of that article the composition flow was summarized using the following diagram:

![composition engine information flow](https://milestone.topics.it/img/posts/viewmodel-composition-show-me-the-code/1551868103502.png){:class="img-responsive"}

The diagram is a bird-eye view of the composition flow, and misses details about lists composition whose [darkness we've already investigated](https://milestone.topics.it/2019/02/28/into-the-darkness-of-viewmodel-lists-composition.html).

## Let's dance

In the mentioned article, _Marketing_ is identified as the *Product* concept owner, and as such _Marketing_ is the one responsible to return the **list** of *Products*:

```csharp
class MarketingProductsListGetHandler : IHandleRequests
{
   public bool Matches(RouteData routeData, string httpVerb, HttpRequest request)
   {
      var controller = (string)routeData.Values["controller"];
      var action = (string)routeData.Values["action"];

      return HttpMethods.IsGet(httpVerb)
         && controller.ToLowerInvariant() == "products"
         && action.ToLowerInvariant() == "index"
         && !routeData.Values.ContainsKey("id");
   }
}
```

First things, first. The `MarketingProductsListGetHandler` is interested in all requests that are for the `products` controller and don't contain an `id`. In essence URLs like `/products`.

```csharp
class MarketingProductsListGetHandler : IHandleRequests
{
   public bool Matches(RouteData routeData, string httpVerb, HttpRequest request)
   {
      /* omitted for clarity */
   }
   
   public async Task Handle(dynamic vm, RouteData routeData, HttpRequest request)
   {
      var url = $"http://marketing.backend.local/api/available/products";
      var response = await new HttpClient().GetAsync(url);

      var availableProducts = await response.Content.As<int[]>();
   }
}
```

Whenever a matching request is intercepted, _Marketing_ retrieves the list of available products, in the above snippet just IDs are returned.

> As said _Marketing_ also owns names and descriptions, in which case in a real world scenario they would have been returned in the same response.

At this point all the other actors that want to take part in the composition process need to be notified:

```csharp
public class AvailableProductsLoaded
{
   public IDictionary<int, dynamic> AvailableProductsViewModel { get; set; }
}
```

_Marketing_, being the owner, defines the above `AvailableProductsLoaded` event, and raises it:

```csharp
class MarketingProductsListGetHandler : IHandleRequests
{
   /* Matches omitted for clarity */
   
   public async Task Handle(dynamic vm, RouteData routeData, HttpRequest request)
   {
      var url = $"http://marketing.backend.local/api/available/products";
      var response = await new HttpClient().GetAsync(url);

      var availableProducts = await response.Content.As<int[]>();
      
      var availableProductsViewModel = MapToDictionary(availableProducts);
      await vm.RaiseEvent(new AvailableProductsLoaded()
      {
         AvailableProductsViewModel = availableProductsViewModel
      });
      
      vm.AvailableProducts = availableProductsViewModel.Values.ToList();
   }
}
```

The first thing is to prepare a data structure suitable for event handlers that need to augment each _Product_. `MapToDictionary` is as simple as:

```csharp
IDictionary<int, dynamic> MapToDictionary(IEnumerable<int> availableProducts)
{
   var availableProductsViewModel = new Dictionary<int, dynamic>();

   foreach (var id in availableProducts)
   {
      dynamic vm = new ExpandoObject();
      vm.Id = id;

      availableProductsViewModel[id] = vm;
   }

   return availableProductsViewModel;
}
```

Once that's ready the `AvailableProductsLoaded` event is raised, and finally the composed ViewModels are appended to the response ViewModel (`vm`).

> The way the event is raised and dispatched to handlers is still obscure. As obscure is the whole composition infrastructure. Don't desperate there will be a dedicated article.

## False notes

The `IHandleRequests` interfaces is clearly insufficient. Semantically it's not designed to handle events.

```csharp
interface ISubscribeToCompositionEvents
{
   void Subscribe(ISubscriptionStorage subscriptionStorage, RouteData routeData, HttpRequest request);
    }
```

`ISubscribeToCompositionEvents` expresses the intent very well. Components implementing it are interested in subscribing to composition events. For example, _Sales_ could do something like:

```csharp
class AvailableProductsLoadedSubscriber : ISubscribeToCompositionEvents
{
   public void Subscribe(ISubscriptionStorage subscriptionStorage, RouteData routeData, HttpRequest request)
   {
      subscriptionStorage.Subscribe<AvailableProductsLoaded>(async (requestId, pageViewModel, @event, rd, req) =>
      {
         //whatever sales need to do
      });
   }
}
```

At runtime the composition infrastructure will invoke all components that implement the `ISubscribeToCompositionEvents` interface giving them the opportunity to subscribe to composition events. In e above snippet _Sales_ is subscribing to the `AvailableProductsLoaded` event that _Marketing_ raises whenever a list of available products is requested. When _Sales_ handles the event, additional products information are retrieved and composed into the list:

```csharp
public void Subscribe(ISubscriptionStorage subscriptionStorage, RouteData routeData, HttpRequest request)
{
   subscriptionStorage.Subscribe<AvailableProductsLoaded>(async (requestId, pageViewModel, @event, rd, req) =>
   {
      var ids = String.Join(",", @event.AvailableProductsViewModel.Keys);

      var url = $"http://localhost:5001/api/prices/products/{ids}";
      var response = await new HttpClient().GetAsync(url);

      dynamic[] productPrices = await response.Content.AsExpandoArray();

      foreach (dynamic productPrice in productPrices)
      {
         @event.AvailableProductsViewModel[(int)productPrice.Id].ProductPrice = productPrice.Price;
      }
   });
}
```

It's important to note that the event handler:

- has all the information to perform a single request to its back-end: in the above snippet _Sales_ gets all the IDs at once from the dictionary passed along with the event.
- once additional information are retrieved it iterates over the elements in the dictionary, matching by ID, and augment each element with its own information.

Other handlers do the exact same thing in parallel, and once they are all done the composed list is returned to the client.

## Conclusion

Composing a list in an efficient way is indeed much more complex. Complexity comes because we want to have full control over the number of back-end requests that each actor in the composition process issues. Specifically, requests number should not be greater than the number of services involved in the composition. Thanks to composition events we can notify composition handlers with enough information so that each one can perform a single request to its back-end.

Finally, another important thing, that deserves its own article: _Marketing_ doesn't know which services participate in the composition process. There is no such a thing as orchestration.

#### Articles in this series:

- [What is Services ViewModel Composition, again?](https://milestone.topics.it/2019/02/06/what-is-services-viewmodel-composition-again.html)”.
- [The Services ViewModel Composition maze](https://milestone.topics.it/2019/02/20/viewmodel-composition-maze.html)
- [Into the darkness of ViewModels Lists Composition](https://milestone.topics.it/2019/02/28/into-the-darkness-of-viewmodel-lists-composition.html)
- [ViewModel Composition: show me the code!](https://milestone.topics.it/2019/03/06/viewmodel-composition-show-me-the-code.html).
- [There is no such a thing as cross-service ViewModel Composition](https://milestone.topics.it/2019/03/13/there-is-no-such-a-thing-as-cross-services-composition.html)