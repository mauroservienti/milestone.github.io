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

<!-- TODO: confirm the title and the synopsis. -->
<!-- TODO: write the intro from the following notes. -->

- [ServiceComposer 6.0.0](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/6.0.0) is out, on [NuGet](https://www.nuget.org/packages/ServiceComposer.AspNetCore/6.0.0).
- The theme: keep "feeling at home" in ASP.NET Core, from the [last](https://milestone.topics.it/2025/01/08/all-new-goodies-in-servicecomposer.html) [posts](https://milestone.topics.it/2025/04/23/contract-less-handlers.html), and remove the behaviors that surprised users.
- It's a major: breaking changes are listed in the [upgrade guide](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/upgrade-guides/5.x.x-6.0.0.md).

## Composition over controllers, grown up

<!-- TODO: why it matters. -->
Composition over controllers is the migration path from [controllers to ServiceComposer, one route at a time](https://milestone.topics.it/2026/11/17/controllers-to-servicecomposer.html).

### One mode: an endpoint filter

- `EnableCompositionOverControllers()`, an MVC result filter for every controller, is gone: obsolete in 5.3, a compilation error in 6.0. ([#1116](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1116), [#1126](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1126))
- `WithCompositionOverControllers()` opts controller endpoints in, and runs the handlers as an endpoint filter: other endpoint filters wrap both the action and the handlers.
<!-- TODO: snippet: `app.MapControllers().WithCompositionOverControllers();` -->

### Controllers and handlers cooperate

- Handlers compose into the model the controller action returns, instead of replacing it. ([#273](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/273))
- Error results, i.e. 4xx and 5xx status codes, `Forbid()` and `Challenge()`, skip the handlers: when the controller rejects the request, handlers with side effects shouldn't run.
- Results that can't carry a model, e.g. redirects and `Ok()`, are still composed, and the view model is discarded, as in 5.x. POST-redirect-GET keeps working: `POST` handlers composing over an action that redirects still send their commands. ([#1218](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1218))
- Should handlers also run over error results, as an opt-in? [#1221](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1221) tracks the interest: comment there with your use case.
<!-- TODO: snippet: `composition-over-controllers-controller-model` from the docs. -->

### A regression caught by a demo

The redirect rule didn't start like that. In 6.0.0-beta.2, handlers didn't run at all when the controller action returned a result that can't carry a model. A redirect has no model to compose into, so skipping the handlers looked like saving some work.

Then I upgraded the [Welcome to the state machine demo](https://github.com/mauroservienti/welcome-to-the-state-machine-demos) to beta.2. Its website uses POST-redirect-GET: reserving a ticket, finalizing, and checking out are `POST` requests to controller actions that return `RedirectToAction(...)`. The composition handlers composing over those actions are the ones sending the commands to Reservations, Finance, and Shipping. With beta.2, they'd stop running. No exception, no warning: the user is redirected as usual, and nothing happens behind the scenes.

The demo's tests were all green. They call the handlers directly, so they check what each handler sends, not that ServiceComposer runs it.

[6.0.0-beta.3](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/6.0.0-beta.3) fixed it ([#1218](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1218)): handlers run over every result that isn't an error, and a debug log says when the composed view model is discarded. The demo also got an [end-to-end test](https://github.com/mauroservienti/welcome-to-the-state-machine-demos/pull/654): it starts the whole system with Aspire's testing support, reserves and checks out a ticket through the website, and waits for the payment to succeed and the order to ship. It fails on beta.2 and passes on beta.3, and it runs in CI in about two minutes.

The lesson I keep relearning: testing each piece in isolation doesn't tell you the pieces are wired together. Composition is all about wiring.
<!-- TODO: keep, shorten, or move the story to its own post. -->

### Handlers' authorization is enforced

- Before: `[Authorize]` on a handler composing over a controller was ignored; only the controller's applied. ([#1119](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1119))
- Now: the handlers' metadata goes on the controller endpoint. The most restrictive requirements win: a handler's `[Authorize]` beats the action's `[AllowAnonymous]`. Security first.
- Conventions see the components through `CompositionEndpointComponents`.

### Matching the right action

- Handlers compose over the controller action with the same HTTP method, also when the controller has other actions on the same template, or is mapped after other endpoints, e.g. minimal APIs. Before, these setups failed at startup, returned a 405, or failed requests with an `AmbiguousMatchException`. Also fixed in 5.3.4. ([#1211](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1211))

## Seeing the components behind a route

- `CompositionEndpointComponents`: each composition endpoint lists its handlers, subscribers and view model factory, with their classes, methods and attributes. Conventions and endpoint filters can read it. ([#1153](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1153))
- `MapCompositionHandlers()` returns `CompositionEndpointConventionBuilder`, so libraries can add extension methods for composition endpoints only. ([#1149](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1149))
<!-- TODO: snippet: the `composition-endpoint-components` convention from the endpoint filters docs. -->

## Composition filters run per handler

- Before: all the filters of a route wrapped the whole composition. ([#784](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/784))
- Now: each filter wraps the handler it's declared on, and `CompositionRequestFilterContext.Handler` says which one. Short-circuiting skips that handler only.
<!-- TODO: snippet: before and after `InvokeAsync`, from the upgrade guide. -->
<!-- TODO: mention the view model and action result examples in the composition filters docs. -->

## Registering components without assembly scanning

- `ICompositionComponentsProvider`, and a source generator emitting one in every assembly with composition components. ([#1094](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1094), [#1108](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1108), [#1109](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1109))
- `options.RegisterReferencedComponents()` registers all referenced providers. ([#1110](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/pull/1110))
- Scanning and providers can be mixed while migrating.
- The first step toward Native AOT: see "What's next".

## Smaller things that add up

- `[Route]` on component classes prefixes their routes, as on controllers. ([#148](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/148))
- A view model factory returning `null` falls through to the next one. ([#232](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/232))
- Declarative model binding errors return `400 Bad Request` with problem details, and `Bind<T>()` throws on binding errors. ([#674](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/674))
- Responses use the minimal APIs JSON options, configured with `ConfigureHttpJsonOptions()`. ([#1160](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1160))
- Fail fast:
  - output formatters enabled without MVC services fail at startup ([#1159](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1159));
  - write routes with write support disabled are logged ([#658](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/658));
  - routes with no composition handler aren't mapped, and are logged ([#1199](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1199)).
<!-- TODO: pick 2-3 to expand, and keep the rest as a list. -->

## Security fixes

- Two authorization fixes, also released in 5.3.1 and 4.3.3:
  - attributes on handler classes are honored ([GHSA-mh5p-7fmw-pw24](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/security/advisories/GHSA-mh5p-7fmw-pw24));
  - `[AllowAnonymous]` on one handler no longer disables another's authorization ([GHSA-rfp4-mgx6-3c5x](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/security/advisories/GHSA-rfp4-mgx6-3c5x)).
<!-- TODO: one line on why they're advisories, and to upgrade the 5.x and 4.x apps too. -->

## Documentation

- New pages and sections: attribute routing, single item and list composition, view model preview handlers, route matching casing, casing with output formatters, generic event handlers as the default. ([#233](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/233), [#234](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/234), [#280](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/280), [#281](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/281), [#282](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/282), [#781](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/781), [#1099](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1099))
<!-- TODO: link the docs index. -->

## Upgrading

- Read the [upgrade guide](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/upgrade-guides/5.x.x-6.0.0.md): each breaking change says what changed and what to do.
- Supported versions: only the last two majors are supported, so 6.0, and 5.3 for bug fixes. 4.x is no longer supported: 4.3.6 is its last release.
- The demos are on 6.0: [All our aggregates are wrong](https://github.com/mauroservienti/all-our-aggregates-are-wrong-demos) and [Welcome to the state machine](https://github.com/mauroservienti/welcome-to-the-state-machine-demos) show the upgrade from `EnableCompositionOverControllers()` to `WithCompositionOverControllers()`. <!-- TODO: update the links to the upgrade commits once Renovate moves them from beta.3 to 6.0.0. -->
- Release notes are now shorter, with a "what to do" for every behavior change. <!-- TODO: keep or drop. -->

## What's next

- Native AOT in a 6.x minor, with assembly scanning disabled: [#510](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/510).
- 7.0: AOT by default, with assembly scanning as an opt-in.
<!-- TODO: anything else? Accessing the dynamic view model through interfaces ([#1079](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1079)), binding to contract-less handlers' properties ([#1189](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1189)), API versioning ([#1180](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1180)). -->

---

Photo by <a href="https://unsplash.com/@karenchew?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Karen Chew</a> on <a href="https://unsplash.com/photos/a-close-up-of-a-book-with-musical-notes-8MOLegdydLk?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a>
