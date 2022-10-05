---

typora-copy-images-to: ..\img\posts\turn-on-the-motors
typora-root-url: ..
layout: post
header_image: /img/posts/turn-on-the-motors/header.jpg
title: "Turn on the motors"
author: Mauro Servienti
synopsis: "It's time to discover all the nitty gritty details of the Composition Gateway. It's going to be a roller-coaster ride from ASP.Net Core Routing to the composition engine and back. Fasten your seat belt and enjoy the ride!"
tags:
- soa
- viewmodel-composition
series: view-model-composition
---

We spent the last seven posts introducing ViewModel Composition and diving into many aspects of it. A detailed list of articles can be found in the [ViewModel Composition](https://milestone.topics.it/categories/view-model-composition.html) category.

In a few occasions I mentioned either `the infrastructure` or `the engine` and always said: "there will be a post about it". Time has come.

{% include link-to-service-composer.html %}

## Composition Gateway

To make sure that data can be aggregated we need to make clients interact with a third party and not directly with endpoints owned by services. Still using our services sample clients don't directly talk to *Marketing*, *Sales*, *Warehouse*, and *Shipping*. They connect to a service that sits between them and business services to run the composition logic.

>  This has also the nice side effect of masquerading the internal services topology. It solves spatial coupling issues.

This service behaves like a reverse proxy:

- receives incoming requests
- puts them on hold
- invokes request handlers
- returns the composed view model responding to the incoming requests

### Please welcome ASP.Net Core

ASP.Net Core is a real work of art, the tiny thing I probably love the most is that `Routing` is not anymore part of `Mvc`. In ASP.Net the routing engine is double linked to `Mvc` and has near to zero extension options. In ASP.Net Core `Routing` is a separate component/package from `Mvc` and can be used in isolation in an ASP.Net Core application that doesn't use `Mvc`.

Given the premise the following is all what is needed to run a sample *Composition Gateway*:

```csharp
public class Startup
{
	public void ConfigureServices(IServiceCollection services)
	{
		services.AddRouting();
		services.AddViewModelComposition();
	}

	public void Configure(IApplicationBuilder app, ILoggerFactory loggerFactory)
	{
		app.RunCompositionGatewayWithDefaultRoutes();
	}
}
```

The above `startup` "simply" does 3 things:

1. Adds `Routing` to the services that will be run by the ASP.Net Core application
2. Through calling `AddViewModelComposition`:
   1. Scans all assemblies in the `bin` directory looking for types that implement either the `IHandleRequests` interface or the `ISubscribeToCompositionEvents` one
   2. Registers all types matching the above "query" in the current IoC/DI container
3. Runs the Composition Gateway as an ASP.Net Core pipeline terminator in `RunCompositionGatewayWithDefaultRoutes`

> I know it doesn't really appear simple, have faith. It's not really complex either.

#### HTTP Requests handling

ASP.Net Core handles HTTP requests through a pipeline, "elements" in the handling pipeline are called middleware. Middleware can be passthrough, when they intercept the request and then pass it to the next middleware in the pipeline; or they can be terminators as they will terminate the incoming request handling and are responsible to start the response.

> Basically there can be only 1 terminator in a pipeline. For example in in `Mvc` we could consider `Controllers` to be terminators. It's not that simple, but you probably get the point.
>
> More on ASP.Net Core pipeline and middleware in <https://docs.microsoft.com/en-us/aspnet/core/fundamentals/middleware/>

The Composition Gateway acts like a terminator, it sits at the end of the pipeline. `RunCompositionGatewayWithDefaultRoutes` is defined as follows:

```csharp
public static void RunCompositionGatewayWithDefaultRoutes(this IApplicationBuilder app)
{
    app.RunCompositionGateway(routes =>
    {
	routes.MapComposableGet( template: "{controller}/{id:int?}");
        routes.MapRoute("{*NotFound}", context =>
        {
            context.Response.StatusCode = StatusCodes.Status404NotFound;
            return Task.CompletedTask;
        });
    });
}
```

What it does is:

- defines a default route using as template `{controller}/{id:int?}`
- defines a *catch-all* route to return a `404` to clients hitting invalid routes

It's a shortcut to:

```csharp
public static void RunCompositionGateway(this IApplicationBuilder app, Action<IRouteBuilder> routes = null)
{
    var routeBuilder = new RouteBuilder(app);
    routes?.Invoke(routeBuilder);

    app.UseRouter(routeBuilder.Build());
}
```

> In a real world application we would probably call `RunCompositionGateway` configuring routes we need. We could say that `RunCompositionGatewayWithDefaultRoutes` is for simple scenarios or demo purposes.

Here is when the new routing engine shines. Finally custom routes and route handlers can be defined and injected into the engine. That's exactly what we are doing in `MapComposableGet`. `MapComposableGet` calls a more generic `MapComposableRoute` defined as follows:

```csharp
public static IRouteBuilder MapComposableRoute(this IRouteBuilder routeBuilder,
   string template,
   IDictionary<string, object> constraints,
   RouteValueDictionary defaults = null,
   RouteValueDictionary dataTokens = null)
{
   var route = new Route(
      target: new RouteHandler(ctx => HandleRequest(ctx)),
      routeTemplate: template,
      defaults: defaults,
      constraints: constraints,
      dataTokens: dataTokens,
      inlineConstraintResolver: routeBuilder.ServiceProvider.GetRequiredService<IInlineConstraintResolver>()
   );

   routeBuilder.Routes.Add(route);

   return routeBuilder;
}
```

We are defining a custom route using the supplied `template` and constraints. The relevant line of code is the following:

```csharp
target: new RouteHandler(ctx => HandleRequest(ctx))
```

where a custom route handler is defined. Finally, in the custom route handler is where composition happens.

`HandleRequest` does 5 things:

1. Retrieves from the `IoC/DI` container all instances implementing either `IHandleRequests` or `ISubscribeToCompositionEvents`
2. Filters out, calling `Matches`, all the one not interested in handling the current request
3. Iterates over all `ISubscribeToCompositionEvents` giving them the opportunity to `Subscribe` to events
4. Iterates over `IHandleRequests`  invoking `Handle` 
5. Once composition is completed, returns the composed ViewModel to the client.

## Conclusion

Before composition happens many moving parts are involved. It seems complex at the beginning, but once it's clear that the behavior is not that different from a regular reverse proxy it's probably easier to find a place for each one of the moving parts. I crafted a simple Composition Gateway implementation and a reference sample implementation. It's available on my GitHub account in the [composition-gateway-sample](https://github.com/mauroservienti/composition-gateway-sample) repository.

---

Header image: Photo by [Bruce Warrington](https://unsplash.com/photos/-gcMdCCo_ys?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/motor?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
