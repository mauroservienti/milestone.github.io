---
typora-copy-images-to: ..\img\posts\viewmodel-composition-show-me-the-code
typora-root-url: ..
layout: post
header_image: /img/posts/viewmodel-composition-show-me-the-code/header.jpg
title: "ViewModel Composition: show me the code!"
author: Mauro Servienti
synopsis: "Time was spent discussing ViewModel Composition concepts and their design. It's time for some code. Let's see Single Item Composition in action: how does the code look like?"
tags:
- SOA
- Services ViewModel Composition
---

The ViewModel Composition discovery journey is progressing nicely, so far we've discussed:

* What problem is Services ViewModel Composition designed to solve in [What is Services ViewModel Composition, again?](https://milestone.topics.it/2019/02/06/what-is-services-viewmodel-composition-again.html)
* How is Single Item Composition designed in [The Services ViewModel Composition maze](https://milestone.topics.it/2019/02/20/viewmodel-composition-maze.html)
* How is ViewModels Lists Composition designed in [Into the darkness of ViewModels Lists Composition](https://milestone.topics.it/2019/02/28/into-the-darkness-of-viewmodel-lists-composition.html)

## Show me the code!

It's probably the right time to start looking at some code, maybe still some theoretical and pseudo code, but at least something that explains how to put in practice what we've discovered so far.

> I'll be using .NET and C# as it is my field of expertise. All that I'm showing can be achieved using different languages and platforms.

Let's keep this simple by looking at *Single Item Composition* first. Pursuing the Product sample we used so far, we identified the following:

* Each product is identified by a unique `key`.
* Multiple services share the aforementioned key and use it to identify pieces of data that describe the Product from their point of view. As a recap we said:
  * *Marketing* owns name and description.
  * *Sales* owns price.
  * *Warehouse* owns availability.
  * *Shipping* owns shipping options.
* Whenever a Product is requested, each service needs to participate in the request handling and augment the returned product, the ViewModel, with its data.

If each service needs to be able to participate in the request handling process we could start by designing something like:

```csharp
interface IHandleRequests
{
    Task Handle(dynamic vm, RouteData routeData, HttpRequest request);
}
```

Whenever a request comes into the system it'll be handled by something we can call Composition Engine for now that creates an empty `ViewModel`, the `dynamic vm` argument above, and invokes all the implementers of the `IHandleRequests` interface.

> `IHandleRequests` implementations, given the current `RouteData` and the current `HttpRequest` need to make a decision first: am I interested in this specific request? Or put another way: is this for a Product or for something else?

We're probably assigning too many responsibilities to the `Handle` implementation so we can enhance the situation by changing the above interface as follows:

```csharp
interface IHandleRequests
{
    bool Matches(RouteData routeData, string httpVerb, HttpRequest request);
    Task Handle(dynamic vm, RouteData routeData, HttpRequest request);
}
```

The `Matches` method's responsibility is to determine if the current `HttpRequest` is of interest for a given request handler. Introducing the `Matches` method means that the mentioned Composition Engine has the following behavior:

* Handles an incoming request
* Iterates over all request handlers calling the `Matches` implementation
* If there is any handler interested in the current request
  * Creates and empty `ViewModel`
  * Calls all the interested handlers `Handle` implementations

Thinking about a Product, one possible implementation, eg. for *Marketing*, could be:

```csharp
class MarketingProductDetailsGetHandler : IHandleRequests
{
   public bool Matches(RouteData routeData, string httpVerb, HttpRequest request)
   {
      var controller = (string)routeData.Values["controller"];
      var action = (string)routeData.Values["action"];

      return HttpMethods.IsGet(httpVerb)
         && controller.ToLowerInvariant() == "products"
         && action.ToLowerInvariant() == "details"
         && routeData.Values.ContainsKey("id");
   }
}
```

The `MarketingProductDetailsGetHandler` `Matches` method inspects the current `HttpRequest` and based on its status determines if it is interested in handling it or not. In case it is interested it returns `true` and the Composition Engine will invoke the `Handle` method, that could look similar to:

```csharp
class MarketingProductDetailsGetHandler : IHandleRequests
{
   public bool Matches(RouteData routeData, string httpVerb, HttpRequest request)
   {
      /* omitted for clarity */
   }
   
   public async Task Handle(dynamic vm, RouteData routeData, HttpRequest request)
   {
      var id = (string)routeData.Values["id"];

      var url = $"http://marketing.backend.local/api/product-details/product/{id}";
      var response = await new HttpClient().GetAsync(url);

      dynamic details = await response.Content.AsExpando();

      vm.ProductName = details.Name;
      vm.ProductDescription = details.Description;
   }
}
```

At handling time the request handler loads data from its backend (in the above sample by forwarding an http request), but it could use whatever technique it wants. Once data are retrieved they are appended to the incoming ViewModel (`dynamic vm`).

At this point it's probably clear that if all the services interested in a specific type of request, e.g. a Product details, deploy their own implementation of the `IHandleRequests` interface they can all participate in the ViewModel composition process.

## Conclusion

The entire composition flow can be summarized as follows:

![composition engine information flow](/img/posts/viewmodel-composition-show-me-the-code/1551868103502.png){:class="img-fluid"}

The composition engine handles the incoming request:

1. Selects the interested handlers by invoking the `Matches` method.
2. Creates the empty ViewModel.
3. Invokes the `Handle` method of all the interested handlers.
4. Finally returns the composed ViewModel to the original caller

As we've already identified composing a list is more complex, we'll get to that in the next article. We've also introduced this new `Composition Engine` that will be analyzed in a dedicated post.
