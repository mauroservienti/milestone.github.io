---
layout: post
header_image: /img/posts/update-me-please/header.jpg
title: "Update me, please"
author: Mauro Servienti
synopsis: "We're so used to notifications that we probably never stopped to think about how to implement them. It might be trivial at first glance. However, in a distributed system, we might face more challenges requiring techniques we don't expect when implementing a notifications infrastructure."
tags:
- SOA
- Distributed systems
- Notifications
---

Users utilize the system daily. They rely on notifications and a home page that works like a personal dashboard to keep up with what they do and their pending tasks. The home page dashboard and the notification system are good enough tools for users' productivity. However, users are isolated in silos. They have no idea what other users are doing, their tasks, and their status. The lack of visibility is particularly compelling for the organization management, which needs this type of bird-eye view to understand what's happening and how the organization is progressing.

The system builds on top of an event-driven architecture. Most service-oriented architecture (SOA) concepts are in place, and service boundaries are solidly defined. Such a well-designed system allowed the organization to benefit from polyglot technological choices; different services use different technologies to fulfill their requirements. Some of them use relational databases and the Microsoft stack, and some others use no-SQL databases and, for example, PHP.

Those polyglot technological choices and the service-oriented architecture come with some challenges. Service boundaries, and the inherent differences in technical preferences, make it harder to define and fulfill a data set that can provide a much-needed bird-eye view.

Some users need a point-in-time update about changes in the system.

Let's imagine that the system allows, among many other things, to create purchase orders: that happens each time a department in the organization purchases from a supplier. Whenever that happens, the following event is published by the responsible service:

```csharp
interface IPurchaseOrderCreated
{
    string OrderId{ get; }
    string SupplierId{ get; }
    string DepartmentId{ get; }
}
```

Based on the requirement above, we need to update interested users about the recent change.

> to keep things simple, we'll ignore the subscribe to/unsubscribe from notifications and assume a predetermined set of users will receive the notifications.

Before getting to the "how to," let's dissect a bit the "what" part of the problem. What do we need to do? At the very minimum, we need to:

1. collect events about things happening in the system
2. for each event, understand if there are subscribed users
3. for each subscribed user, detect which notification format they would like to receive, e.g., text message, email, or web/push notification
4. prepare and deliver one or more notifications

To collect events happening in the system, we need to subscribe to those. The subscriber will be the notification service that will then be responsible for performing all the other mentioned steps.

However, there's an issue. By looking at the mentioned steps, it's probably clear that the subscribed service needs to know the events types. Steps one and four need that. Collecting events requires being subscribed, which requires knowing the event type. Similarly, preparing the notification, given that we're using thin events with IDs only, requires enriching those events, which, indeed, requires knowing the events.

## Coupling is just around the corner

If we were to bake the required knowledge into the notification service, we'd end up coupling the entire system to it. We don't want that.

We can leverage the logical boundaries vs. physical deployment difference mentioned in ["Don't keep a saga in both camps"](link-to-post), to understand better who is responsible for what.

Assuming procurement owns and publishes the `IPurchaseOrderCreated` event, it is the best candidate to fulfill steps one and four mentioned above. Procurement can do that by deploying a message handler to the notification service. Procurement is the logical owner, and the notification service is the physical host.

Let's imagine that the system relies on brokered transport like Azure Service Bus, RabbitMQ, or AWS SNS and uses [NServiceBus](https://docs.particular.net/nservicebus/). Procurement can create and deploy a message handler like the following:

```csharp
namespace Procurement.Notifications
{
   class PurchaseOrderCreatedHandler : IHandleMessages<IPurchaseOrderCreated>
   {
      public Task Handle( IPurchaseOrderCreated msg, IMessageHandlerContext ctx )
      {
         return Task.CompletedTask;
      }
   }
}
```

From the logical boundaries perspective, procurement owns the above message handler. However, the deployment process makes it so that the package ends up in the notification service runtime directory. The NServiceBus [assembly scanning logic](https://docs.particular.net/nservicebus/hosting/assembly-scanning) takes care of the rest. When the notification service starts, the NServiceBus transport seam will create a subscription for the handled message at runtime and will invoke the handler as expected.

## IT/Ops facilities 

A notification service is not a genuine business service in SOA terminology. It's an IT/Ops kind of service that provides facilities to business services in the system. In the case of this article, the notification service offers business services a way to deliver notifications. To do so, it ships a notifications package that business services can use to interact with it. The notifications package is composed of an `INotificationService` interface that looks like the following:

```csharp
interface INotificationService
{
   Task<IEnumerable<Subscription>> GetSubscriptionsFor(string eventId);
   Task Dispatch(IEnumerable<Notification> notifications);
}
Users utilize the system daily. They rely on notifications and a home page that works like a personal dashboard to keep up with what they do and their pending tasks. The home page dashboard and the notification system are good enough tools for users' productivity. However, users are isolated in silos. They have no idea what other users are doing, their tasks, and their status. The lack of visibility is particularly compelling for the organization management, which needs this type of bird-eye view to understand what's happening and how the organization is progressing.

The system builds on top of an event-driven architecture. Most service-oriented architecture (SOA) concepts are in place, and service boundaries are solidly defined. Such a well-designed system allowed the organization to benefit from polyglot technological choices; different services use different technologies to fulfill their requirements. Some of them use relational databases and the Microsoft stack, and some others use no-SQL databases and, for example, PHP.

Those polyglot technological choices and the service-oriented architecture come with some challenges. Service boundaries, and the inherent differences in technical preferences, make it harder to define and fulfill a data set that can provide a much-needed bird-eye view.

Some users need a point-in-time update about changes in the system.

Let's imagine that the system allows, among many other things, to create purchase orders: that happens each time a department in the organization purchases from a supplier. Whenever that happens, the following event is published by the responsible service:

```csharp
interface IPurchaseOrderCreated
{
    string OrderId{ get; }
    string SupplierId{ get; }
    string DepartmentId{ get; }
}
```

Based on the requirement above, we need to update interested users about the recent change.

> to keep things simple, we'll ignore the subscribe to/unsubscribe from notifications and assume a predetermined set of users will receive the notifications.

Before getting to the "how to," let's dissect a bit the "what" part of the problem. What do we need to do? At the very minimum, we need to:

1. collect events about things happening in the system
2. for each event, understand if there are subscribed users
3. for each subscribed user, detect which notification format they would like to receive, e.g., text message, email, or web/push notification
4. prepare and deliver one or more notifications

To collect events happening in the system, we need to subscribe to those. The subscriber will be the notification service that will then be responsible for performing all the other mentioned steps.

However, there's an issue. By looking at the mentioned steps, it's probably clear that the subscribed service needs to know the events types. Steps one and four need that. Collecting events requires being subscribed, which requires knowing the event type. Similarly, preparing the notification, given that we're using thin events with IDs only, requires enriching those events, which, indeed, requires knowing the events.

## Coupling is just around the corner

If we were to bake the required knowledge into the notification service, we'd end up coupling the entire system to it. We don't want that.

We can leverage the logical boundaries vs. physical deployment difference mentioned in ["Don't keep a saga in both camps"](link-to-post), to understand better who is responsible for what.

Assuming procurement owns and publishes the `IPurchaseOrderCreated` event, it is the best candidate to fulfill steps one and four mentioned above. Procurement can do that by deploying a message handler to the notification service. Procurement is the logical owner, and the notification service is the physical host.

Let's imagine that the system relies on brokered transport like Azure Service Bus, RabbitMQ, or AWS SNS and uses [NServiceBus](https://docs.particular.net/nservicebus/). Procurement can create and deploy a message handler like the following:

```csharp
namespace Procurement.Notifications
{
   class PurchaseOrderCreatedHandler : IHandleMessages<IPurchaseOrderCreated>
   {
      public Task Handle( IPurchaseOrderCreated msg, IMessageHandlerContext ctx )
      {
         return Task.CompletedTask;
      }
   }
}
```

From the logical boundaries perspective, procurement owns the above message handler. However, the deployment process makes it so that the package ends up in the notification service runtime directory. The NServiceBus [assembly scanning logic](https://docs.particular.net/nservicebus/hosting/assembly-scanning) takes care of the rest. When the notification service starts, the NServiceBus transport seam will create a subscription for the handled message at runtime and will invoke the handler as expected.

## IT/Ops facilities 

A notification service is not a genuine business service in SOA terminology. It's an IT/Ops kind of service that provides facilities to business services in the system. In the case of this article, the notification service offers business services a way to deliver notifications. To do so, it ships a notifications package that business services can use to interact with it. The notifications package is composed of an `INotificationService` interface that looks like the following:

```csharp
interface INotificationService
{
   Task<IEnumerable<Subscription>> GetSubscriptionsFor(string eventId);
   Task Dispatch(IEnumerable<Notification> notifications);
}
```

And the `Subscription` and `Notification` types could look like the following:

```csharp
public record Subscription(string Id, NotificationFormat Format);

public record Notification(Subscription Subscription, string Content);
```

> the presented snippets use the new [C# 9 record types](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/record). It's not necessary; however, it's a convenient way to define immutable types.

The only relevant thing in the presented snippets is probably the `NotificationFormat` enumeration type. It could have values like `EmailMessage`, `TextNotification`, `PushNotification`, `WebHook`, and many more depending on the business needs.

With the above in place, procurement can define the NServiceBus message handler as follows:

```csharp
namespace Procurement.Notifications
{
    class PurchaseOrderCreatedHandler : IHandleMessages<IPurchaseOrderCreated>
    {
        readonly INotificationService notificationService;
        public PurchaseOrderCreatedHandler(INotificationService notificationService)
        {
            this.notificationService = notificationService;
        }

        public async Task Handle(IPurchaseOrderCreated msg, IMessageHandlerContext ctx)
        {
            var subscriptionId = "procurement/purchase-order-created";
            var subscriptions = (await notificationService.GetSubscriptionsFor(subscriptionId)).ToArray();
            if(!subscriptions.Any())
               return;

            var formats = subscriptions.Select(s => s.Format).Distinct();
            var formattedNotifications = new Dictionary<NotificationFormat, string>();
            var client = new HttpClient();
            foreach (var format in formats)
            {
                var requestUri = $"http://composition.api/notifications/{subscriptionId}?oid={msg.OrderId}&sid={msg.SupplierId}&did={msg.DepartmentId}";
                var request = new HttpRequestMessage(HttpMethod.Get, requestUri);
                request.Headers.Add("Accept", $"NotificationFormat/{format}");

                var response = await client.SendAsync(request);
                var formattedNotification = await response.Content.ReadAsStringAsync();
                formattedNotifications.Add(format, formattedNotification);
            }

            var notifications = subscriptions.Select(s => new Notification()
            {
                Subscription = s,
                Content = formattedNotifications[s.Format]
            });
            await notificationService.Dispatch(notifications);
        }
    }
}
```

Let's analyze step by step what's happening. The first thing the handling code does is retrieve a list of subscriptions for a given event identifier. It does so through the provided notification service interface, one of the notifications infrastructure facilities. Out of all the subscriptions, it creates a separate list of all the requested formats. For each format, it invokes a [ViewModel composition API](https://milestone.topics.it/categories/view-model-composition) setting the `Accept` HTTP header to the format value. The remote API can leverage [output formatters](https://milestone.topics.it/view-model-composition/2021/04/14/please-welcome-model-binding-formatters-to-servicecomposer.html) support to serialize the response and match the requested format. Once the formatted notifications are available, it's only a matter of creating and dispatching the notifications.

> There might be a couple of issues in the presented implementation. Someone could argue that issuing HTTP calls in a loop is not ideal, even if we only perform a minimal amount of calls. The second one is that there might be a need for templates, such as email templates. Both are food for follow-up posts.

## Conclusion 

We already have all the tools we need. It's "only" a matter of understanding how to use them to achieve what we need. The crucial aspect is to know how to benefit from the logical boundaries vs. physical deployment differences. Once that's in place, all the pieces of the puzzle will slowly find their homes, and we'll be able to build a straightforward solution for our notifications requirements.

---

Photo by <a href="https://unsplash.com/@markuswinkler?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Markus Winkler</a> on <a href="https://unsplash.com/s/photos/update?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
