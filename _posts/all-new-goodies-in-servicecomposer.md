---
layout: post
title: "All the new goodies in ServiceComposer"
author: Mauro Servienti
synopsis: "Thanks to users’ feedback, I enjoyed working on some new cool ServiceComposer features, namely endpoint filters, a greatly improved event handling API, and declarative model binding, which paves the way for a new cool feature in the works"
header_image: /img/posts/all-new-goodies-in-servicecomposer/header.jpg
tags:
- viewmodel-composition
- development
---

It's been a while since [the last blog post](https://milestone.topics.it/2024/04/09/service-control-ghost-endpoints.html), and no, the [20th anniversary](https://milestone.topics.it/2024/11/30/anniversary.html) doesn't count.

Thanks to some user requests, I spent some time working on [ServiceComposer](https://github.com/ServiceComposer/ServiceComposer.AspNetCore), my [ViewModel Composition](https://milestone.topics.it/series/view-model-composition.html) open-source library. I ended up releasing two major releases and one minor release for each one of the majors. A lot of work!

In a few weeks, I released [3.0](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/3.0.0), [3.1](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/3.1.0), [4.0](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/4.0.0), and [4.1](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/4.1.0).

## Versions 3.0 and 3.1

Let's look at what's new in ServiceComposer versions [3.0](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/3.0.0) and [3.1](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/3.1.0). I'll refer to those versions as 3.x.

### Endpoint filters

Version 3.x introduced support for [endpoint filters](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/endpoint-filters.md) using the standard ASP.Net minimal API filters syntax. This feature allows more granular control over the request pipeline, enhancing the flexibility and power of ServiceComposer. The decision to use the minimal API syntax and programming model is to avoid introducing yet another programming style. Overall, ServiceComposer is leaning towards being a citizen in the ASP.Net ecosystem. As such, its API should be aligned as much as possible with the Microsoft one to maintain the 'feel at home' feeling. More on this later.

### Simplified event handling using generic event handlers

In the realm of ViewModel Composition, [events](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/events.md) play a role when composing lists or graphs from a complex data hierarchy.

For an introduction to the list composition problem and its relevance in the context of ServiceComposer, you can read [The ViewModel Lists Composition dance](https://milestone.topics.it/2019/03/21/the-viewmodels-lists-composition-dance.html). The code snippets are outdated, but all the concepts are still valid today.

The standard way of subscribing to events felt clunky and unnatural. I got feedback from users and colleagues. Take a look at the following snippet:

```csharp
public class AnEventSubscriber : ICompositionEventsSubscriber
{
    [HttpGet("/a-route/{some-id}")]
    public void Subscribe(ICompositionEventsPublisher publisher)
    {
        publisher.Subscribe<AnEvent>((@event, request) =>
        {
            // handle the event
            return Task.CompletedTask;
        });
    }
}
```

It was hard to justify the need for the `Http*` attribute and the unnatural way of subscribing to events.

Version 3.x also introduced the concept of [generic event handlers](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/events.md#generic-event-handlers). With the new syntax, the above event handler looks like the following:

```csharp
public class AnEventHandler : ICompositionEventsHandler<AnEvent>
{
    public Task Handle(AnEvent @event, HttpRequest request)
    {
        // handle the event
        return Task.CompletedTask;
    }
}
```

No attributes are required, and the interface implementation guides toward the correct class design to handle events.

However, the old design still has good reasons to exist and will be supported. Generic event handlers, classes implementing `ICompositionEventsHandler<TEvent>`, are invoked every time an event they subscribe to is published, regardless of the currently handled route. If the same event is used in multiple scenarios, e.g., when doing an HTTP GET and a POST, and different behaviors are required, it's better to implement a route-based event handler that can easily differentiate (through the route attribute) the type of request it reacts to.

### Initial support for composition filters

Endpoint filters are at the ASP.Net endpoint level. They can intercept all incoming requests before they are processed by components later in the pipeline. Those components could be either regular controllers or ServiceComposer composition handlers. The only way to know which component will handle the request is to inspect the request path, which is far from trivial.

For those reasons, version 3.x added support for [composition filters](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/composition-filters.md). Their API matches the endpoint filters one, and the main difference is that their pipeline is after the endpoint filters and before invoking composition handlers. We can define composition filters as either an attribute to decorate composition components or as a class implementing the `ICompositionRequestFilter<T>,` where `T` is the component to filter.

*Caveat*: Composition filters are still immature, and their API will evolve in future releases.

### Targeting .NET 8 only breaking change

The last change introduced by 3.0 is a breaking change. It removed all the previously supported framework versions and added support for only .NET 8.

## Versions 4.0 and 4.1

Versions [4.0](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/4.0.0) and [4.1](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/4.1.0) continue the good work users nudged me to do.

### System.Text.Json replaced Newtonsoft.Json

Version 4.0 started with a breaking change, which incidentally was also a requested "feature." System.Text.Json replaced Newtonsoft.Json for all the internal serialization needs. Tests prove that the externally visible behavior did not change. Still, it's a breaking change, and thus, it deserves a major release.

### Declarative model binding

ServiceComposer added support for [model binding](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/model-binding.md) in version 1.9, a long time ago in March 2021. Since then, little to nothing changed. The essence of model binding is that it lets users define models for incoming requests, for example, a class like the following:

```csharp
class RequestModel
{
    [FromRoute(Name = "id")] public int Id { get; set; }
    [FromBody] public BodyModel Body { get; set; }
}
```

And then, in the composition handler, bind the above model:

```csharp
[HttpPost("/sample/{id}")]
public async Task Handle(HttpRequest request)
{
    var requestModel = await request.Bind<RequestModel>();
    var body = requestModel.Body;
    var aString = body.AString;
    var id = requestModel.Id;

    //use values as needed
}
```

The above code is not wrong, but it doesn't play nicely with endpoint filters. The endpoint filters API exposes an arguments list representing the binding results performed by ASP.Net before invoking the HTTP handling pipeline. The need to populate arguments means binding must happen earlier in the process and cannot be performed in the composition handler if users also want to use endpoint filters.

With [declarative model binding](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/model-binding.md#declarative-model-binding), the above composition handler looks like the following:

```csharp
[HttpPost("/sample/{id}")]
[BindFromBody<BodyModel>]
[BindFromRoute<int>(routeValueKey: "id")]
public Task Handle(HttpRequest request)
{
    var arguments = request.GetCompositionContext().GetArguments(this);
    var body = arguments.Argument<BodyModel>();
    var id = arguments.Argument<int>(name: "id");

    return Task.CompletedTask;
}
```

The `RequestModel` wrapper class is no longer needed. The code declares the models for binding using attributes and later, it can access them via the arguments collection exposed by the composition context. There are attributes for all the supported binding sources, such as the query string or request headers. 

The attribute declarations allow the ServiceComposer composition pipeline to determine which model to bind earlier, providing a much nicer user experience.

## What's coming

Declarative model binding is not a destination but the beginning of a new era for ServiceComposer API. Currently, defining a composition handler requires code like the following:

```csharp
namespace CompositionHandlers;

class MyHandler : ICompostitionRequestsHandler
{
    [HttpPost("/sample/{id}")]
    [BindFromBody<BodyModel>]
    [BindFromRoute<int>(routeValueKey: "id")]
    public Task Handle(HttpRequest request)
    {
        return Task.CompletedTask;
    }
}
```

It's not bad; however, in light of the "feeling at home" principle mentioned above, what if users could write something like:

```csharp
namespace CompositionHandlers;

class MyCompositionHandler
{
    [HttpPost("/sample/{id}")]
    public Task Sample(int id, [FromBody]BodyModel model)
    {
        return Task.CompletedTask;
    }
}
```

That looks syntactically identical to an ASP.Net controller action, doesn't it?

I'm working to get there and having fun with source generators. For certain definitions of fun ;-).

Stay tuned!

---

Photo by <a href="https://unsplash.com/@ilincaroman?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Ilinca Roman</a> on <a href="https://unsplash.com/photos/four-assorted-shape-chocolates-mmaiZFhZ3Uc?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>