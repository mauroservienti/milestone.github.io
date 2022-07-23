---
layout: post
author: Mauro Servienti
title: "Distributed systems evolution: topology changes"
synopsis: "Evolving distributed systems architecture is challenging. It's not only a matter of evolving message contracts or processes state. Surprisingly, deployments can play a role in creating more challenges."
header_image: /img/topology-changes/header.jpg
enable_mermaid: true
series: distributed-systems-evolution
tags:
- distributed-systems
---

I wrote about the [challenges](https://milestone.topics.it/2022/06/11/distributed-systems-evolution-challenges.html) of evolving distributed systems, options to [evolve message contracts](https://milestone.topics.it/2022/07/04/messages-evolution.html), and details about [changing processes state](https://milestone.topics.it/2022/07/12/processes-state-evolution.html).

There is more, and it is more subtle.

## Topology changes

The system is happily running in production. There are service level agreements (SLA) in place, and operations folks notice that the [critical time](https://docs.particular.net/monitoring/metrics/definitions#metrics-captured-critical-time) of a bunch of messages is consistently near the defined SLA or, sometimes, a bit above the threshold. In simple terms, messages are taking more time than allowed. Users will complain, and they'll have a right to do so.

The most straightforward move would be to scale out the affected endpoints. Multiple copies of the same endpoint will be using the competing consumer approach and distributing the load across different instances. However, that might be a palliative, and we should try to ask ourselves if we're kicking the can.

By scaling out instances, we're accepting more load, but at the same time, we're still equally distributing the load. If the load increases, we'll be in the same situation again.

The solution is to split the "offending" endpoints, separating the handlers causing the SLA violations from the others.

For example, imagine we have a Sales endpoint that processes payments, post-payment operations, refunds, frauds, and cancellations.

After some analysis, it's clear that post-payment operations are the culprit. They consume a lot of resources, and when that consumption happens simultaneously with other operations, the system cannot meet the defined SLAs.

What we can do is create a Sales.PostPaymentProcessing endpoint and move the related message handlers there.

However, that's a routing configuration breaking change. Senders must be updated, which must happen synchronously with the deployment of the new endpoint. Otherwise, new messages will end up in the wrong destination queue. A similar problem applies to in-flight messages. They'll end up in the Sales input queue where the expected handlers won't be there.

The first option is to split the endpoint but keep the post-payment operations-related handlers in both endpoints for a while. That will cause some SLA violations and, at the same time, guarantee the time to update senders' routing configurations.

The second option is to modify the Sales endpoint to forward post-payment-related messages to the new endpoint. If you're using NServiceBus, the pipeline is the perfect place to introduce such an extension. We can design a message forwarding feature that forwards some messages to another destination instead of processing them in the Sales endpoint. In the NServiceBus documentation, there is a [forwarding sample](https://docs.particular.net/samples/routing/message-forwarding/) showing how to implement that type of extension point. The example doesn't exactly demonstrate what we need, but it should be reasonably easy to adapt. If you have any issues, let me know.
 
The third option is to introduce a triage endpoint. We will convert Sales into the triage endpoint and add two more endpoints to handle messages: Sales.PostPaymentProcessing and Sales.Operations, for example. The triage endpoint masquerades the processing endpoints topology to senders. Using a forwarding technique, the triage endpoint inspects incoming messages and then redirects them to the processing endpoint.

The second option is designed to be temporary. We will modify senders to properly route messages to the new endpoint and remove the forwarding logic. On the contrary, the third option comes with the goal of not breaking senders.

### Publish/subscribe caveats

Everything presented so far applies well to message sending. Pub/sub is a bit trickier and what we do depends more on the underlying infrastructure. Let's say that we're deploying on AWS (Amazon Web Services), and we are using SQS (Simple Queue Service) and SNS (Simple Notification Service).

Let's imagine that an event is responsible for triggering post-payment operations. Once users pay, the payment processor publishes a `PaymentCompleted` event. Based on that, Sales subscribed to the event and started the post-payment operations. Visually, it's like the following diagram:

<div class="mermaid">
graph LR
    P[Publisher] --> T[PaymentCompleted - SNS Topic]
    T --> S1[Sales - subscription]
    S1 -->Q1[Sales - SQS input queue]
</div>

As soon as we deploy the new endpoint, it'll create a new subscription:

<div class="mermaid">
graph LR
    P[Publisher] --> T[PaymentCompleted - SNS Topic]
    T --> S1[Sales - subscription]
    S1 -->Q1[Sales - SQS input queue]
    T --> S2[Sales.PostPaymentProcessing - subscription]
    S2 -->Q2[Sales.PostPaymentProcessing - SQS input queue]
</div>

The Sales endpoint receives the `PaymentCompleted` event and Sales.PostPaymentProcessing too. That will cause duplicate processing.

As we discussed, we need to keep the message handlers in the Sales endpoint to process in-flight messages: those sitting in the input queue and those sent before we apply the changes. But we must avoid getting new messages.

To achieve that, we need to delete the Sales subscription to the SNS topic and modify the Sales endpoint configuration to stop subscribing to the `PaymentCompleted` event while keeping the message handler.

Note that if you use NServiceBus, it will recreate the deleted subscription every time the endpoint restarts. To prevent that, the [`AutoSubscribe` feature comes with the option to disable subscriptions for specific events](https://docs.particular.net/nservicebus/messaging/publish-subscribe/controlling-what-is-subscribed?version=core_8#automatic-subscriptions-exclude-event-types-from-auto-subscribe). Thanks, [Tim](https://timbussmann.github.io/), for the reminder.

## Conclusion

Evolving a system, it's not only a matter of updating contracts and interfaces or upgrading data structures. Changes, like the topology once, can break the system's backward compatibility or alter the system's behaviors. As with all things distributed systems, it's essential to start by analyzing the desired changes impact on message senders and publishers, recipients and subscribers, and the infrastructure.

---

Photo by <a href="https://unsplash.com/@dmjdenise?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Denise Jans</a> on <a href="https://unsplash.com/@dmjdenise?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
  