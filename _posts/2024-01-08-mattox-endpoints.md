---
layout: post
title: "Mattox: simple, pre-configured NServiceBus endpoints"
author: Mauro Servienti
synopsis: "NServiceBus endpoints support only code-based configuration, which is handy and not always friendly at the same time. But what if we could plug in the superb Microsoft configuration extensions to configure NServiceBus endpoints?"
header_image: /img/posts/mattox-endpoints/header.jpg
tags:
- nservicebus
- messaging
reviewed-by: [kbaley, tmasternak]
---

[Matt Mattox](https://en.wikipedia.org/wiki/Matt_Mattox) was one of my favorite modern jazz ballet teachers. In the early 90s, I had the pleasure to spend a week at one of his workshops in Venice. One of the critical aspects of his dance style was isolation. I still remember this short exercise/choreography that finished with everyone screaming "Stop!" in a particular position. It was about isolating movements of body parts, stripping away all the gimmicks, and reducing it to its minimalist essence.

[Mattox.NServiceBus](https://github.com/mauroservienti/Mattox.NServiceBus) is all about simplicity and NServiceBus endpoint configuration. With Mattox.NServiceBus, if we need to set up and start a new NServiceBus endpoint using Amazon SQS as the transport, we can do the following:

```c#
var endpoint = new AmazonSqsEndpoint("my-endpoint");
var endpointInstance = await endpoint.Start();
```

If we're using Microsoft hosting, the above code will look like the following:

```c#
Host.CreateDefaultBuilder()
    .UseNServiceBus(ctx => new AmazonSqsEndpoint(ctx.Configuration))
    .Build();
```

At runtime, the [Mattox.NServiceBus.AmazonSQS](https://github.com/mauroservienti/Mattox.NServiceBus.AmazonSQS) endpoint will look for configuration settings through the provided [`IConfiguration` object instance](https://learn.microsoft.com/en-us/dotnet/core/extensions/configuration).

For example, we can express the endpoint configuration using a JSON file similar to the  following:

```json
{
  "NServiceBus": {
    "EndpointConfiguration": {
      "EndpointName": "my-endpoint",
      "Auditing": {
        "Enable": "true"
      },
      "Installers": {
        "Enable": "true"
      },
      "Recoverability": {
        "Delayed": {
          "NumberOfRetries": 2,
          "TimeIncrease": "00:00:25"
        }
      }
    }
  }
}
```

With the above configuration, the endpoint name will be "my-endpoint," it'll have auditing enabled using the default "audit" queue, installers will configure the required infrastructure at runtime, and delayed retries will retry messages two times instead of the default three, with a 25 second time increase between them.

Given that the Microsoft configuration engine supports a variety of sources, we can use the above configuration via environment variables in a Docker container by defining the following variables in the Dockerfile:

```Dockerfile
env NServiceBus:EndpointConfiguration:EndpointName="my-endpoint"
env NServiceBus:EndpointConfiguration:Auditing:Enable=True
env NServiceBus:EndpointConfiguration:Installers:Enable=True
env NServiceBus:EndpointConfiguration:Recoverability:Delayed:NumberOfRetries=True
env NServiceBus:EndpointConfiguration:Recoverability:Delayed:TimeIncrease="00:00:25"
```

> I never remember if, in Linux, the `:` (colon) must be replaced with `__` (double underscores)—the above works in macOS, FWIW. I think Microsoft recommends `__` these days as it works in MacOS, Windows, and Linux.

We can also mix and match various configuration sources to take advantage of the flexibility of the configuration engine.

## Sensible defaults

The available Mattox endpoints, at the time of this writing, [AmazonSQS](https://github.com/mauroservienti/Mattox.NServiceBus.AmazonSQS) and [RabbitMQ](https://github.com/mauroservienti/Mattox.NServiceBus.RabbitMQ), come with sensible defaults set out of the box. For example, the serializer is the `System.Text.Json` serializer. For RabbitMQ, the default topology is the conventional one, and the endpoint will use quorum queues. Both values can be overwritten either via code or configuration:

```json
{
  "NServiceBus": {
    "EndpointConfiguration": {
      "EndpointName": "my-endpoint",
      "Transport": {
        "QueueType": "classic",
        "RoutingTopology": "conventional"
      }
    }
  }
}
```

The above JSON configuration file configures the RabbitMQ endpoint to use the conventional routing topology (the default and thus redundant in the above example) and classic queues instead of the default quorum ones.

## Further customization

Not everything can be configured through string values, though. If that's the case, Mattox allows accessing the usual NServiceBus code-based configuration in a couple of ways.

For specific customizations, the endpoint API exposes several options. For example, the following snippet allows replacing the default serializer with the Json.NET one:

```c#
var endpoint = new AmazonSqsEndpoint("my-endpoint");
endpoint.ReplaceDefaultSerializer<NewtonsoftJsonSerializer>();
var endpointInstance = await endpoint.Start();
```

Or we can customize the transport by using the following code:

```c#
var endpoint = new AmazonSqsEndpoint("my-endpoint");
endpoint.CustomizeTransport(transport =>
{
   // apply transport settings
});
var endpointInstance = await endpoint.Start();
```

The transport customization delegate is invoked after applying any `IConfiguration`-defined transport setting.

If the need is to apply changes to the whole endpoint configuration before starting it, we can preview the `EndpointConfiguration` instance before it's used:

```c#
var endpoint = new AmazonSqsEndpoint("my-endpoint");
endpoint.PreviewConfiguration(endpointConfiguration =>
{
   // Apply the needed changes
});
var endpointInstance = await endpoint.Start();
```

As for the transport customization delegate, the endpoint configuration one is invoked after applying any `IConfiguration`-defined setting.

At the moment, Mattox endpoints are primarily experiments, so I've only implemented support for RabbitMQ and AmazonSQS, which are different enough to validate the approach.

> Let me know in the comments below if that's something you might be interested in using, and I'll bring it to completion and publish it to NuGet.

## That's _not_ all, folks!

What if it would be possible to do something like the following:

```dockerfile
FROM NServiceBus.Endpoints:9 AS base

# use a dedicated image to build and publish
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=build /app .

ENV NServiceBus__EndpointName=MyEndpointName
ENV NServiceBus__Transport=AmazonSQS

# Transport specific settings
ENV AWS_ACCESS_KEY_ID=<access key ID>
ENV AWS_SECRET_ACCESS_KEY=<secret access key>
ENV AWS_REGION=<region>
```

> Let me know in the comments below what you think about this option too.

The above Dockerfile defines a containerized endpoint, where everything comes from the `base` layer, and the user code can be limited to message handlers and sagas.

The endpoint configuration is expressed via environment variables, including transport selection, persistence, serialization, and other NServiceBus options.

[Tomek](https://twitter.com/Masternak) and I built a far-from-being-production-ready spike to demonstrate how it could work.

With the above-presented approach, other than greatly simplifying NServiceBus endpoint development, we could create custom base images improving project governance by sharing a pre-configured image with all the dials and knobs set as required by the environment.

## Why?

Why not stick with the regular, code-based NServiceBus configuration? In the end, the `EndpointConfiguration` class has plenty of properties and methods to set all the dials and knobs of the NServiceBus endpoint.

A good reason to offer only a code-based configuration option is that it's way easier to evolve. Deprecating things in configuration files and schema is error-prone and undiscoverable. It's a runtime thing leaving traces only in logs. Users will have to pay attention to logs to realize that a configuration option they use will not be supported anymore, and they'll have to transition to something else. Compare that with an obsolete warning at compile-time, and you get a good idea of why code configuration is superior.

However, code-based configuration comes with a few downsides too:

- Changing the code is the only way to change a configuration value. That means some production-context-dependent values require developers' intervention.
- The above leads users and organizations to craft their mechanism to map file-based configuration to a code-based one.

Mattox endpoints present themselves as the best of both worlds! They use the de facto standard Microsoft Configuration extension to create the mapping that bridges all the supported configuration sources to the NServiceBus endpoint code-based configuration.

---

Photo by <a href="https://unsplash.com/@darthxuan?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Xuan Nguyen</a> on <a href="https://unsplash.com/photos/three-woman-standing-on-stage-on-black-background-KcWIsfbBfa4?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
