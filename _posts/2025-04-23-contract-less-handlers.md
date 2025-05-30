---
layout: post
title: "ServiceComposer contract-less composition request handlers"
author: Mauro Servienti
synopsis: "Recently, I started thinking about evolving the ServiceComposer user-facing API. I was faced with many options, leading me to analysis paralysis. I decided to start with a principle first: The feel-at-home ServiceComposer principle. This principle led me to introduce a new syntax that mimics ASP.NET controllers for defining composition handlers. This syntax helps users reduce the learning and adoption curve. Let's take a look, shall we?"
header_image: /img/posts/contract-less-handlers/header.jpg
tags:
- viewmodel-composition
series: view-model-composition
---

Look at this beauty:

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

It's not an ASP.NET controller. It's a ServiceComposer composition handler (requires [ServiceComposer 4.2.0-alpha.1](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/4.2.0-alpha.1)); to be more precise, it's a [contract-less composition requests handler](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/contract-less-composition-requests-handlers.md). Syntax-wise, it's so much better than the current way of declaring composition handlers:

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

The new style doesn't require an interface or applying those _BindFrom*_ attributes. Not to mention that all binding operations are automatically executed, and their results are presented to the code as method arguments.

## The "feeling-at-home" principle

Why all this fuzz, one could argue? In my [last article](https://milestone.topics.it/2025/01/08/all-new-goodies-in-servicecomposer.html), I introduced the "feeling-at-home" principle. ServiceComposer always aimed to be a first-class citizen in the ASP.NET ecosystem, but the required composition syntax was departing too much from the one of controllers and actions.

In the end, if you think about it, ServiceComposer handles incoming HTTP requests, like any controller, with the only difference being that there could be more than one composition handler for a given request—ASP.NET complains if more than one controller action is configured to handle the same route.

## There is more

The "feeling-at-home" principle also led to a couple more functionalities.

Similar to ASP.NET, ServiceComposer now supports [endpoint filters](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/endpoint-filters.md), using the same semantics, types, and syntax as ASP.NET. Last but not least, [composition request filters](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/composition-filters.md) are a long-standing feature that provides a similar experience to ASP.NET action filters.

## Source generators for the win

Contract-less composition requests handlers are (_a sort of_) syntactic sugar. The ServiceComposer composition engine knows nothing about them. At compile time, a custom source generator creates a class that implements the required `ICompositionRequestsHandler` interface and forwards invocations to the user contract-less handler. It's effectively a proxy.

For example, given a user-defined contract-less handler like the following:

```csharp
namespace Snippets.Contractless.CompositionHandlers;
class SampleCompositionHandler
{
    [HttpGet("/sample/{id}")]
    public Task SampleMethod(int id, [FromQuery(Name = "c")]string aValue, [FromBody]ComplexType ct)
    {
        return Task.CompletedTask;
    }
}
```

At compile time, source generation adds a class like the following:

```csharp
// <auto-generated/>
using CompositionHandlers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using ServiceComposer.AspNetCore;
using Snippets.Contractless.CompositionHandlers;
using System;
using System.ComponentModel;
using System.Threading.Tasks;

#pragma warning disable SC0001
namespace Snippets.Contractless.CompositionHandlers.Generated
{
    [EditorBrowsable(EditorBrowsableState.Never)]
    class SampleCompositionHandler_SampleMethod_int_id_string_aValue_Snippets_Contractless_CompositionHandlers_ComplexType_ct(Snippets.Contractless.CompositionHandlers.SampleCompositionHandler userHandler)
         : ICompositionRequestsHandler
    {
        [HttpGetAttribute("/sample/{id}")]
        [BindFromRoute<Int32>("id")]
        [BindFromQuery<String>("c")]
        [BindFromBody<ComplexType>()]
        public Task Handle(HttpRequest request)
        {
            var ctx = HttpRequestExtensions.GetCompositionContext(request);
            var arguments = ctx.GetArguments(this);
            var p0_id = ModelBindingArgumentExtensions.Argument<Int32>(arguments, "id", BindingSource.Path);
            var p1_c = ModelBindingArgumentExtensions.Argument<String>(arguments, "c", BindingSource.Query);
            var p2_ct = ModelBindingArgumentExtensions.Argument<ComplexType>(arguments, "ct", BindingSource.Body);

            return userHandler.SampleMethod(p0_id, p1_c, p2_ct);
        }
    }
}
#pragma warning restore SC0001
```

The generated and user classes are registered in the _Inversion of Control_ container, enabling dependency injection in the user contract-less composition requests handler.

The advantage is clear. The code is less verbose and, as such, easier to read and maintain.

Another great pro is that contract-less composition request handlers allow bundling multiple handler methods in the same class, keeping together logically correlated composition request handlers. The maintenance advantage is clear compared to the previous approach, which required a different class for each handler.

As you can see, the generated class name `SampleCompositionHandler_SampleMethod_int_id_string_aValue_Snippets_Contractless_CompositionHandlers_ComplexType_ct` enforces uniqueness even in the case of more than one method overload. Or at least, I hope so :-)

## Why an alpha?

There are still many unanswered questions, such as: Is the feature covering most (all?) scenarios?

I don't know yet. I have not finished porting all the tests to use it, and there are still some dark spots. What about stuff like default arguments?

In a recent release of the `Microsoft.CodeAnalysis.Analyzers` package, the .NET team deprecated source generators in favor of incremental source generators. The migration is far from straightforward; it's indeed a PITA. I want to evaluate whether it's worth migrating before the final release or releasing it as is and doing the migration in a subsequent minor.

Last but not least, there are some pending design decisions. For example, the interface approach gives immediate access to the HTTP request, context, and surrounding properties. The contract-less approach makes it more difficult, requiring users to opt-in to the HTTP context accessor, register it in the IoC container, and add a dependency.

It’s not the end of the world, but are there better options? Sure thing. For example, ServiceComposer contract-less request handlers could support the `[FromServices]` to make the design even more in line with ASP or support a convention-based approach. If the handler has a non-private HttpContex property, the source generator will emit code to set it.

It's critical to mention that `4.2.0.-alpha.1` includes no other changes. That means it's safe to update, as all existing functionalities remain unchanged. Using the new syntax to define contract-less composition request handlers is opt-in.

## Conclusion

Without source generators, implementing such a feature would have required a great deal of reflection at startup to discover user contract-less handlers, followed by some magic to generate and compile some expression trees to avoid the performance penalties of reflection-based invocation. Source generators are not straightforward but are indeed better than the alternatives.

---

Photo by <a href="https://unsplash.com/@silas_1976?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">silas Tarus</a> on <a href="https://unsplash.com/photos/a-black-and-white-photo-of-construction-cranes-0x29kOD2AHg?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
