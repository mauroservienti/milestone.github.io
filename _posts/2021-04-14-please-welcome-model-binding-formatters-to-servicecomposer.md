---
layout: post
header_image: /img/posts/please-welcome-model-binding-formatters-to-servicecomposer/header.jpg
title: "Please welcome Model Binding and Formatters to ServiceComposer"
author: Mauro Servienti
synopsis: "Model binding frees the code from dealing with incoming payload content type and deserialization issues. It's a great way to move the attention from infrastructure code to business code. Model binding is now available in ServiceComposer."
tags:
- soa
- Model Binding
- Output formatters
- Input formatters
- viewmodel-composition
category: view-model-composition
---

The ServiceComposer API has been historically pretty low level. Users can access the incoming `HttpRequest` and the outgoing `HttpResponse` to read and manipulate content.

> What's ServiceComposer? ServiceComposer is a view model composition gateway designed to compose data owned by different (micro)services and transparently serve users' requests with a single response view model. More information about the overall architectural problem and the many nuances are available in the [ViewModel Composition series](https://milestone.topics.it/categories/view-model-composition) of articles on this blog.

To plugin logic into the ServiceComposer pipeline, users need to provide an implementation of the `ICompositionRequestHandler` interface, for example, using something like the following class:

```csharp
class SampleHandler : ICompostionRequestHandler
{
   [HttpGet("sample/{id}")]
   public Task Handle(HttpRequest request)
   {
      //composition steps here.
   }
}
```

At runtime, ServiceComposer inspects the incoming HttpRequest, and if any defined composition handler matches the request URL, ServiceComposer invokes the `Handle` method.

> The incoming request matching is performed using regular ASP.NET attribute routing support. More information is in ["Please welcome Attribute Routing to ServiceComposer."](https://milestone.topics.it/view-model-composition/2021/02/11/please-welcome-attribute-routing-to-servicecomposer.html)

At this point, if there is a need to retrieve query string values, route data values, body or form content, users need to write the code to extract that information from the incoming `HttpRequest`. For example, to extract route data:

```csharp
[HttpPost("sample/{id}")]
public Task Handle(HttpRequest request)
{
    var routeData = request.HttpContext.GetRouteData();
    var id = int.Parse(routeData.Values["id"].ToString());

    //use the id value as needed

    return Task.CompletedTask;
}
```

The code is not complex; however, it's error-prone, and the compiler cannot help. To make it more robust, we should move away from `Parse` to `TryParse` and handle the failure scenario, for example.

Things get much worse when the incoming request contains a body that we need to process the request:

```csharp
[HttpPost("sample/{id}")]
public async Task Handle(HttpRequest request)
{
    request.Body.Position = 0;
    using var reader = new StreamReader(request.Body, Encoding.UTF8, leaveOpen: true );
    var body = await reader.ReadToEndAsync();
    var content = JObject.Parse(body);

    //use the content object instance as needed, e.g.:
    var aString = content?.SelectToken("AString")?.Value<string>();
}
```

Too many things are happening simultaneously; we first need to rewind the stream, there might have been other handlers that processed the request body, and thus, the stream position is at the end. We need to know the request encoding; in the above sample, UTF8 is hardcoded, and it's also crucial to leave the stream open when the read operation completes. Finally, we can't assume the content is a JSON object, let alone parse and use it. If we don't want to deserialize to a POCO object, we need to deal with the JObject API.

## Model binding to the rescue

Starting with version 1.9.0, ServiceComposer supports ASP.NET model binding. Using the above sample, we need to bind two things, the request body and one route value, the ID parameter. We first need a model for the request body:

```csharp 
class BodyModel
{
    public string AString { get; set; }
    //all the properties that we need
}
```

If we were using ASP.NET controllers, that would have been enough. A controller action signature like the following describes the intention in a good enough manner for the binder to understand what to do:

```csharp 
[HttpPost("sample/{id}")]
public Task<object> Sample(int id, [FromBody]BodyModel model)
```

ASP.NET binding logic matches the first argument name with the route template value key, and thanks to the `[FromBody]` attribute, the second argument gets deserialized from the incoming request body. Pretty straightforward.

In ServiceComposer, we're not yet there, even if we're paving the road to provide a similar experience. We need to explain to the binder where the values we want to bind to are coming from. We can do that with an intermediate class:

```csharp
class RequestModel
{
    [FromRoute] public int id { get; set; }
    [FromBody] public BodyModel Body { get; set; }
}
```

The `RequestModel` class is what glues all the concepts that we need together. We have a public property, id, that matches the route value key and is decorated with the `[FromRoute]` attribute to explain to the binder where the value comes from, and a public property for the body using binding attributes as well.

> By the way, class names can be whatever you want.

With the two above classes in place, we can now write the following handler:

```csharp
[HttpPost("sample/{id}")]
public async Task Handle(HttpRequest request)
{
    var requestModel = await request.Bind<RequestModel>();
    var body = requestModel.Body;
    var aString = body.AString;
    var id = requestModel.id;

    //use values as needed
}
```

Thanks to model binding, the presented code becomes much more maintainable and easier to understand. Not to mention that it is now compiler safe, since it's strongly typed.

## Formatters

A welcome side effect of using the ASP.NET model binding infrastructure is that now ServiceComposer automatically supports input formatters. Previously it was up to the user to determine the serialization format of the incoming payload in their handling code, with model binding that becomes transparent and can be configured using standard ASP.NET configuration and HTTP headers to describe the request content type.

Similarly, we decided to support output formatters. Output formatters were a natural choice to decouple ServiceComposer from the hardcoded JSON serialization format and start honoring the "accept" HTTP header. For backward compatibility reasons, output formatters are not enabled by default; they need to be explicitly enabled at configuration time:

```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddViewModelComposition(options =>
    {
        options.ResponseSerialization.UseOutputFormatters = true;
    });
    services.AddControllers();
}
```

Both formatters and model binding require the MVC infrastructure to be in place. This means that, as in the above snippet, one of the following needs to be configured:

- AddControllers()
- AddControllersAndViews()
- AddMvc
- AddRazorPages()

## Conclusion

With model binding and input and output formatters, ServiceComposer is moving from providing only a low-level API to a more robust and easy-to-use approach to maximize the developer experience and reduce errors. Model binding and formatters pave the way for a feature that has been in the back of my mind since its inception: a controller-like API that allows users to express their binding intentions through the handle method signature. The road is still long, but the journey just started.

Last but not least, credit where it's due. Thanks to [Mark Phillips](https://github.com/markphillips100) for the ideas, the brainstorming, and the support in developing the mentioned features.

---

Photo by <a href="https://unsplash.com/@brett_jordan?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Brett Jordan</a> on <a href="https://unsplash.com/s/photos/binder?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
