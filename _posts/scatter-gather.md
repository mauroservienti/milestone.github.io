---
layout: post
title: "ServiceComposer 5.1 scatter/gather support"
author: Mauro Servienti
synopsis: "Scatter/gather represents a subset of the ViewModel Composition problem space: all the downstream endpoints return the same type of data with the same schema. It was a natural addition to ServiceComposer."
header_image: /img/posts/scatter-gather/header.jpg
tags:
- soa
- viewmodel-composition
series: view-model-composition
---

Starting [version 5.1.0](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/5.1.0), ServiceComposer natively supports [scatter/gather](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/scatter-gather.md) scenarios. Scatter/gather is supported through a fanout approach. Given an incoming HTTP request, ServiceComposer will issue HTTP requests to fetch data from downstream endpoints. Once all data has been retrieved, it is composed and returned to the original upstream caller.

The following configuration configures a scatter/gather endpoint:

```cs
public void Configure(IApplicationBuilder app, ILoggerFactory loggerFactory)
{
    app.UseRouting();
    app.UseEndpoints(builder => builder.MapScatterGather(template: "api/scatter-gather", new ScatterGatherOptions()
    {
        Gatherers = new List<IGatherer>
        {
            new HttpGatherer(key: "ASamplesSource", destinationUrl: "https://a.web.server/api/samples/ASamplesSource"),
            new HttpGatherer(key: "AnotherSamplesSource", destinationUrl: "https://another.web.server/api/samples/AnotherSamplesSource")
        }
    }));
}
```

The snippet above configures ServiceComposer to handle HTTP requests that match the `api/scatter-gather` route template. Each time a matching request is handled, ServiceComposer invokes each configured gatherer and merges their responses into a response returned to the original issuer.

The `Key` and `Destination` properties are mandatory. The key uniquely identifies each gatherer in the context of a specific request. The destination is the URL of the downstream endpoint to invoke to retrieve data.

## Customizing downstream URLs

If the incoming request contains a query string, its values are automatically appended to downstream URLs as is, and the same applies to request headers by default. It is possible to override the query string behavior by setting the `DownstreamUrlMapper` delegate as presented in the following snippet:

```cs
public void Configure(IApplicationBuilder app, ILoggerFactory loggerFactory)
{
    app.UseEndpoints(builder => builder.MapScatterGather(template: "api/scatter-gather", new ScatterGatherOptions()
    {
        Gatherers = new List<IGatherer>
        {
            new HttpGatherer("ASamplesSource", "https://a.web.server/api/samples/ASamplesSource")
            {
                DestinationUrlMapper = (request, destination) => destination.Replace(
                    "{this-is-contextual}",
                    request.Query["this-is-contextual"])
            }
        }
    }));
}
```

The same approach can be used to customize the downstream URL before it is invoked. Other [configuration options allow you to customize how headers are forwarded](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/scatter-gather.md#forwarding-headers). 

## Data format

ServiceComposer scatter/gather support works with JSON data by default. Gatherers must return an `IEnumerable<JsonNode>`. By default, gatherers assume that the downstream endpoint [results can be converted into a `JsonArray`](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/scatter-gather.md#data-format). With some configuration and customization, it's possible to support downstream endpoints using separate formats.

### Transforming returned data

If there is a need to transform downstream data, it's possible to create a custom gatherer and override the `TransformResponse` method:

```cs
public class CustomGatherer : Gatherer
{
    public CustomGatherer(string key, string destination) : base(key, destination) { }
    
    protected override Task<IEnumerable<JsonNode>> TransformResponse(HttpResponseMessage responseMessage)
    {
        // retrieve the response as a string from the HttpResponseMessage
        // and parse it as a JsonNode enumerable.
        return base.TransformResponse(responseMessage);
    }
}
```

### Taking control of the downstream invocation process

If transforming returned data is not enough, it's possible to take full control over the downstream endpoint invocation by overriding the `Gather` method:

```cs
public class CustomGatherer : Gatherer
{
    public CustomGatherer(string key, string destination) : base(key, destination) { }

    public override Task<IEnumerable<JsonNode>> Gather(HttpContext context)
    {
        // by overriding this method we can implement custom logic
        // to gather the responses from the downstream service.
        return base.Gather(context);
    }
}
```

## Conclusion

ServiceComposer had always supported scatter/gather, but without a proper feature, it required excessive manual, repetitive configuration, which made no sense at all. The new feature brings everything together, streamlining the approach with a lean, straightforward configuration-first approach that also supports [Microsoft.Extensions.Configuration](https://learn.microsoft.com/en-us/dotnet/core/extensions/configuration).

---

Photo by <a href="https://unsplash.com/@vladhilitanu?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Vlad Hilitanu</a> on <a href="https://unsplash.com/photos/people-holding-miniature-figures-1FI2QAYPa-Y?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
