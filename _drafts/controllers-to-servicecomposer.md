---
layout: post
title: "From controllers to ServiceComposer, one route at a time"
author: Mauro Servienti
synopsis: "Contract-less composition handlers look like controller actions, which makes migrating an existing ASP.NET application to ViewModel Composition feasible. Let's migrate a controller step by step and look at the gotchas along the way."
header_image: /img/posts/controllers-to-servicecomposer/header.jpg
tags:
- viewmodel-composition
- soa
series: view-model-composition
---

When I introduced [contract-less composition handlers](https://milestone.topics.it/2025/04/23/contract-less-handlers.html), the driving principle was "feeling at home": composition handlers should look like ASP.NET controller actions. The most obvious benefit is a shorter learning curve. There's a less obvious one: if handlers look like controller actions, an existing application built with controllers can be migrated to ViewModel Composition one small step at a time.

A big-bang rewrite isn't required. Let's see what a step-by-step migration looks like, and what bites along the way.

{% include link-to-service-composer.html %}

## The starting point

Let's start with a classic. An online store with a `ProductsController`, backed by a single database with a single `Products` table:

```csharp
[ApiController]
public class ProductsController(ShopDbContext db) : ControllerBase
{
    [HttpGet("/products/{id}")]
    public async Task<IActionResult> Get(int id)
    {
        var product = await db.Products.FindAsync(id);
        if (product is null)
        {
            return NotFound();
        }

        return Ok(new ProductDetails(product.Id, product.Name, product.Description, product.Price));
    }

    [HttpPost("/products/{id}")]
    public async Task<IActionResult> Update(int id, UpdateProduct request)
    {
        var product = await db.Products.FindAsync(id);
        if (product is null)
        {
            return NotFound();
        }

        product.Name = request.Name;
        product.Description = request.Description;
        product.Price = request.Price;
        await db.SaveChangesAsync();

        return NoContent();
    }
}
```

The `Product` entity has a name and a description, owned by Marketing, and a price, owned by Sales. Nothing in the code says so. As I discussed in ["Back to Basics: who owns the data?"](https://milestone.topics.it/2026/11/09/back-to-basics-data-ownership.html), the product is a single entity only in the user's head.

The goal is to end up with a Sales composition handler and a Marketing composition handler, each dealing only with the data it owns, without breaking clients along the way.

## Step 1: host ServiceComposer next to controllers

ServiceComposer and controllers can live in the same ASP.NET application. Let's add ServiceComposer to the existing setup:

```csharp
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.DictionaryKeyPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });
builder.Services.AddHttpContextAccessor();
builder.Services.AddViewModelComposition(options =>
{
    options.ResponseSerialization.UseOutputFormatters = true;
});

var app = builder.Build();
app.MapControllers();
app.MapCompositionHandlers();
```

There are a few things worth discussing in the above snippet.

Contract-less handlers access the composed view model through the HTTP context, which requires the `IHttpContextAccessor` service to be registered, hence `AddHttpContextAccessor()`.

Handlers need a way to return a 404 or a 204, like the controller does. In ServiceComposer, that's done through [MVC action results](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/action-results.md), which require output formatters, hence `UseOutputFormatters = true`.

The `DictionaryKeyPolicy` bit is a gotcha that's easy to miss. By default, the composed view model is a dynamic object, and under the hood, a dynamic object is a dictionary. When output formatters are enabled, the MVC JSON formatter serializes it. It camel cases property names, but not dictionary keys. Without the setting, the controller returns `{"id":42,...}` and the composed endpoint returns `{"Id":42,...}`. Same data, different contract, broken clients.

> Without output formatters, ServiceComposer uses its own serialization, which [defaults to camel case](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/response-serialization-casing.md). The setting is needed only when output formatters are enabled.

One last thing: a route can't be served by a controller action and composition handlers at the same time. If both are mapped, ASP.NET fails the request with an `AmbiguousMatchException`. That's not a problem; it's the migration unit. We migrate one route at a time: the route moves from the controller to the handlers, and the controller action is removed.

## Step 2: move the action, as it is

The first move is boring on purpose. Let's move the controller actions to a single contract-less composition handler, changing as little as possible:

```csharp
[CompositionHandler]
class ProductDetailsHandler(ShopDbContext db, IHttpContextAccessor httpContextAccessor)
{
    [HttpGet("/products/{id}")]
    public async Task Get(int id)
    {
        var request = httpContextAccessor.HttpContext.Request;
        var product = await db.Products.FindAsync(id);
        if (product is null)
        {
            request.SetActionResult(new NotFoundResult());
            return;
        }

        var vm = request.GetComposedResponseModel();
        vm.Id = product.Id;
        vm.Name = product.Name;
        vm.Description = product.Description;
        vm.Price = product.Price;
    }

    [HttpPost("/products/{id}")]
    public async Task Update(int id, [FromBody] UpdateProduct body)
    {
        var request = httpContextAccessor.HttpContext.Request;
        var product = await db.Products.FindAsync(id);
        if (product is null)
        {
            request.SetActionResult(new NotFoundResult());
            return;
        }

        product.Name = body.Name;
        product.Description = body.Description;
        product.Price = body.Price;
        await db.SaveChangesAsync();

        request.SetActionResult(new NoContentResult());
    }
}
```

The differences are minimal. Instead of returning a `ProductDetails` instance, the handler writes to the composed view model. Instead of returning `NotFound()` or `NoContent()`, it sets an action result. Route, binding, and data access are the same.

Nothing is gained yet, architecturally speaking. What we gained is a safety net: the route is now served by ServiceComposer, and clients shouldn't notice. That's what we need to verify. A set of tests comparing the responses before and after the migration is the best tool for the job.

Comparing the responses reveals one difference. `[ApiController]` turns `NotFound()` into a [problem details](https://www.rfc-editor.org/info/rfc9457/) response body, while `NotFoundResult` returns an empty body. If clients rely on the problem details content, use an object result carrying a `ProblemDetails` instance instead.

## Step 3: split by ownership

Now comes the interesting part. Let's split the handler into two: Sales deals with the price, Marketing with the name and the description. Sales looks like the following:

```csharp
[CompositionHandler]
class SalesProductHandler(IServiceProvider serviceProvider, IHttpContextAccessor httpContextAccessor)
{
    [HttpGet("/products/{id}")]
    public async Task Get(int id)
    {
        await using var scope = serviceProvider.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<ShopDbContext>();

        var request = httpContextAccessor.HttpContext.Request;
        var price = await db.Products
            .Where(p => p.Id == id)
            .Select(p => new { p.Price })
            .SingleOrDefaultAsync();
        if (price is null)
        {
            request.SetActionResult(new NotFoundResult());
            return;
        }

        var vm = request.GetComposedResponseModel();
        vm.Id = id;
        vm.Price = price.Price;
    }
}
```

And Marketing looks like the following:

```csharp
[CompositionHandler]
class MarketingProductHandler(IServiceProvider serviceProvider, IHttpContextAccessor httpContextAccessor)
{
    [HttpGet("/products/{id}")]
    public async Task Get(int id)
    {
        await using var scope = serviceProvider.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<ShopDbContext>();

        var details = await db.Products
            .Where(p => p.Id == id)
            .Select(p => new { p.Name, p.Description })
            .SingleOrDefaultAsync();
        if (details is null)
        {
            return;
        }

        var vm = httpContextAccessor.HttpContext.Request.GetComposedResponseModel();
        vm.Name = details.Name;
        vm.Description = details.Description;
    }
}
```

There's a lot going on. Let's dissect it.

**Each handler reads only the columns it owns.** The table is still shared; we haven't touched the database. However, Sales queries only the price, and Marketing queries only the name and the description. The projections make ownership explicit in the code. Moving each service's data to its own table, or its own database, later becomes a change confined to one handler.

**Handlers run in parallel.** ServiceComposer invokes all the handlers matching a route concurrently. A scoped `DbContext` is shared within the HTTP request, and `DbContext` isn't thread-safe. Injecting it directly into both handlers is a recipe for intermittent concurrency exceptions. As described in the [ServiceComposer thread safety documentation](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/thread-safety.md), each handler creates its own child scope and resolves a private `DbContext` instance. Later, when each service has its own `DbContext` type, the problem goes away.

**One handler owns the status code.** Who decides that a product doesn't exist? If both handlers set a 404, it still works, since only the first action result is used. However, it's better to be explicit: in this example, Sales decides. Marketing doesn't fail when it finds nothing; it just doesn't contribute.

## Step 4: decomposition

The `POST` route follows the same approach. Each service binds only the part of the request body it owns, as I described in ["ServiceComposer: how do strongly-typed models affect composition and decomposition?"](https://milestone.topics.it/2026/10/28/servicecomposer-strongly-typed-models.html). Sales binds the price:

```csharp
[HttpPost("/products/{id}")]
public async Task Update(int id, [FromBody] SalesProductData data)
{
    await using var scope = serviceProvider.CreateAsyncScope();
    var db = scope.ServiceProvider.GetRequiredService<ShopDbContext>();

    var request = httpContextAccessor.HttpContext.Request;
    var product = await db.Products.FindAsync(id);
    if (product is null)
    {
        request.SetActionResult(new NotFoundResult());
        return;
    }

    product.Price = data.Price;
    await db.SaveChangesAsync();

    request.SetActionResult(new NoContentResult());
}
```

Marketing binds the name and the description:

```csharp
[HttpPost("/products/{id}")]
public async Task Update(int id, [FromBody] MarketingProductData data)
{
    await using var scope = serviceProvider.CreateAsyncScope();
    var db = scope.ServiceProvider.GetRequiredService<ShopDbContext>();

    var product = await db.Products.FindAsync(id);
    if (product is null)
    {
        return;
    }

    product.Name = data.Name;
    product.Description = data.Description;
    await db.SaveChangesAsync();
}
```

Did you spot the catch? The controller updated the name, the description, and the price in a single transaction. The two handlers save their changes independently. If Sales succeeds and Marketing fails, the price is updated, and the name isn't.

That's not a ServiceComposer problem. It's what happens every time data owned by different services is updated by the same request. The question to ask the business is whether the three values really need to change atomically. Most of the time, they don't: price and description changes are independent, and the user interface could even save them separately. When they do, it's often a sign that the boundary isn't where we thought it was. When the failure modes matter, the handlers can send messages instead of writing to the database directly. I discussed the options in ["Safety first!"](https://milestone.topics.it/2019/05/02/safety-first.html).

## What's next?

After step 4, the route is served by two handlers that only deal with their own data. Everything still runs in the same process, against the same database. And that's fine.

From here on, each service can evolve independently: moving its data to its own tables, moving its handlers to its own assembly, and, eventually, if there is a reason, moving its data behind its own API in a separate deployment. As I argued in ["What I'm sure of is that it's distributed last"](https://milestone.topics.it/2026/11/05/distributed-last.html), physical distribution is the last decision, not the first.

## Conclusion

Migrating from controllers to ViewModel Composition doesn't require a rewrite. The migration unit is a route. Move the action as it is, verify clients don't notice, then split the handler by ownership.

The tricky parts aren't the handlers themselves. They are the details around them: response casing, status codes, parallel execution, and transactions that used to span data owned by different services. The last one is the most valuable to discover, because it tells us something about the boundaries.

---

TODO: header image and credits
