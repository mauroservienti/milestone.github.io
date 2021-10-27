---
layout: post
header_image: /img/posts/hey-hey-hey-its-started/header.jpg
title: "Hey hey hey it's started"
author: Mauro Servienti
synopsis: "When using NServiceBus, sometimes there is a need to perform actions when the endpoint is started. This can become cumbersome when using the .NET Core Generic Host infrastructure. NServiceBus.Extensions.EndpointStarted comes to the rescue, and allows to register a simple callback function during the endpoint configuration phase."
tags:
- nservicebus
- NServiceBus Extensions
---

From time to time I manage to find some spare time, and when that happens there's usually a long lists of things I'd like to do, one of which is coding.

> Spoiler: it's not at the top of my list ;-)

Last time it happened I [released a couple of NServiceBus extensions](https://milestone.topics.it/2019/06/19/i-built-a-thing-well-two.html) to route messages and to define message conventions using attributes (there seems to be an [interesting update](https://github.com/Particular/NServiceBus/pull/5682) coming). This time I managed to solve a much simpler problem:

> As a user I need to know when an NServiceBus endpoint is started to perform some actions.

Sounds like a trivial problem to solve, especially when self-hosting endpoints using a console application:

```csharp
public static async Task Main(string[] args)
{
    var endpointConfiguration = new EndpointConfiguration("SampleEndpoint");
    endpointConfiguration.UseTransport<LearningTransport>();
    
    var endpointInstance = await Endpoint.Start(endpointConfiguration);
    
    //here the endpoint is started, perform whatever action is needed.
}
```

So far, so good. So what's the problem?

NServiceBus supports the .NET Core generic hosting paradigm, which means that the above can be rewritten as follows:

```csharp
public static void Main(string[] args)
{
    CreateHostBuilder(args).Build().Run();
}

public static IHostBuilder CreateHostBuilder(string[] args) =>
    Host.CreateDefaultBuilder(args)
        .UseNServiceBus(context =>
        {
            var endpointConfiguration = new EndpointConfiguration("SampleEndpoint");
            endpointConfiguration.UseTransport<LearningTransport>();

            return endpointConfiguration;
        });
```

Using the generic hosting means that the endpoint lifecycle is not anymore controlled by our code. It's controlled by the generic host, which means we have no place to perform the actions we need to perform when the endpoint is started.

The easiest solution is to create an NServiceBus [Feature](https://docs.particular.net/nservicebus/pipeline/features), and register a [FeatureStartupTask](https://docs.particular.net/nservicebus/pipeline/features#feature-startup-tasks) that is invoked by NServiceBus when the endpoint is started.

## Are you kidding me?

Sounds complex, for such simple task. Hence I created a thing, I called it [NServiceBus.Extensions.EndpointStarted](https://github.com/mauroservienti/NServiceBus.Extensions.EndpointStarted). It implements a Feature and a FeatureStartupTask and allows the user code to register a simple `Func<IMessageSession, Task>` during the endpoint configuration phase:

```csharp
var endpointConfiguration = new EndpointConfiguration("SampleEndpoint");
endpointConfiguration.UseTransport<LearningTransport>();
endpointConfiguration.OnEndpointStarted(messageSession =>
{
    return Task.CompletedTask;
});
```

The `OnEndpointStarted` extension can be used also when using the generic hosting infrastructure:

```csharp
public static IHostBuilder CreateHostBuilder(string[] args) =>
    Host.CreateDefaultBuilder(args)
        .UseNServiceBus(context =>
        {
            var endpointConfiguration = new EndpointConfiguration("SampleEndpoint");
            endpointConfiguration.UseTransport<LearningTransport>();
            endpointConfiguration.OnEndpointStarted(messageSession =>
            {
                return Task.CompletedTask;
            });
            
            return endpointConfiguration;
        });
```

The package is available on NuGet as [NServiceBus.Extensions.EndpointStarted](https://www.nuget.org/packages/NServiceBus.Extensions.EndpointStarted/), and the source code on [GitHub](https://github.com/mauroservienti/NServiceBus.Extensions.EndpointStarted). As usual, raise an issue if you face any issues :-)

---

Header image: Photo by [Alex Paganelli](https://unsplash.com/@alexpaganelli?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
