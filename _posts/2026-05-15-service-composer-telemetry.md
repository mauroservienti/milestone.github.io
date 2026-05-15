---
layout: post
title: "ServiceComposer 5.2 OpenTelemetry support"
author: Mauro Servienti
synopsis: "OpenTelemetry tracing is one of those things you don't want until you need it. With version 5.2, ServiceComposer integrates with ASP.NET tracing adding relevant information to the ASP.NET spans"
header_image: /img/posts/service-composer-telemetry/header.jpg
tags:
- soa
- viewmodel-composition
---

This is going to be a quick one—ServiceComposer [5.2.0](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/releases/tag/5.2.0) introduced support for OpenTelemetry.

More details on the [OpenTelemetry documentation page](https://github.com/ServiceComposer/ServiceComposer.AspNetCore/blob/master/docs/open-telemetry.md).

Tracing can be enabled for composition or scatter/gather:

```csharp
builder.Services.AddOpenTelemetry()
    .WithTracing(b => b
       .AddSource("ServiceComposer.AspNetCore.ViewModelComposition")
       .AddSource("ServiceComposer.AspNetCore.ScatterGather"));
```

Each `ICompositionRequestsHandler` execution produces a child span of the ASP.NET Core HTTP server span. When a handler raises an event via `context.RaiseEvent<TEvent>()`, the event handling produces a child span of the raising handler's span. When a handler or event handler throws, the span sets `ActivityStatusCode.Error`, adds tags, and an exception span event following the [OTel exception conventions](https://opentelemetry.io/docs/reference/specification/trace/semantic_conventions/exceptions/).

On a smaller scale, when using [scatter/gather](https://milestone.topics.it/2026/03/12/scatter-gather.html), each `IGatherer` execution produces a child span of the ASP.NET Core HTTP server span. When a gatherer throws, the span sets `ActivityStatusCode.Error` with the same `otel.status_code`, `otel.status_description` tags, and exception span event as the composition process does.

## Conclusion

I've wanted OpenTelemetry support for a very long time, and finally it landed.

---

Photo by <a href="https://unsplash.com/@americanaez225?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Arturo Añez</a> on <a href="https://unsplash.com/photos/stock-chart-indicates-growth-and-potential-profit-Q_vhJv5im-8?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
