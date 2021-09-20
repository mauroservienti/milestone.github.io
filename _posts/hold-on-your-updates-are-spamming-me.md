---
layout: post
header_image: /img/posts/hold-on-your-updates-are-spamming-me/header.jpg
title: "Hold on! Your updates are spamming me"
slug: hold-on-your-updates-are-spamming-me
author: Mauro Servienti
synopsis: ""
tags:
- sagas
- delayed deliveries
---

["Update me, please"](https://milestone.topics.it/2021/08/03/update-me-please.html) shows how to design a notification infrastructure in a distributed system. It's a basic design that I've successfully used myself multiple times. It comes with a limitation, though. Let's have a look at the following scenario:

> An area manager is responsible for a geographical area and all the retail shops in the assigned area. Area managers are interested in receiving notifications. For example, when one retail shop performs one or more actions they care about, or a specific event occurs, e.g., a retail shop runs out of stock or places a fulfillment order for a particular item.

In the presented scenario, an area manager might supervise tens of retail shops. If we were to design the notification infrastructure as explained in the mentioned article, we'd end up spamming the inculpable manager. They subscribed to what they were interested, and nothing more. However, the system design was causing a notification message for every meaningful event. Such a design with tens of shops can easily lead to hundreds if not thousands of notification messages.

## Digests

Near real-time notifications might be helpful in some scenarios. In many cases, though, we can get along with summaries. A daily or a weekly digest with a list of things that happened since the last digest is more than enough to satisfy our desire to be updated.

We can design a notification infrastructure supporting digests-type of subscriptions on top of what we already have. Let's start by extending the subscription concept to include what type of grouping we need:

```csharp
public record Subscription(string Id, NotificationFormat Format, NotificationFrequency Frequency);
```

With the `NotificationFrequency` enumeration that looks like:

```csharp
enum NotificationFrequency
{
   Immediate,
   DailyDigest,
   WeeklyDigest
}
```

At this point, things get tricky. In ["Update me, please"](https://milestone.topics.it/2021/08/03/update-me-please.html), we concluded that the responsibility for handling events, through regular message handlers, to turn into notifications belongs to business services. Those handlers use IT/Ops facilities, like the presented `INotificationService`, and are hosted by the notification infrastructure managed by IT/Ops.

Dealing with digests is not the responsibility of a business service. They take care of formatting the notification and nothing else. To minimize the impact of the digest feature on business services, we need to "hide" the feature in the notification infrastructure. Luckily the way we designed allows that. The last bit of the presented notification handler is something like:

```csharp
var notifications = subscriptions.Select(s => new Notification()
{
    Subscription = s,
    Content = formattedNotifications[s.Format]
});
await notificationService.Dispatch(notifications);
```

At dispatch time, the notification service will inspect incoming notifications, and based on the `NotificationFrequency` value, will decide how to handle them: Send immediately or store for later delivery.

### How do I subscribe?

Before looking at the "store for later delivery" details, we need to discuss something we have neglected so far: how does someone subscribe to a notification?

The first thing we need is a notifications database. The system needs to present a list of available notifications. We can build such a database in many ways. One of the many options is by using reflection. The business service that owns the events users can subscribe can decorate those events using something similar to the following:

```csharp
[Notification( 
   Id: "procurement/purchase-order-created",
   Name: "Purchase order created",
   Description: "Raised when a retail shop creates a purchase order.")]
interface IPurchaseOrderCreated
{
    string OrderId{ get; }
    string SupplierId{ get; }
    string DepartmentId{ get; }
}
```

Event classes or interfaces are deployed to the notification infrastructure alongside the notification handler. Notification infrastructure hosts can, at startup time, scan their deployment directories looking for types decorated with the presented attribute. Inspected types and attributes details constitute the notifications database—it's up to the notification infrastructure to decide how to store it. Once the notifications database is ready, the system can present users with a list of subscribable notifications. At subscribe time, users select the frequency for each of the subscribed notifications. When choosing to receive a digest, they can input digest details, if not previously done—for example, a weekly digest, every Friday at 10 AM.
Saving their subscriptions settings will cause a digest notification saga to start, if not already running.

> More information about sagas are available in the [official NServiceBus documentation](https://docs.particular.net/nservicebus/sagas/) and the [online saga tutorial](https://docs.particular.net/tutorials/nservicebus-sagas/).

The first thing we need is a message to kick off the saga:

```csharp
class StartWeeklyDigest
{
   public string SubscriberId{ get; set; }
   public DayOfWeek DayOfWeek{ get; set; }
   public string Time{ get; set; }
}
```

When starting a digest, we need the subscriber and the schedule settings. In this case, the day of the week and the time when users like to have the digest delivered. In lack of a better type, for example, a `Time` .NET type, we're using a simple string to represent the time of the day. Your mileage might vary, depending on the scheduling options offered to users.

The required data are stored in the saga data. We keep the scheduling settings too because the system could use a subsequent `StartWeeklyDigest` message to update the digest scheduling. By storing current settings, we can check if the configuration needs to change.

```csharp
class WeeklyDigestData : ContainsSagaData
{
   public string SubscriberId{ get; set; }
   public DayOfWeek DayOfWeek{ get; set; }
   public string Time{ get; set; }
}

class WeeklyDigestSaga : 
   Saga<WeeklyDigestData>,
   IAmStartedBy<StartWeeklyDigest>
{
    protected override void ConfigureHowToFindSaga(SagaPropertyMapper<WeeklyDigestData> mapper)
    {
        mapper.ConfigureMapping<StartWeeklyDigest>(m => m.SubscriberId)
            .ToSaga(s => s.SubscriberId);
    }

    public Task Handle(StartWeeklyDigest message, IMessageHandlerContext context)
    {
        var firstOccurrenceDate = ... // calculate first occurrence using message properties
        Data.FirstOccurrence = firstOccurrenceDate;
        return RequestTimeout(context, firstOccurrenceDate, new DispatchWeeklyDigestFirstOccurrence());
    }
}
```

The `DispatchWeeklyDigestFirstOccurrence` timeout message is an empty class; we don't need to carry any state. To handle a timeout, we need to change the saga definition in the following way:

```csharp
class WeeklyDigestSaga : 
   Saga<WeeklyDigestData>,
   IAmStartedBy<StartWeeklyDigest>,
   IHandleTimeouts<DispatchWeeklyDigestFirstOccurrence>
```

Which forces the implementation of the following method:

```csharp
public Task Timeout( DispatchWeeklyDigestFirstOccurrence message, IMessageHandlerContext context)
{
    //query the notifications database for notifications to dispatch
    //or send a message to offload the task to a separate handler

    //schedule regular weekly deliveries
    var next = Data.FirstOccurrence.AddDays(7);
    return return RequestTimeout(context, next, new DispatchWeeklyDigest());
}
```

Nothing fancy, the saga when handling the timeout selects and deletes, or marks them as dispatched, notifications to deliver from the database where they were stored previously.

It's also worth noticing that the above snippet requires implementing the `IHandleTimeouts<DispatchWeeklyDigest>` interface, whose implementation will be very similar to the one presented above.

### A note about offloading delivery to a separate handler

In the above snippet, I left this comment:

> query the notifications database for notifications to dispatch or send a message to offload the task to a separate handler

Picking an option might not be easy. The [official documentation](https://docs.particular.net/nservicebus/sagas/#accessing-databases-and-other-resources-from-a-saga) states the following:

> The main reason for avoiding accessing data from external resources is possible contention and inconsistency of saga state. Depending on persister, the saga state is retrieved and persisted with either pessimistic or optimistic locking. If the transaction takes too long, it's possible another message will come in that correlates to the same saga instance. It might be processed on a different (concurrent) thread (or perhaps a scaled out endpoint) and it will either fail immediately (pessimistic locking) or while trying to persist the state (optimistic locking). In both cases the message will be retried.

The presented reason is a technical and infrastructure reason. I have a preference based on the single responsibility principle (SRP). It's not the role of the saga to dispatch notifications; its function is to decide to deliver.

### A note about notifications formats

In ["Update me, please"](https://milestone.topics.it/2021/08/03/update-me-please.html) to retrieve formatted notifications, we use the following approach:

```csharp
var request = new HttpRequestMessage(HttpMethod.Get, requestUri);
request.Headers.Add("Accept", $"NotificationFormat/{format}");

var response = await client.SendAsync(request);
var formattedNotification = await response.Content.ReadAsStringAsync();
```

The composition API returns a formatted response. What if we wanted a different format if the notification should be immediately dispatched or included in a digest? A digest is a sort of summary, and thus we might need a summary style notification. If this is the case, we could tweak the composition API to return multiple styles—for example, a full and a formatted summary notification.

## Conclusion

Sagas are a multi-purpose tool. We can use them to build long-running business processes, such as handling the lifecycle of an order, or we can use them for recurring things delivering a digest to subscribers. Sagas are probably a good fit whenever a business process we're designing is long-running or needs to deal with time. If you'd like to know more about the relationship between sagas and the passage of time, [I delivered a webinar on the topic](https://particular.net/webinars/got-the-time).
