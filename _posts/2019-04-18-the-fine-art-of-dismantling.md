---
typora-copy-images-to: ..\img\posts\the-fine-art-of-dismantling
typora-root-url: ..
layout: post
header_image: /img/posts/the-fine-art-of-dismantling/header.jpg
title: "The fine art of dismantling"
author: Mauro Servienti
synopsis: "What happens when there is the need to write data in a distributed system? What if this data needs to go to different services? How do services participate in this process like they do for the Composition part? This is when ViewModel Decomposition comes into play. Let's have a look at what it is and especially when it's really needed."
tags:
- SOA
- Services ViewModel Composition
- Services ViewModel Decomposition
category: view-model-composition
---

The last nine articles in this series were focused on composing ViewModels to present data coming from different services. In all these articles, available in the [ViewModel Composition category](/categories/view-model-composition.html), data flows from the system to users. But this isn't the only direction in which data flows in a system. Users add and edit data all the time.

In the *product* sample scenario used so far, it's legitimate to think that there is a business requirement for creating a new *product*. In which case a question is:

> how do we send data from the UI to multiple services?

And also:

> If [there is no such thing as orchestration](/view-model-composition/2019/04/09/slice-it.html), how do we make sure all services act correctly so that the end result is not a corrupted *product* with a price but without a name and a description?

We're leaving the composition space to enter what I like to call the decomposition world.

## Dismantling is rarely the solution

First things first. It's very easy to immediately jump to a solution for the above requirement:

> We need a *product* page that allows editing *product* details and keeps them from talking to each of the services. Same goes for a page that creates a new *product*.

### Products are not created nor edited

Before diving into a real decomposition scenario, let me first demystify a couple of things. In talking to a business stakeholder in the ecommerce space they won't ever say: I want to create a new *product*. They will say things like:

1. We started fulfilling a new *product* form a new supplier
2. I want to start selling a new *product* online
3. I want to change the price of a *product* we sell

None of the above intentions/actions include changing an entire *product* at once. In order to sell a new *product* by adding it to the catalog we first need to buy it from a supplier. The Warehouse has a back-office page that allows adding a new supplied *product* with details such as: supplier SKU, supplier price, supplier description, etc.

Once the *product* is defined in Warehouse, it'll be available to both Marketing and Sales. Through a composite view, both can display products available in Warehouse that don't have a selling price defined, or that don't have a name and a description suitable for the online catalog.

A page in Sales allows creating the Sales concept of a *product*, with the same ID of the Warehouse one, with an assigned price. A page in Marketing allows defining the name and description to assign to the *product* when it'll be available on the online catalog. And finally a different page, still in Marketing probably, allows selecting which *products* are now available for sale online.

The pages just described will use ViewModel Composition techniques to visualize read-only data coming from services and composing forms to allow users to edit a subset of the data, subset owned by one service. This is to say that in large systems all these operations are performed by different people in different moment.

## Decomposition to the rescue

There are however scenarios that require users to "edit", at the same time, data owned by different services. Let's say that we need to reserve a hotel room online. We search for the room availability, select the room we prefer, and land on a "confirm reservation" page. On this page we need to input:

- personal details such as first name, last name, etc.
- credit card information

The page also summarizes the details of the reservation we're going to make, such as check-in/check-out dates and destination. Finally there is a single "confirm your booking" button, to submit all the details at once.

Based on what we discussed so far it's easy to realize that:

* Personal details should go a Customer Care/CRM service.
* Credit card information should go to Payments.
* Reservations should keep track of the reservation request but wait at least for Payments to confirm that the payments details are valid and the credit card has been charged.

Based on this we can define Decomposition as:

> the process of intercepting incoming data, data that are flowing from users to the system and allow each service to chop off the part they own so that no boundaries are violated and ownership is respected.

### Yes, we can!

The infrastructure we've designed so far can easily handle this type of scenario. The `IHandleRequests` interface is designed to handle read requests, but also write requests:

```csharp
class PaymentReservationHandler : IHandleRequests
{
   public bool Matches(RouteData routeData, string httpVerb, HttpRequest request)
   {
      var controller = (string)routeData.Values["controller"];

      return HttpMethods.IsPost(httpVerb)
         && controller.ToLowerInvariant() == "resevation"
         && routeData.Values.ContainsKey("id");
   }
}
```

Payments can define a request handler that intercepts HTTP post requests to a URL like `/reservation/{reservation-id}`, the same can be done by Customer Care, and by Reservations.

Let's start from the end: Reservation in the `Handle` method of its request handler will send a request to its backend to kick off the reservation process. The reservation process is a state machine whose first state is `reservation-pending`.

Customer Care simply stores customer information along with the `reservation-id` to keep track that a reservation belongs to a customer. By using list composition techniques Customer Care can now handle scenarios like: we want to display all the reservations made by a customer.

Payments sends to its backend credit card details. The backend kicks off the payment process, which is also a state machine. Once done, it'll notify the system, e.g. via an event on a queue, that the payment for a reservation identified by a specific ID succeeded (or failed).

Reservations will react to the event and will transition its state machine from `reservation-pending` to `reservation-confirmed`, or `reservation-declined` in case of payment failure.

In order to do so, all the handlers deployed by services need to do is to extract data from the incoming POST request:

```csharp
class PaymentReservationHandler : IHandleRequests
{
   public bool Matches(RouteData routeData, string httpVerb, HttpRequest request)
   {
      /* omitted for clarity */
   }
   
   public async Task Handle(string requestId, dynamic vm, RouteData routeData, HttpRequest request)
   {
      var reservationId = (string)routeData.Values["id"];
      var creditCardNumber = (string)request.Form["creditCardNumber"][0]);
      var creditCardName = (string)request.Form["creditCardName"][0]);
      
      /* send Form data owned by Payments to backend */
   }
}
```

### Not all what glitters is gold

Sending data to backend is not as easy at it seems at first glance. The incoming request is HTTP and there are, in this sample, three different handlers that try to handle part of the request. What if one of them fails? We need to find a way to deal with the fact that HTTP has no transaction support. The next article will be focused on what we can do when things go wrong.

## Conclusion

In distributed systems it's very easy to find business cases where ViewModel Composition is what we need. We need to be careful in not falling into the "we need decomposition as well" trap. As we've seen that's not always the case. There are however scenarios in which ViewModel Decomposition techniques are required to satisfy specific business needs.

---

Header image: Photo by [Vadim Sherbakov](https://unsplash.com/photos/osSryggkso4?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
