---
layout: post
title: "ServiceComposer 6.0: feeling at home, without the surprises"
author: Mauro Servienti
synopsis: "6.0 makes composition over controllers a first-class citizen, gives conventions and filters a view of the components behind each route, and trades a few surprising behaviors for safer defaults."
header_image: /img/posts/servicecomposer-6/header.jpg
related:
- 2025-01-08-all-new-goodies-in-servicecomposer.md
- 2025-04-23-contract-less-handlers.md
- 2026-10-28-servicecomposer-strongly-typed-models.md
- 2026-11-17-controllers-to-servicecomposer.md
tags:
- viewmodel-composition
- development
series: view-model-composition
---

[ServiceComposer 6.0.0](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/6.0.0) is out, on [NuGet](https://www.nuget.org/packages/ServiceComposer.AspNetCore/6.0.0). [6.0.1](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/6.0.1) followed the same day, fixing contract-less handlers with parameters of generic types.

The [last](https://milestone.topics.it/2025/01/08/all-new-goodies-in-servicecomposer.html) [posts](https://milestone.topics.it/2025/04/23/contract-less-handlers.html) about ServiceComposer were about making ViewModel Composition feel at home in ASP.NET Core. 6.0 goes further in the same direction, and removes the behaviors that surprised users: authorization attributes silently ignored, filters wrapping more than their handler, and handlers not running when users expected them to.

It's a major, so it comes with breaking changes. The [upgrade guide](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/upgrade-guides/5.x.x-6.0.0.md) lists them all, and each one says what changed and what to do. Let's look at what's new.

## Composition over controllers, grown up

Composition over controllers lets an MVC application move [from controllers to ServiceComposer, one route at a time](https://milestone.topics.it/2026/11/17/controllers-to-servicecomposer.html). Last year, I was inclined to make it obsolete: there's an [issue](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/788) about it, raised in 2024. However, I realized it's the best migration path to ServiceComposer, and it deserves more attention, to keep it aligned with what regular composition handlers can do. So, here we are.

### One mode: an endpoint filter

`EnableCompositionOverControllers()`, which added an MVC result filter to every controller, is gone: obsolete in 5.3, it's a compilation error in 6.0. ([#1116](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1116), [#1126](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1126)) Controller endpoints opt in with `WithCompositionOverControllers()` instead, like the following:

```csharp
builder.Services.AddViewModelComposition();
builder.Services.AddControllers();

var app = builder.Build();
app.MapControllers()
    .WithCompositionOverControllers();
app.MapCompositionHandlers();
```

The composition handlers run as an endpoint filter, so other endpoint filters on the controller endpoints wrap both the action and the handlers. For example, a filter opening a transaction covers the work done by both. For that to work, `WithCompositionOverControllers()` must be the last endpoint filter added. `MapCompositionHandlers()` is still needed: it finds the handlers matching the controllers' routes.

### Controllers and handlers cooperate

In 5.x, when a controller action returned a model, the handlers composed into a new view model, and that view model was discarded. In 6.0, the handlers compose into the model the action returns: the controller acts as the view model factory for the request. ([#273](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/273))

In the following example, the response contains both the name set by the controller and the price set by the composition handler:

```csharp
[Route("/products")]
public class ProductsController : ControllerBase
{
    [HttpGet("{id}")]
    public IActionResult Get(int id)
    {
        dynamic product = new ExpandoObject();
        product.Name = "Product name";

        // Composition handlers compose into the returned model
        return Ok(product);
    }
}

public class ProductPriceHandler : ICompositionRequestsHandler
{
    [HttpGet("/products/{id}")]
    public Task Handle(HttpRequest request)
    {
        var vm = request.GetComposedResponseModel();
        vm.Price = 42m;

        return Task.CompletedTask;
    }
}
```

The handler writes through `dynamic`, so the controller's model must support dynamic members, like `ExpandoObject`. With a typed model, use `GetComposedResponseModel<T>()`.

What if the action doesn't return a model? It depends on what it returns:

- **An error**, i.e. a 4xx or 5xx status code, `Forbid()`, or `Challenge()`: the handlers don't run. When the controller rejects the request, handlers with side effects, like sending a command, shouldn't run either.
- **A result with no room for a model**, e.g. a redirect or a plain `Ok()`: the handlers run, as in 5.x, but the response is the controller's, and whatever the handlers composed is thrown away. Why run them at all, then? Because handlers don't only compose. A form posting to an action that redirects, the POST-redirect-GET pattern, is a common example: the `POST` handlers composing over that action are the ones sending commands to the back end. Skip them, and nothing happens. ([#1218](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1218))

Should handlers also run over error results, as an opt-in? [#1221](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1221) tracks the interest: if you have a use case, comment there.

### A regression caught by a demo

The redirect rule didn't start like that. In 6.0.0-beta.2, handlers didn't run at all when the controller action returned a result that can't carry a model. A redirect has no model to compose into, so skipping the handlers looked like saving some work.

Then I upgraded the [Welcome to the state machine demo](https://github.com/mauroservienti/welcome-to-the-state-machine-demos) to beta.2. Its website uses POST-redirect-GET: reserving a ticket, finalizing, and checking out are `POST` requests to controller actions that return `RedirectToAction(...)`. The composition handlers composing over those actions are the ones sending the commands to Reservations, Finance, and Shipping. With beta.2, they'd stop running. No exception, no warning: the user is redirected as usual, and nothing happens behind the scenes.

The demo's tests were all green. They call the handlers directly: they check what each handler sends, not that ServiceComposer runs it.

[6.0.0-beta.3](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/6.0.0-beta.3) fixed it: handlers run over every result that isn't an error, and a debug log says when the composed view model is discarded. ([#1218](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1218))

The demo also got an [end-to-end test](https://github.com/mauroservienti/welcome-to-the-state-machine-demos/pull/654). It starts the whole system with Aspire's testing support, reserves and checks out a ticket through the website, and waits for the payment to succeed and the order to ship. It fails on beta.2, passes on beta.3, and runs in CI in about two minutes.

The lesson I keep relearning: testing each piece in isolation doesn't tell you the pieces are wired together. And composition is all about wiring.

> That's not news, and it's why I keep writing about integration testing. ["Exploring NServiceBus integration testing options"](https://milestone.topics.it/2019/07/04/exploring-nservicebus-integration-testing-options.html) starts from the same problem with messaging: unit tests check each handler, and nothing checks the whole business scenario. [NServiceBus.IntegrationTesting 3](https://milestone.topics.it/2026/03/06/integration-testing-3.html) runs real endpoints in containers, against a real broker and real persistence, and ["You wanna test HTTP, right?"](https://milestone.topics.it/2021/04/28/you-wanna-test-http.html) goes through the options for HTTP. The demo's end-to-end test goes one level up: from the website request to the last message handled.

### Handlers' authorization is enforced

In 5.x, `[Authorize]` on a handler composing over a controller was ignored: only the controller's and the action's attributes applied. ([#1119](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1119))

In 6.0, `WithCompositionOverControllers()` adds the handlers' metadata to the controller endpoint, and callers must satisfy all the requirements. The most restrictive ones win: if anything on the route requires authorization, `[AllowAnonymous]` is ignored, also on the action. Security first. Conventions added afterward see the handlers' metadata too, and the `CompositionEndpointComponents` item described below.

### Matching the right action

Handlers compose over the controller action with the same HTTP method, also when the controller has other actions on the same template, or when it's mapped after other endpoints, e.g. minimal APIs. Before, these setups failed at startup, returned a 405, or failed requests with an `AmbiguousMatchException`. The fix is in 5.3.4 too. ([#1211](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1211))

## Seeing the components behind a route

Endpoint filters and conventions see a composition endpoint, not the handlers behind it. What if a convention needs to know which handlers run on a route, for example, to read their attributes?

In 6.0, each composition endpoint carries a `CompositionEndpointComponents` metadata item listing its handlers, subscribers, and view model factory, with their classes, methods, and attributes. ([#1153](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1153)) The following convention, for example, lists the composition handlers of each endpoint:

```csharp
app.MapCompositionHandlers().Add(endpointBuilder =>
{
    var components = endpointBuilder.Metadata
        .OfType<CompositionEndpointComponents>()
        .Single()
        .Components;

    foreach (var component in components.Where(c => c.Kind == CompositionComponentKind.RequestsHandler))
    {
        // component.UserType and component.Method are the user's class and method,
        // also for contract-less composition handlers.
        Console.WriteLine($"{endpointBuilder.DisplayName}: {component.UserType.Name}.{component.Method.Name}, " +
                          $"{component.TypeAttributes.Count} class and {component.MethodAttributes.Count} method attributes");
    }
});
```

`MapCompositionHandlers()` now returns `CompositionEndpointConventionBuilder`, so libraries can add extension methods that apply to composition endpoints only. ([#1149](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1149)) More in [reading a route's components](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/endpoint-filters.md#reading-a-routes-components).

## Composition filters run per handler

In 5.x, all the filters of a route wrapped the whole composition: a filter declared on one handler ran around all the handlers of the route, and short-circuiting skipped all of them. ([#784](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/784))

In 6.0, each filter wraps the handler it's declared on, and `CompositionRequestFilterContext.Handler` says which one. Short-circuiting skips that handler only.

`InvokeAsync` returns `ValueTask` instead of `ValueTask<object>`, because the value a filter returns is no longer the response: the response is always the composed view model, or the action result set with `SetActionResult`. Updating a filter looks like the following:

```csharp
// 5.x
public override async ValueTask<object> InvokeAsync(CompositionRequestFilterContext context, CompositionRequestFilterDelegate next)
{
    // before the handlers
    var viewModel = await next(context);
    // after the handlers
    return viewModel;
}

// 6.0.0
public override async ValueTask InvokeAsync(CompositionRequestFilterContext context, CompositionRequestFilterDelegate next)
{
    // before the handler
    await next(context);
    // after the handler
}
```

Logic for the whole request belongs in an endpoint filter now. Composition filters are for what concerns their handler: the [composition filters docs](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/composition-filters.md#accessing-the-view-model-and-the-action-result) show how to set defaults on the view model before the handler runs, read or change what it composed, and reject an invalid request on its behalf with an action result.

## Registering components without assembly scanning

ServiceComposer finds composition components by scanning assemblies at startup. 6.0 adds another way: `ICompositionComponentsProvider`. ([#1094](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1094), [#1108](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1108))

A source generator emits one in every assembly that contains composition components ([#1109](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1109)), and `options.RegisterReferencedComponents()` registers all the referenced ones ([#1110](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1110)). Scanning and providers can be mixed, so the migration can be gradual.

It's the first step toward Native AOT: more in "What's next".

## Smaller things that add up

- `[Route]` on component classes prefixes their routes, as it does on controllers. ([#148](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/148))
- A view model factory returning `null` falls through to the next one, instead of giving the handlers a `null` view model. ([#232](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/232))
- Declarative model binding errors return a `400 Bad Request` with problem details, and `Bind<T>()` throws on binding errors. ([#674](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/674))
- When output formatters aren't used, responses use the minimal APIs JSON options, configured with `ConfigureHttpJsonOptions()`. ([#1160](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1160))
- Misconfigurations show up at startup:
  - enabling output formatters without the MVC services fails, instead of failing the first request ([#1159](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1159));
  - write routes that aren't mapped because write support is disabled are logged ([#658](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/658));
  - routes with no composition handler aren't mapped, and a warning lists them ([#1199](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1199)).

## Security fixes

6.0 includes two authorization fixes, also released in 5.3.1 and 4.3.3:

- attributes on handler classes are honored ([GHSA-mh5p-7fmw-pw24](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/security/advisories/GHSA-mh5p-7fmw-pw24));
- `[AllowAnonymous]` on one handler no longer disables another's authorization ([GHSA-rfp4-mgx6-3c5x](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/security/advisories/GHSA-rfp4-mgx6-3c5x)).

They're security advisories because, in both cases, requests that should have been rejected reached the composition handlers. If you still have 5.x or 4.x applications, upgrade them to the latest 5.3 or 4.3 release too.

## Documentation

The docs got new pages and sections: attribute routing, single item and list composition, view model preview handlers, route matching casing, casing with output formatters, and generic event handlers as the recommended default. ([#233](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/233), [#234](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/234), [#280](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/280), [#281](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/281), [#282](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/282), [#781](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/781), [#1099](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1099))

The [documentation index](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/README.md) is the place to start.

## Upgrading

- Start from the [upgrade guide](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/upgrade-guides/5.x.x-6.0.0.md): each breaking change says what changed and what to do.
- Only the last two majors are supported: 6.0, and 5.3 for bug fixes. 4.x is no longer supported, and 4.3.6 is its last release.
- The demos are on 6.0. The upgrade pull requests of [All our aggregates are wrong](https://github.com/mauroservienti/all-our-aggregates-are-wrong-demos/pull/721) and [Welcome to the state machine](https://github.com/mauroservienti/welcome-to-the-state-machine-demos/pull/651) show the move from `EnableCompositionOverControllers()` to `WithCompositionOverControllers()`.

## What's next

Native AOT support is planned for a 6.x minor, with assembly scanning disabled. ([#510](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/510)) In 7.0, AOT becomes the default, and assembly scanning an opt-in.

A few nice-to-haves are on the list too:

- **Accessing the dynamic view model through interfaces** ([#1079](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1079)). Today, type safety needs a concrete view model class implementing every service's interface, and a view model factory, both living in the composition host. Every time a service changes its interface, that class changes too. With a proxy over the dynamic view model, each service gets a typed view of the data it owns, and there's no shared class to keep in sync.
- **Binding to properties of contract-less handlers** ([#1189](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1189)). Values shared by the handler methods of the same class, e.g. a tenant route value, would be declared once, as properties, like MVC does with `[BindProperty]`. The source generator would do the binding, with no reflection, so it stays compatible with the AOT work.
- **API versioning** ([#1180](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1180)). Versions in the URL already work, and the class-level `[Route]` makes them easier. The issue is about versions in the query string, headers, or media type, with ASP.NET API Versioning, in a separate package, so that the core one doesn't depend on it.

---

Photo by <a href="https://unsplash.com/@karenchew?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Karen Chew</a> on <a href="https://unsplash.com/photos/a-close-up-of-a-book-with-musical-notes-8MOLegdydLk?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a>
