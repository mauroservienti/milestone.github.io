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

- [ServiceComposer 6.0.0](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/6.0.0) is out. <!-- TODO: check the link once 6.0.0 is tagged. -->
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
- Error and redirect results aren't composed.
<!-- TODO: snippet: `composition-over-controllers-controller-model` from the docs. -->

### Handlers' authorization is enforced

- Before: `[Authorize]` on a handler composing over a controller was ignored; only the controller's applied. ([#1119](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1119))
- Now: the handlers' metadata goes on the controller endpoint. The most restrictive requirements win: a handler's `[Authorize]` beats the action's `[AllowAnonymous]`. Security first.
- Conventions see the components through `CompositionEndpointComponents`.

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
- Supported versions: 6.0, and 5.3 for patches. 4.3 patches end with 6.0 GA. <!-- TODO: confirm the supported versions. -->
- Release notes are now shorter, with a "what to do" for every behavior change. <!-- TODO: keep or drop. -->

## What's next

- Native AOT in a 6.x minor, with assembly scanning disabled: [#510](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/510).
- 7.0: AOT by default, with assembly scanning as an opt-in.
<!-- TODO: anything else? Accessing the dynamic view model through interfaces ([#1079](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1079)), binding to contract-less handlers' properties ([#1189](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1189)), API versioning ([#1180](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/issues/1180)). -->

---

<!-- TODO: header image and Unsplash credit. -->
