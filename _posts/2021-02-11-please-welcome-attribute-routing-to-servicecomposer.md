---
layout: post
header_image: /img/posts/please-welcome-attribute-routing-to-servicecomposer/header.jpg
title: "Please welcome Attribute Routing to ServiceComposer"
author: Mauro Servienti
synopsis: "Attribute routing is a great MVC feature. However, endpoint routing is the game-changer. Library authors can plug in custom route handling and benefit from all the attribute routing goodies. It's easier than ever."
tags:
- soa
- viewmodel-composition
series: view-model-composition
---

With .NET Core 3, Microsoft introduced a long-waited feature in ASP.Net: Endpoint routing. Thanks to endpoint routing, it's finally possible to customize the target of an incoming HTTP request.

{% include link-to-service-composer.html %}

A bit of history might be helpful. In the .NET Framework version of ASP.NET, routing is part of MVC. That is, there is no way to use routing without using MVC. With the introduction of ".NET Core," Microsoft split routing into a separate `Microsoft.AspNetCore.Routing` package. The ability to use the routing feature in isolation was the thing that allowed [ServiceComposer](https://github.com/ServiceComposer) to see the light.

> What's ServiceComposer? ServiceComposer is a view model composition gateway designed to compose data owned by different (micro)services and transparently serve users' requests with a single response view model. More information about the overall architectural problem and the many nuances are available in the [ViewModel Composition series](https://milestone.topics.it/categories/view-model-composition) of articles on this blog.

With the ability to use routing standalone, we can now write something like:

```csharp
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddRouting();
    }

    public void Configure(IApplicationBuilder app, ILoggerFactory loggerFactory)
    {
        var routeBuilder = new RouteBuilder(app);
        routeBuilder.MapRoute("{controller}/{id:int?}", context =>
        {
            //handle the incoming HTTP Request here
            return Task.CompletedTask;
        });
        app.UseRouter(routeBuilder.Build());
    }
}
```

As you can see, it's pretty low-level stuff; you can barely use route templates and map those to callback functions. It was what ServiceComposer was doing under the hood. On top of that, in ServiceComposer, we built a higher-level API to abstract away some of the complexity.

## Problem: Lack of authentication and authorization support

Requests to support authentication and authorization came as no surprise (for example [here](https://github.com/ServiceComposer/ServiceComposer.AspNetCore.Mvc/issues/53) and [here](https://github.com/mauroservienti/designing-a-ui-for-microservices-demos/issues/2)). The problem was that to provide an authentication and authorization model; we'd have had to write it from scratch.

To handle a request and compose results using ServiceComposer, users need to define request composition handlers, something like the following:

```csharp
class SampleHandler : ICompostionRequestHandler
{
   public Task Handle(HttpRequest request)
   {
      //composition steps here.
   }
}
```

> A request composition handler is conceptually similar to an MVC Controller. The main difference is that in MVC, controllers are a one-to-one association with routes. One controller can serve only one route, and one route can have only one controller. In ServiceComposer, we can associate many request handlers with one route to allow a cooperative data composition.

To elegantly solve the authorization and authentication issue, it would have been great to allow the use of regular ASP.NET authentication and authorization attributes, e.g.:

```csharp
[Authorize]
public Task Handle(HttpRequest request)
{
}
```

The problem was that even if we were using the routing package, the request handling pipeline didn't invoke the authentication and authorization processing logic; it was still part of MVC only.

## Problem: Lack of decentralized routing configuration

Another concerning issue was the requirement to centralize the routing configuration during application startup or develop very complex and convoluted solutions to allow the configuration to be decentralized.
When designing a monolithic web application using ASP.NET MVC (or .NET Core for that matter), the fact that the routing configuration is centralized in a single place can become a maintenance problem in large applications. Every route is defined in the `Startup.cs` file, and if the application handles hundreds of routes, its management becomes a nightmare. Attribute routing was one of the options offered in later versions by Microsoft. With attribute routing, all the related route configurations were set where they made sense, on the controller itself. Moving routing information from a centralized place to controllers liberated developers from the possible maintenance nightmare.

ServiceComposer had a very similar problem exacerbated by a couple more things. In a Service-Oriented Architecture-based system, coupling is something that we need to handle with care. Orchestrators and coordinators are a coupling source, logical or physical, and a centralized configuration is a form of orchestration, especially in a composition gateway.

> More on "Orchestrators and coordinators are a source of coupling" in a future article.

As previously said, ServiceComposer allows autonomous services to participate in the data composition to respond to users' requests. ServiceComposer hosts the composition process and provides services facilities to implement composition support. ServiceComposer aims to be ignorant about the composition steps; if the composition gateway has some static knowledge of the composition steps, it's a barrier to the freedom of evolving. Any knowledge about the routing configuration is an evolution obstacle. Suppose services teams, each time they need to implement a change in their routing logic, have to adjust the ServiceComposer configuration. In that case, the configuration centralization is a bottleneck to remove.

Again, the attribute-based routing would have been a great addition as it would allow something like:

```csharp
[Authorize]
[HttpGet("products/details/{id}")]
public Task Handle(HttpRequest request)
{
}
```

Using attribute-based routing is a superior solution compared to cluttering the composition gateway startup code with routing configuration code.

## Endpoints, finally

At a high level, the difference is minimal. It seems just some cosmetic API tweaks; the API moved from being:

```csharp
public void Configure(IApplicationBuilder app, ILoggerFactory loggerFactory)
{
    var routeBuilder = new RouteBuilder(app);
    routeBuilder.MapRoute("{controller}/{id:int?}", context => { /* ... */ });
    app.UseRouter(routeBuilder.Build());
}
```

to:

```csharp
public void Configure(IApplicationBuilder app, ILoggerFactory loggerFactory)
{
    app.UseRouter();
    app.UseEndpoints( builder => builder.MapRoute("{controller}/{id:int?}", context => { /* ... */ }));
}
```

However, under the hood, the changes are substantial. Endpoints are a new concept to ASP.NET users. They are the target of a route, and in MVC, they represent the bridge between a route and a controller by default. Endpoints define "Route Metadata." For example, MVC stores in the metadata collection all the attributes applied to controllers and action methods. That means ServiceComposer can do the same; ServiceComposer can provide its Endpoint implementation that acts as a bridge between routes and multiple target composition handlers. At the same time, ServiceComposer can store into the Endpoint metadata collection attributes defined by developers onto composition handlers' Handle methods.

```csharp
[Authorize]
[HttpGet("products/details/{id}")]
public Task Handle(HttpRequest request)
{
}
```

The above code now works out of the box; at runtime, when ASP.NET builds endpoints, ServiceComposer provides all the endpoints grouping composition handlers by routes templates. Once handlers are grouped by template, the `Http*` attributes and all other relevant attributes are stored in the endpoint metadata collection for ASP.NET. At runtime, ASP.NET:

- handles incoming requests,
- matches them to route templates exposed by the registered endpoints.

Before invoking the endpoint handling logic, the runtime checks the metadata collection for well-known attributes such as the ones related to authentication and authorization, and if any notable attribute is present, ASP.NET invokes the related processing logic. In our case, applying the `Authorize` attribute produces the expected effect that ASP.NET executes the authorization pipeline.

## Conclusion 

Thanks to ASP.NET Endpoints, ServiceComposer now uses attribute-based routing by default and can leverage the authentication and authorization pipeline by merely applying the relevant attributes to composition handlers.

---

<span>Photo by <a href="https://unsplash.com/@sarahmutter?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Sarah Mutter</a> on <a href="https://unsplash.com/?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></span>
