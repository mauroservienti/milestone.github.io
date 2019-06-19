---
typora-copy-images-to: ..\img\posts\i-built-a-thing-well-two
typora-root-url: ..
layout: post
header_image: /img/posts/i-built-a-thing-well-two/header.jpg
title: "I built a thing, well...two."
author: Mauro Servienti
synopsis: "NServiceBus has a configurable routing engine whose role is to define where messages should be routed when sent. The routing engine is configured along with the endpoint, that might not be the most comfortable solution. Is there anything we can do about it?"
tags:
- NServiceBus
- Routing
- Conventions
---

As you may already know, I work for [Particular Software](https://particular.net/), the makers of NServiceBus. [Our documentation defines NServiceBus as follows](https://docs.particular.net/nservicebus/):

>NServiceBus is the heart of a distributed system and the Particular Service Platform. It helps create systems that are scalable, reliable, and flexible.
>
>At its core, NServiceBus works by routing *messages* between *endpoints*. Messages are plain C# classes that contain meaningful data for the business process that is being modeled.

This post is focused on the routing part. Well, in the end not only on the routing, but routing was the inception of everything. A message in NServiceBus is a plain old C# class, like the following:

```csharp
public class ProcessOrder
{
    public int OrderId { get; set; }
}
```

To send that message the following code is more than enough:

```csharp
await endpoint.Send(new ProcessOrder { OrderId = 15 });
```

Hold on, where is the message sent? This is a very good question, and here is when routing comes in to play. When the send operation is performed the endpoint will look in the defined routing table to determine the destination of a message. To configure the routing table the following code can be used:

```csharp
var endpointConfiguration = new EndpointConfiguration("my-endpoint-name");
var transport = endpointConfiguration.UseTransport<SomeTransport>();

var routing = transport.Routing();
routing.RouteToEndpoint(
    messageType: typeof(ProcessOrder),
    destination: "Sales");

var endpoint = await Endpoint.Start(endpointConfiguration);
```

The above code snippet configures the routing engine building what is called the routing table.

## So far, so good. What's problem?

There isn't any, really. I struggle in remembering to update the routing configuration whenever I add a new message to the project I'm working on. Generally, what happens is:

-  The message class is created
- The code is modified to send the new message type

To then discover at runtime, or test-time, that I forgot about the routing configuration for the new message.

I looked around and realized that the problem is not different from the ASP.Net MVC routing configuration. They introduced attributes based routing for different reasons, and at the same time alleviated the exact same problem I face all the times. So why not allow developers to do something like:

```csharp
[RouteTo("Sales")]
public class ProcessOrder
{
    public int OrderId { get; set; }
}
```

And replace the routing configuration as follows:

```csharp
var endpointConfiguration = new EndpointConfiguration("my-endpoint-name");
endpointConfiguration.UseTransport<SomeTransport>();

endpointConfiguration.UseAttributeRouting();

var endpoint = await Endpoint.Start(endpointConfiguration);
```

At endpoint start time the attribute routing feature kicks in and automatically configure the routing table for all the messages (and commands) that have the `RouteTo` attribute applied.

> ~~Note: The `EnableAttributeRouting` will soon be renamed to `UseAttributeRouting`~~ renamed in v0.0.5.
>
> For more information on this little community feature head to: <https://github.com/mauroservienti/NServiceBus.AttributeRouting>

## I got carried away...

While I was there implementing the attribute routing feature my dear colleague [Mike](https://twitter.com/Wolfbyte) suggested me that I could have extended that by adding attribute based conventions.

> Refer to the NServiceBus documentation about [unobtrusive mode](https://docs.particular.net/nservicebus/messaging/unobtrusive-mode) for more details about conventions.

I'm a big fan of conventions, however conventions might be hard to maintain and keep in sync in large projects. Unless you could do something like:

```csharp
[Command]
public class ProcessOrder
{
    public int OrderId { get; set; }
}
```

And when configuring the endpoint something like:

```csharp
var endpointConfiguration = new EndpointConfiguration("my-endpoint-name");
endpointConfigration.UseAttributeConventions();
```

> For more information on this other feature head to: <https://github.com/mauroservienti/NServiceBus.AttributeConventions>

What I find very nice is the result when the two features are combined:

```csharp
[Command, RouteTo("Sales")]
public class ProcessOrder
{
    public int OrderId { get; set; }
}
```

I personally find it very expressive.

## Conclusion

NServiceBus is a powerful framework, with a lot of extensibility points. By crafting those two little things I just scratched the surface. Hopefully there will be more. In the meantime, if you want to give a try to the features just head to their GitHub repositories and follow the very simple instructions there. Do not hesitate to raise issues in case you have any problem or any suggestion.

---

Header image: Photo by [Rosie Kerr](https://unsplash.com/@rosiekerr?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/craft?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)

