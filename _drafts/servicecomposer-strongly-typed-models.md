---
layout: post
title: "ServiceComposer: how do strongly-typed models affect composition and decomposition?"
author: Mauro Servienti
synopsis: "Strongly typed models make the compiler our friend, but in ViewModel Composition, they can quietly reintroduce the coupling we worked hard to remove. Let's see how to get type safety on both sides of the HTTP request without giving up autonomy."
header_image: /img/posts/servicecomposer-strongly-typed-models/header.jpg
tags:
- soa
- viewmodel-composition
series: view-model-composition
---

When dealing with HTTP requests and responses, we usually deal with two different models: the request and the response models. The request model represents the incoming data; it could be the HTTP Post request body, the incoming form collection, a set of query string elements, elements from the matching route, request headers, or a combination.

On the other hand, the response is what the web server sends back to the client: a status code, a set of response headers, and the response model. The response model could be empty when there is no response data, and the status code and headers suffice, or it could be rich, ranging from simple data types, such as a string or a number, to complex structures, such as a JSON response.

ServiceComposer is no different; it deals with request and response models. However, when dealing with distributed systems and [ViewModel Composition](https://milestone.topics.it/series/view-model-composition.html), we pay a lot of attention to the effect of [coupling](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html) and how it can negatively impact the system maintainability over time.

Most concerns arise when we want to start using strongly typed view models. Why is that?

## Response models

Let's look at an example. In ServiceComposer, we can define two [contract-less composition handlers](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/contract-less-composition-requests-handlers.md) like the following:

```csharp
[CompositionHandler]
class SalesProductInfo(IHttpContextAccessor httpContextAccessor)
{
    [HttpGet("/product/{id}")]
    public Task GetProductInfo(string id)
    {
        dynamic vm = httpContextAccessor.HttpContext.Request.GetComposedResponseModel();

        vm.ProductId = id;
        vm.ProductPrice = 100;

        return Task.CompletedTask;
    }
}
```

And another one like:

```csharp
[CompositionHandler]
class MarketingProductInfo(IHttpContextAccessor httpContextAccessor)
{
    [HttpGet("/product/{id}")]
    public Task GetProductInfo()
    {
        dynamic vm = httpContextAccessor.HttpContext.Request.GetComposedResponseModel();

        vm.ProductName = "Sample product";
        vm.ProductDescription = "This is a sample product";

        return Task.CompletedTask;
    }
}
```

> Contract-less composition handlers receive route values, query string parameters, and body payloads as method arguments. To access the composed response model, they rely on the `IHttpContextAccessor` service, which must be registered at startup using `services.AddHttpContextAccessor()`.

Both handlers compose data for the same route, `/product/{id}`; as you can see from the presented snippets, they share the same model. The model is a C# dynamic object, and each request handler appends its properties.

Using a dynamic object causes no coupling between the two handlers. However, it comes with the downside of dynamic typing: handlers could be using the same property name, and a rigorous development process needs to be implemented to mitigate that.

ServiceComposer supports strongly typed composed response models. Let's imagine we wanted to use a composed response model like the following:

```csharp
public class ProductViewModel
{
    public string ProductId { get; set; }
    public decimal ProductPrice { get; set; }
    public string ProductName { get; set; }
    public string ProductDescription { get; set; }
}
```

To set that up, we first need to plug in a [view model factory](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/view-model-factory.md):

```csharp
class ProductViewModelFactory : IEndpointScopedViewModelFactory
{
    [HttpGet("/product/{id}")]
    public object CreateViewModel(HttpContext httpContext, ICompositionContext compositionContext)
    {
        var productId = httpContext.GetRouteValue("id").ToString();
        return new ProductViewModel()
        {
            ProductId = productId
        };
    }
}
```

ServiceComposer will invoke the view model factory before invoking the presented handlers. The factory creates the strongly typed view model instance. At this point, we can update the handlers to use the strongly typed model as follows:

```csharp
[CompositionHandler]
class MarketingProductInfo(IHttpContextAccessor httpContextAccessor)
{
    [HttpGet("/product/{id}")]
    public Task GetProductInfo()
    {
        var vm = httpContextAccessor.HttpContext.Request.GetComposedResponseModel<ProductViewModel>();

        vm.ProductName = "Sample product";
        vm.ProductDescription = "This is a sample product";

        return Task.CompletedTask;
    }
}
```

Handlers can use the `GetComposedResponseModel<TModel>()` generic version to retrieve the `ProductViewModel` instance.

We are now in a position where the compiler protects us, but there is coupling at play. Each handler can now access all properties of the response model, regardless of whether they own it.

## What's wrong with that?

At first glance, not much. The code compiles, the response is correct, and IntelliSense is happy. Let's look at it from a different angle, though.

`ProductViewModel` must live somewhere. Both the Sales and the Marketing handlers reference it, so it needs to be in an assembly that both depend on. What we have created is a shared kernel: a piece of code owned by nobody and used by everybody.

That has a few consequences:

- **Data ownership is no longer enforced.** Nothing prevents the Marketing handler from writing `vm.ProductPrice = 0`. Price is Sales data, but the model makes it accessible to anyone who handles the route. With the dynamic model, it was equally possible, but at least nobody had a typed property to stumble upon.
- **Changes ripple.** Sales wants to add a `ProductDiscount` property. To do that, it needs to change the shared assembly, which means rebuilding and redeploying everything that references it, Marketing included. Marketing didn't change anything, yet it's involved in the release.
- **The model tends to grow.** Shared models attract properties. Over time, `ProductViewModel` becomes the place where every service adds whatever it needs, and it slowly turns into the entity-shaped object that service boundaries were designed to avoid.

In short, we traded a runtime risk, property name collisions, for a design-time risk: coupling. The question is whether we can have type safety without paying that price.

## Segregating the response model

`GetComposedResponseModel<T>()` doesn't require `T` to be the exact type the view model factory created. It requires that the view model instance *is* a `T`. That small detail opens an interesting door: interfaces.

Each service can define the subset of the view model it owns. Sales defines its interface in its own assembly:

```csharp
namespace Sales.ViewModelComposition
{
    public interface ISalesProductViewModel
    {
        decimal ProductPrice { get; set; }
    }
}
```

And Marketing does the same in its own assembly:

```csharp
namespace Marketing.ViewModelComposition
{
    public interface IMarketingProductViewModel
    {
        string ProductName { get; set; }
        string ProductDescription { get; set; }
    }
}
```

Handlers ask for the interface they own, not for the concrete view model:

```csharp
[CompositionHandler]
class MarketingProductInfo(IHttpContextAccessor httpContextAccessor)
{
    [HttpGet("/product/{id}")]
    public Task GetProductInfo()
    {
        var vm = httpContextAccessor.HttpContext.Request.GetComposedResponseModel<IMarketingProductViewModel>();

        vm.ProductName = "Sample product";
        vm.ProductDescription = "This is a sample product";

        return Task.CompletedTask;
    }
}
```

The Marketing handler can no longer see, let alone change, the product price. The compiler still protects us, but this time it protects service boundaries too.

Finally, the concrete view model implements all the interfaces:

```csharp
internal class ProductViewModel : ISalesProductViewModel, IMarketingProductViewModel
{
    public string ProductId { get; set; }
    public decimal ProductPrice { get; set; }
    public string ProductName { get; set; }
    public string ProductDescription { get; set; }
}
```

The view model factory doesn't change; it still creates a `ProductViewModel` instance. When the response is serialized, the serializer sees the concrete type, and the client gets all the properties.

Since handlers only depend on the interfaces, nobody outside the assembly that defines the concrete view model needs to know about it. `ProductViewModel` can now be `internal`.

### Where does the coupling go?

Coupling didn't disappear. It moved. The concrete `ProductViewModel` and its factory must reference the Sales and the Marketing assemblies. However, there's a significant difference: the coupling is now in a single place, and it points in the right direction. Services don't depend on each other or on a shared model; the component hosting the composition depends on the services.

That's a responsibility the composition host already has. It's the component that knows which services contribute to which route, and the response model is, in the end, the contract with the client. Someone has to own that contract, and the composition host is a natural candidate. When Sales adds `ProductDiscount`, it changes its interface, and the composition host updates the concrete model. Marketing isn't involved.

That doesn't mean changes come for free. When Marketing needs an additional property, it adds it to its interface, and the concrete view model must be updated to implement it. The two changes must ship together: deploying the new Marketing assembly with the old composition host results in a type load failure at runtime, since `ProductViewModel` no longer implements all the members of `IMarketingProductViewModel`. A process is still needed to coordinate changes to the internal view model. However, the coordination is always between a single service and the composition host, never between services. Sales doesn't need to be recompiled or redeployed; it doesn't even know Marketing changed anything.

### A caveat about property names

Interfaces don't fully solve the property name collision problem. If Sales and Marketing both declare a `string Name { get; set; }` property in their interfaces, the concrete class will happily implement both with a single property. The compiler won't complain, and the two services will silently overwrite each other's data. It only happens when the two properties also share the same type, though. If Sales declared `string Name` and Marketing declared `int Name`, the concrete class couldn't expose both as public properties, and we'd be forced to implement at least one of them explicitly.

Explicit interface implementations would make the collision visible, but they come with a different problem: serializers like `System.Text.Json` only serialize public properties of the concrete type, so explicitly implemented properties won't make it to the response.

The pragmatic mitigation is a naming convention, for example, prefixing properties or grouping each service's data under a dedicated property, such as `Sales` and `Marketing`. The concrete class is in one place, though, so reviewing it is much easier than chasing property names across dynamic objects scattered in many handlers.

## Request models

So far, we looked at composition. What about decomposition? When a client sends data to the composition gateway, the incoming request must be [dismantled](https://milestone.topics.it/2019/04/18/the-fine-art-of-dismantling.html), and each service must get the data it owns.

Let's imagine an endpoint that allows updating a product:

```http
POST /product/42
Content-Type: application/json

{
    "price": 120,
    "name": "Sample product",
    "description": "This is an updated sample product"
}
```

The temptation is to repeat the response model approach and define a strongly typed request model that mirrors the whole payload:

```csharp
public class UpdateProductRequest
{
    public decimal Price { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
}
```

The same issues apply: a shared model, a shared assembly, and every service able to read data it doesn't own. A reading handler is less dangerous than a writing one, but the Marketing handler should have no reason to know there is a price in the request. If it can read it, sooner or later, it will use it.

The good news is that request models are easier to handle than response models. ServiceComposer [model binding](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/model-binding.md) relies on the ASP.NET model binding infrastructure, which ignores incoming properties that don't match the target model. And ServiceComposer buffers the incoming request body, so every handler can bind it independently.

That means each service can define its own request model, with only the properties it owns, in its own assembly. With contract-less composition handlers, the body is bound to a method argument. Sales binds the price:

```csharp
class SalesProductData
{
    public decimal Price { get; set; }
}

[CompositionHandler]
class SalesUpdateProduct
{
    [HttpPost("/product/{id}")]
    public Task UpdateProduct(int id, [FromBody] SalesProductData data)
    {
        // store data.Price for product id
        return Task.CompletedTask;
    }
}
```

Marketing binds the name and the description:

```csharp
class MarketingProductData
{
    public string Name { get; set; }
    public string Description { get; set; }
}

[CompositionHandler]
class MarketingUpdateProduct
{
    [HttpPost("/product/{id}")]
    public Task UpdateProduct(int id, [FromBody] MarketingProductData data)
    {
        // store data.Name and data.Description for product id
        return Task.CompletedTask;
    }
}
```

The request models are private to each service; they can even be `internal`. There is no shared assembly, no composition host involvement, and each service is free to evolve its own model. The compiler protects us, and the services remain autonomous. Decomposition gets type safety for free.

## Conclusion

Strongly typed models are not the enemy of ViewModel Composition. Shared strongly typed models are.

On the request side, each service binds its own private model and gets type safety without coupling. On the response side, someone needs to own the shape of the response. Segregating the view model through service-owned interfaces keeps each service focused on the data it owns, and concentrates the unavoidable coupling in the composition host, where it belongs.

If the trade-off isn't worth it for a given route, dynamic view models are still there, and they're still a perfectly valid choice.

---

Photo by <a href="https://unsplash.com/@edge2edgemedia?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Edge2Edge Media</a> on <a href="https://unsplash.com/photos/grey-metal-chain-on-white-background-t1OalCBUYRc?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
