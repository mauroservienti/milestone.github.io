---
layout: post
header_image: /img/posts/got-the-time/header.jpg
title: "Got the time"
author: Mauro Servienti
synopsis: "When modeling time, we can use a batch job-oriented approach. I like to define the ticking clock model, or we can flip the responsibilities and use messages for our future selves to achieve the results more efficiently and effectively. Let's see how to model time using NServiceBus sagas and messages."
tags:
- Sagas
- NServiceBus
- Timeouts
- Delayed deliveries
---

In ["I'll be back"](https://milestone.topics.it/2021/02/08/ill-be-back.html), I described a hypothetical invoicing system and, even if the system is trivial, the problem that arises when the business requirement changes. Let's review it:

> Acme Inc. issues invoices on the last day of the month. All issued invoices are due in thirty days. It seems reasonable to set the "check overdue invoices" clock to tick on the 10th of the next month. Forty days after sending invoices, Acme checks payments and acts upon overdue invoices. One day Acme changes its business model and decides to issue invoices on the same day they sell goods or services. The Acme accounting department cannot anymore rely on the forty-day rule to check for overdue invoices because by not issuing invoices regularly, invoices can be outstanding more or less every day. The Acme Operations team's simple reaction is to adjust the ticking clock's scale, and instead of ticking on the 10th of the next month, it makes it tick every day.

In the above quote, the clock's tick refers to the frequency at which a batch job to check for overdue invoices runs. In "I'll be back," the proposal is to flip the problem; instead of relying on a batch job to check for outstanding invoices, rely on a dedicated scheduled check for each issued invoices. It's as if every time the system generates an invoice, it also creates a calendar entry, 40 days in the future, to remind checking for the payment status of that invoice, and only that one.

## The lifecycle of an invoice

It's time to stop for a second and think about the invoice concept. It's easy to fall into [the user's mental model trap](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html) and identify invoices as pure static artifacts. In the end, users describe invoices as read-only set-in-stone things; an invoice, once issued, cannot be changed; to change the content of an invoice, a credit note or another invoice is needed. However, if we dig deeper, invoices have a life. Invoices can be "paid in full," can be "overdue," can be "partially paid," can even be wrong or overpaid, and can have many more behaviors, such as how they participate in regards to taxes. That said, what we could do is flipping the coin and look at invoices as workflows with many different statuses and some data.

As the reader probably knows, I work for [Particular Software](https://particular.net/), the makers of NServiceBus. In the NServiceBus world, we can use sagas to model workflows type of scenarios. The minimum required data set is the invoice number in the most straightforward invoicing procedure, which I'm assuming is unique.

> The invoice number might not be unique. For example, in Italy, uniqueness would be given by a combination of invoice number, year, and invoice type (invoice or credit note).

Let's see how we can model the described scenario using NServiceBus sagas:

```csharp
class OverdueInvoiceData : ContainSagaData
{
   public int InvoiceNumber { get; set; }
}
```

`OverdueInvoiceData` is the structure we'll use to store data related to the lifecycle of an invoice, identified by the invoice number. There will be an instance for every issued invoice, persisted in a database, of the above class.

The next step is to define a saga that uses the `OverdueInvoiceData` type:

```csharp
class OverdueInvoicePolicy :
   Saga<OverdueInvoicePolicy.OverdueInvoiceData>
{
}
```

Nothing fancy, so far. The `OverdueInvoicePolicy` inherits from the `Saga<TSagaData>` base class; it explains NServiceBus that the `OverdueInvoicePolicy` type is a saga.

## Please welcome messaging

If a saga is a workflow of some form, we need a way to trigger state changes. In the NServiceBus world, messages trigger sagas state changes. To respect the single responsibility principle (SRP), we're making the saga responsible for handling only overdue invoices. In the scenario we're considering, an invoice is over if it's not fully paid and if today is beyond the payment terms. Once an invoice is paid, it can't be overdue anymore, even if it was overdue at the time of the payment. If the payment deadline is yet to come, the invoice is not overdue by definition. Finally, we need to start monitoring an invoice once the system produces it. The `InvoiceIssued` event is the message that kicks off the saga:

```csharp
class OverdueInvoicePolicy :
   Saga<OverdueInvoicePolicy.OverdueInvoiceData>,
   IAmStartedByMessages<InvoiceIssued>
{
   public async Task Handle(InvoiceIssued message, IMessageHandlerContext context)
   {
      //...
   }

   protected override void ConfigureHowToFindSaga(SagaPropertyMapper<OverdueInvoiceData> mapper)
   {
      mapper.MapSaga(d => d.InvoiceNumber).ToMessage<InvoiceIssued>(m => m.InvoiceNumber);
   }
}
```

Many things are happening all at the same time. Let's dissect them one by one. The first notable thing is that the saga class implements the `IAmStartedByMessages<TMessage>` interface. The interface tells NServiceBus that the given message type can start the saga; in our sample `InvoiceIssued`. The interface requires our code to implement the `Handle` method, which we'll use later to do something meaningful.

The last bit is the `ConfigureHowToFindSaga` protected method; it's required by the `Saga<T>` base class; it explains to NServiceBus how to find a saga in the configured persistence storage. In our case, we're configuring NServiceBus to map the incoming message `InvoiceNumber` property to the `InvoiceNumber` property defined on the saga data class. When a message arrives, NServiceBus will use the configured mappings to look up the saga data in the storage.

> For more information on messages correlation, refer to the [NServiceBus documentation](https://docs.particular.net/nservicebus/sagas/message-correlation).

One could argue that if the saga can be started by the `InvoiceIssued` even, there is no point in mapping the message as, by definition, there won't be an existing saga for that invoice. There at least a couple of cases in which we need that:

- Duplicate messages: if we're dealing with an "at-least-once" type of transport, we should expect that the infrastructure can deliver the same message multiple times. In that case, we don't want to create a saga instance for each duplicate message; instead, we want to dispatch duplicates to the same saga instance and handle them idempotently.
- Out of order messages: There are scenarios in which sagas can have many entry points, e.g., more than one message type can start a saga. If this is the case, we cannot assume that the `InvoiceIssued` event is the first to arrive. The saga instance might have been already created by a different message.

Back to the overdue invoices tracking scenario; the second condition is: a paid invoice is by definition not overdue. We can model that by handling the `InvocePaid` event:

```csharp
class OverdueInvoicePolicy :
   Saga<OverdueInvoicePolicy.OverdueInvoiceData>,
   IAmStartedByMessages<InvoiceIssued>,
   IHandleMessages<InvoicePaid>
{
   public Task Handle(InvoicePaid message, IMessageHandlerContext context)
   {
      MarkAsComplete();
      return Task.CompletedTask;
   }
}
```

(rest of the code omitted for clarity)

Two things worth noting:

1. `InvoicePaid` is marked as `IHandleMessages<>`, which means that the `InvoicePaid` event cannot start the saga.
2. When the invoice is paid, we can mark the saga as complete; as said, a paid invoice is by definition not overdue; we don't need to keep track of it anymore.

## Delayed deliveries to model time

The initial skeleton of the process is in place. It's now time to design the overdue check. In our case, all issued invoices are due in thirty days. We assume that a bank wire transfer might take a few days to appear on our bank account. Given the two conditions, it's worth checking invoice payments after forty days. When using sagas, we can leverage saga timeouts as a handy tool to model time:

```csharp
public async Task Handle(InvoiceIssued message, IMessageHandlerContext context)
{
   var checkDate = DateTime.Now.AddDays(40);
   await RequestTimeout<CheckPayment>(context, checkDate);
}
```

> The usage of `DateTime.Now` is terrible. It makes the code untestable and not timezones safe. Production-ready code needs to inject a component that can provide that information and use `DateTimeOffset` and account for time zones.

In the `Handle` method for the `InvoceIssued` event, we're scheduling a timeout using the `RequestTimeout` saga method. A timeout is nothing else than a message expected to be delivered in the future. The `CheckPayment` type represents the message that the infrastructure will dispatch in the future, and the `checkDate` argument is the "when" in the future. `CheckPayment`, in this sample, is an empty class such as the following:

```csharp
class CheckPayment
{
}
```

> Nothing blocks us from adding to the class properties as we do for regular messages.

To explain to NServiceBus that we want to handle a timeout, we need to implement the `IHandleTimeouts<TTimeout>` interface on the saga type:

```csharp
class OverdueInvoicePolicy :
   Saga<OverdueInvoicePolicy.OverdueInvoiceData>,
   IAmStartedByMessages<InvoiceIssued>,
   IHandleMessagesMessages<InvoicePaid>,
   IHandleTimeouts<CheckPayment>
{
   public async Task Timeout(CheckPayment state, IMessageHandlerContext context)
   {
      //...
   }
}
```

(rest of the code omitted for clarity)

What are we going to do when the timeout expires? When the timeout is due, NServiceBus dispatches the `CheckPayment` timeout message to the saga; at this point, we can check the payment status of the invoice and act accordingly:

```csharp
public async Task Timeout(CheckPayment state, IMessageHandlerContext context)
{
   var invoiceNumber = Data.InvoiceNumber;
   var isInvoicePaid = _invoiceService.IsInvoicePaid(invoiceNumber);
   if(!isInvoicePaid)
   {
      await context.Publish(new InvoiceOverdueEvent()
      {
         InvoiceNumber = invoiceNumber
      });
   }

   MarkAsComplete();
}
```

> The invoice service (`_invoiceService`), injected into the saga via IoC/DI, is a component that, given an invoice number, returns its payment status.

When time is due, the saga, using the provided invoice service, checks the payment status. If the invoice is overdue, it raises an event accordingly and then marks itself as complete; If the invoice is settled, it immediately marks itself as complete. The saga has one single responsibility, to check for overdue invoices; the saga is not responsible for any further action; it delegates other activities to the endpoints handling the `InvoiceOverdue` event.

### Checking is redundant

Do we need to use an invoice service to check if a given invoice is overdue or not? The answer is no, and this comes with a significant simplification of the saga code. In our scenario, all the messages that the saga handles correctly describe all the possible options. When customers order, the system issues the `InvoiceIssued` event; when they pay, the system publishes the `InvoicePaid` event. There is no need to check for the status when the `CheckPayment` timeout expires from the overdue invoices saga perspective. When an invoice is paid, the infrastructure deletes the corresponding saga (mark as complete); this makes it so that NServiceBus discards the timeout. When NServiceBus successfully dispatches the timeout to the saga, it means that the customer didn't pay that specific invoice yet. The saga can assume that if the timeout reaches the saga, it can publish the `InvoiceOverdue` event; no one paid the invoice yet.

### Order matters: Issue, pay, mark as complete

At this point, an interesting question is:

> What happens to the timeout if the `InvoicePaid` message arrives before the timeout expires?

Previously, we defined it as completed when the saga handles the `InvoicePaid` message. However, if the saga receives messages in the following order:

- Invoice issued (which causes the saga to schedule the timeout)
- Invoice paid

We might find ourselves in a situation where the timeout is scheduled, but there is no saga to dispatch the message to because it's already completed. NServiceBus handles the scenario for us; when the timeout expires, the message is automatically discarded if the saga doesn't exist. The assumption is that an existing saga can only schedule a timeout for itself (there is no way to schedule timeouts for a different saga). If the saga doesn't exist anymore, it's fair to assume that it's already completed. The timeout doesn't make sense anymore.

There are other scenarios in which message ordering is essential from the business perspective.

Imagine the case in which customers are paying with a credit card at the time of the order. The generated invoice is immediately paid. The `InvoicePaid` event may arrive before the `InvoiceIssued`. Remember that physical message ordering is extremely hard, if ever possible, in distributed systems. With the above saga, the described scenario surfaces a problem. The saga is designed to be started only by the `InvoceIssued` message. If `InvocePaid` is dispatched first, NServiceBus cannot find an existing saga; the only viable assumption is that the saga is already completed, and thus the message can be discarded. Later NServiceBus processes the `InvoiceIssued` message and creates the saga. It is a data/message loss scenario.

Suppose we find ourselves in a case like the one described above, which is true for most scenarios. In that case, we want to make sure that NServiceBus can start the saga regardless of messages arrival order:

```csharp
class OverdueInvoicePolicy :
   Saga<OverdueInvoicePolicy.OverdueInvoiceData>,
   IAmStartedByMessages<InvoiceIssued>,
   IAmStartedByMessages<InvoicePaid>,
   IHandleTimeouts<CheckPayment>
{
   public async Task Handle(InvoiceIssued message, IMessageHandlerContext context)
   {
      //...
   }

   public async Task Handle(InvoicePaid message, IMessageHandlerContext context)
   {
      //...
   }

}
```

All the messages that can start the saga are marked as `IAmStartedByMessages<>`. The next step is to explain to NServiceBus how to correlated both messages:

```csharp
protected override void ConfigureHowToFindSaga(SagaPropertyMapper<OverdueInvoiceData> mapper)
{
   mapper.MapSaga(d => d.InvoiceNumber).ToMessage<InvoiceIssued>(m => m.InvoiceNumber);
   mapper.MapSaga(d => d.InvoiceNumber).ToMessage<InvoicePaid>(m => m.InvoiceNumber);
}
```

Finally, we need a way for the saga to determine when it received all the messages. We can easily do that by storing that information in the saga data type:

```csharp
class OverdueInvoiceData : ContainSagaData
{
   public int InvoiceNumber { get; set; }
   public bool InvoiceIssuedReceived { get;set; }
   public bool InvoicePaidReceived { get;set; }
}
```

And use the two new flags in the code that handles incoming messages. 

## Conclusion

We can use sagas and timeouts to model the passage of time. When doing it, it's essential to think deeply about the problem we're modeling and see if there is an opportunity to flip it around and benefit from the passage of time instead of passively modeling it. However, the most important lesson is that we can use messages, and timeouts are just another type of message to model most of the system's interactions across components. That alongside the single responsibility principle generally leads to a significant simplification of the codebase.

The full code is available on GitHub at <https://github.com/mauroservienti/got-the-time-demos/blob/master/src/OverdueInvoices/>

---

<span>Photo by <a href="https://unsplash.com/@alschim?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Alexander Schimmeck</a> on <a href="https://unsplash.com/s/photos/time?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></span>
