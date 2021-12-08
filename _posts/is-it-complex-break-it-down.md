---
layout: post
header_image: /img/posts/is-it-complex-break-it-down/header.jpg
title: "Is it complex? Break it down!"
slug: is-it-complex-break-it-down
author: Mauro Servienti
synopsis: "Sometimes, we choose technology based on the perceived complexity or heaviness. We focus our decisions on the technical solutions rather than looking deeper at the problems we hire those solutions. Are we making the right choices?"
tags:
- sagas
- soa
- distributed-systems
---

Over time I learned how important words are. We have absolute concepts like color; something is red, yellow, or green. And then we have not such absolute concepts, like weight, size, or complexity. When we say that something is small or micro, it's always compared to something else. The same goes for weight or complexity. Something is not heavy; it's heavier or lighter than something else. On the same line, something else is more complex than another thing.

I often listen to people defining some technology or architecture style as heavy or complex. I'm guilty, too; I did the same things many times.

## But are they complex or heavy?

Let me use [NServiceBus sagas](https://docs.particular.net/nservicebus/sagas/) as an example. I like to describe sagas as a modeling tool. We use sagas to model long-running business processes or transactions.

> The usual disclaimer applies: I work for Particular Software, the makers of NServiceBus.

Let's consider the following business process:

> the system, at checkout, converts a shipping cart into an order. Once converted, the process proceeds to fulfill and prepare the order for shipment. When the order is shipped, an invoice is issued and marked as due based on its payment terms. Later on, the order management system checks for overdue invoices.

In theory, we can have a "ginormous" saga handling all that described so far.

If we do that, we'll have a complex implementation of what appears to be a complex business process. And, every time we'll have to tweak it to adapt to change requests, or we'll have to deploy it, we'll perceive it as heavy.

I'm using complex and heavy because we can have a less complicated, I'd argue simple, and thus lightweight, implementation of the described business process.

## It's not a technical issue

As in many cases, it turns out that what makes the implementation complex and heavy is not the technology of choice but the analysis and translation of the business process into architecture.

If we slavishly translate the business process into code, it's not surprising that the outcome can be heavy or complex. I believe that it's because we [trust the user mental model](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html) too much. Instead, we should first break up each business process in its founding procedures. After that, we should start modeling the technical solution, for example, using sagas as a modeling tool.

## Let's break it apart, first

> the system, at checkout, converts a shipping cart into an order.

The first step is to move all items, primary keys, from the shopping cart to a new entity, the order. And delete the cart content. Those are two operations, for example:

- a post request to initiate the checkout and create the order entity
- an event, a message on a queue, to broadcast the order creation that we can use to empty the shopping cart asynchronously.

> Asynchronously, because, if we're building a distributed system, [the shopping cart doesn't exist](https://particular.net/webinars/all-our-aggregates-are-wrong). The only way to reliably empty the cart is by allowing each participant service to asynchronously decide how to deal with order creation and the need to clear it.

### Is the order entity a long-running business transaction?

At this point, a good question is if the order entity represents a long-running transaction. The way the requirements describe it suggests that it is. I bet it's not. The order entity is nothing more than a primary key, an ID, and maybe a few attributes, such as the creation date.

> Don't be tempted by the user interface needs. We need to display an order summary page with all the order details. That's not a good reason to have a rich order entity with all the details. [ViewModel Composition](https://milestone.topics.it/categories/view-model-composition) techniques solve the read model problem. For more information: [Read models, a knot to untie](https://milestone.topics.it/view-model-composition/2019/03/26/read-models-a-knot-to-untie.html).

## Next, please

> Once converted, the process proceeds to fulfill and prepare the order for shipment.

If a service in the system already broadcasts an event to notify that an order has been created, warehouse, another service, can react and proceed with orders fulfillment. Similarly, can shipping.

From a service boundaries perspective, fulfillment and shipping are not part of the order management "thing" because the order management thing does not exist. Order management is a "user mental model" concept that doesn't translate into a service.

Fulfillment and shipping are long-running business transactions, though. They are both started by the order-created event. Fulfillment, during its lifecycle, will collect items from warehouse shelves and take care of all the exceptions connected to no more in-stock items. It'll do so by raising events, not directly managing the exception. Other services will handle those events and make decisions on how to proceed. One of these might be shipping that can turn what was supposed to be a single shipment into multiple deliveries once stocks are replenished.

### Shipping is a long-running business process too

Similar to fulfillment, shipping starts with the order-created event and reacts to interesting events broadcasted by other services. For example, a fulfillment-completed event might trigger the final steps to deliver the order to the customer.

> When the order is shipped, an invoice is issued and marked as due based on its payment terms. Later on, the order management system checks for overdue invoices.

All that said applies to finance too. Finance reacts to the order-shipped event, broadcasted by shipping, and issues the required invoice. Invoicing implies charging the user's credit card, which requires authorizing the card first.

### Surprise, surprise, finance is a long-running process too

We can create a separate saga, or more than one, to handle the payment and invoicing procedures. Payment is a different saga than the one needed to generate the invoice. But it doesn't end here. Once the invoice is issued, which turns to be an event published by finance, a third saga is kicked off to keep track of the shipment-returned event to refund the user's credit card eventually. Another option could be if the system allows different payment methods: if customers could buy and pay, upon receiving the goods, using a wire transfer, the system needs to keep track of overdue payments.

> A sample implementation of this last bit is described in [Got the time article](https://milestone.topics.it/2021/03/05/got-the-time.html).

## Conclusion

When looking at long-running business processes, it's easy to be overwhelmed by the apparent complexity. In many cases, they are not that complex. It's the way we frame them that creates complexity. Beware that the user's mental model can be a traitor. We must spend time dissecting processes to break them down into their founding components. Once that's done, each part is more straightforward and ready to be implemented. Many of these simpler parts can still be long-running processes. If that's the case, sagas are an excellent solution.

As in many contexts, _It's the single responsibility principle, baby._

---

Photo by <a href="https://unsplash.com/@__itsflores?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Omar Flores</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
