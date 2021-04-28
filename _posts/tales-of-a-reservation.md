---
layout: post
header_image: /img/posts/tales-of-a-reservation/header.jpg
title: "Tales of a reservation"
author: Mauro Servienti
synopsis: "Are you relying on invariants and assuming trust in business rules? Distributed software systems disrupt most of ours beliefs. They require a deep understanding of the business and a shift in the way we think. Let's see how the business affects the system design and what new opportunities come to life."
tags:
 - SOA
---

A talk I gave at [ExploreDDD in Denver in 2018](https://youtu.be/KkzvQSuYd5I) has more than 14.000 views. I'm astonished. It was the first time I was presenting my ["All our aggregates are wrong"](/talks/all-our-aggregates-are-wrong.html) at a major conference, and it's been a blast.

There isn't an easy way to get notifications about comments on videos uploaded by others on YouTube. Every once in a while, I quickly scan [all my presentations](https://youtube.com/playlist?list=PLhm595Y7ah_E42m_EwnSvqeMLVCD2EMb5) available on YouTube for new comments.

I recently noticed the following [comment](https://www.youtube.com/watch?v=KkzvQSuYd5I&lc=Ugz_mJEoRQbVSOWnzcR4AaABAg), which I [responded](https://www.youtube.com/watch?v=KkzvQSuYd5I&lc=Ugz_mJEoRQbVSOWnzcR4AaABAg.9D69WRCMOQO9Lugq-tJqOZ), dense enough to deserve its blogpost.

> How does placing an order then work? does the information in each boundary transition to its own order model? I could assume sales would be the one where this operation takes place, but how does validation in other services regarding the placement of this work? e.g. you could call sales to say place this order/order this cart, but what is there is a business rule for an order can only be placed if all of the items have stock at that time? Thanks

The comment is perfect; it summarizes most of the challenges designing a distributed system poses. We have to dissect it, question by question, and then connect the dots again.

## ViewModel decomposition

> does the information in each boundary transition to its own order model?

Yes, and that happens through a ViewModel decomposition process. It's easier if we use a sample. Imagine a hotel booking reservation system; placing an order corresponds to successfully submitting a booking request. To keep things the simplest, let's assume that to place a hotel room reservation, we need four things:

- Valid check-in/check-out dates
- Guests' information, such as first name, last name, etc.
- Payment methods information
- A successful card authorization for the booking amount 

We can imagine that there are three to four different services involved in the mentioned process. The reservation service owns check-in/check-out date, guest service owns guests details, and finance owns payment details and card authorization. Maybe a payment service is responsible for the card authorization; we don't need much detail in this simple scenario. 

The user experience for the presented process goes more or less like the following:

- Users select dates for their stay 
- Based on the chosen dates, the system shows all the available hotels and room options

Users chose one or more options and are presented with a confirmation page composed of:

- The selected dates and options
- A form to input their guest and the payment method details
- A submit button

When all the required data have been provided and the submit button pressed, each set of information needs to be sent to their owning service.

If the presented data is on a web page that groups it using an HTML form, we need to find a way to extract subsets of the form collection and dispatch them to the owning services. The process is called ViewModel decomposition. At a high level, the decomposition process works in the following way:

- The HTML form posts data to the backend
- The backend hosts a composition gateway that handles the post request
- The composition gateway loads one or more components interested in handling the incoming post request
- Each component extracts the portion of the data they own and dispatches it to their service for further processing

The process has many nuances and hidden dangers, I dissect it in ["The fine art of dismantling"](https://milestone.topics.it/view-model-composition/2019/04/18/the-fine-art-of-dismantling.html) and ["Safety first!."](https://milestone.topics.it/2019/05/02/safety-first.html)

## Logical ownership

> I could assume sales would be the one where this operation takes place, but how does validation in other services regarding the placement of this work?

The question is the second part, and we'll get to that soon; however, we have to spend some time contemplating the first part of the sentence.

Conceptually we want to identify who is the logical owner of the business process we're designing. There are scenarios in which we need that, others in which it is not so important. For example, in the hotel reservation sample, the reservation service is probably the logical owner of the reservation business process.

### Why and what are the implications?

There is no unique answer; it depends on how we decide to architect the system and, more importantly, how the business works. In the presented sample, two options come to my mind:

1. When the user hits the submit button, the reservation service pre-locks the selected rooms and waits for an event published by finance to signal a successful card authorization. When the card is authorized, the reservation service confirms the selected rooms; at this point, finance confirms the authorization, and the process completes.
2. A second option is to go to finance first. Finance authorizes the user's credit card, publishes the authorization event, and reservation marks the selected rooms as booked. Finance can now confirm the card's authorization, and the process completes.

The first consideration is that we never mentioned marketing as an actor in the above choreography. It is a crystal-clear signal that marketing is not the logical owner of the business process. We're left with finance or reservation. Both the presented options are valid, and a final selection probably depends on the business. Let's make some more assumptions, though; option two is more straightforward, there are fewer interactions. A downside of option two is that it is more fragile in high concurrency scenarios. Imagine thousands of people concurrently trying to book hotels in the same city for a big event. By the time a card is authorized, there is a high chance a different customer successfully booked the same room, and the process needs to start again to retry. Option one is more chatty but comes with a solution, a two-phase transaction approach, to the high concurrent scenarios.

The described conversation requires some way for involved services to identify which conversation messages are related to; we call that a correlation identifier. Who generates the correlation identifier? Suppose the conversation starts from the user interface; A request needs to be decomposed and dispatched to many services. In that case, the correlation identifier needs to be generated at the user interface level. The logical owner is an excellent candidate to create the mentioned identifier.

In complex systems, the implications ramifications can be huge; you probably understand why identifying logical ownership is essential.

## Invariants are evil

Let's move on.

> [...] but how does validation in other services regarding the placement of this work?  e.g. you could call sales to say place this order/order this cart, but what is there is a business rule for an order can only be placed if all of the items have stock at that time? Thanks

Things are getting tricky! Let's analyze the booking system sample we have used so far first.

In the hotel booking sample, resources are fixed. The number of available rooms can be considered unelastic. Using a warehouse analogy, what's in stock is all that we have. Option one is the safest; we lock the selected rooms first, which guarantees they will be available to the customer. That is the same approach used by most ticket booking websites, for example. Option two is less safe even in low concurrent scenarios. The more rooms a customer tries to book, the higher the risk one will not be available when the credit card is authorized. In the booking business, it seems that locking is a better option.

Is that always the case? As you probably guess, the simple fact that I'm asking the question means that the answer is no. The presented options are probably both valid even in booking-kind scenarios, and it depends on the business setup. So far, it seems that option one is safer than option two.
Before presenting a booking scenario where option two, or a variation of it, might be better, let's have a look at a different business.

Lacadon, Inc. is a generic e-commerce website that sells many things. Lacadon has many warehouses worldwide; the order fulfilling system might pick up items from different warehouses based on some business rules.

Let's see what happens if we apply option one to the Lacadon business. Option one is a transaction-based approach. When an order comes in, products are locked for that order, and if the credit card authorization is successful, the order is confirmed and later processed and shipped. If not all products are available in one warehouse, we need a distributed transaction over more than one warehouse.
In both cases, even the simpler one involving one warehouse, the system doesn't scale. The more order we have, the longer they'll wait until one way or the other they deadlock.
In this kind of business, locking is rarely, if ever, an option. Appling option two doesn't change the situation much; it'll still be tough to guarantee the business rule. With option two, we first authorize the card and then check for items' availability. If items are in stock, we proceed with the order. The devil is in the details:

1. We first have to count items in stock that match the items in the order, and this might need to be cross-warehouse
2. If there is enough availability, we proceed with the order

In between steps one and two, a different order can change the status. Again, the only viable option is a transaction with a pessimistic lock—a no-go in a distributed system and probably a no-go in any scenario.

### So what?

There is no technical solution. The solution is turning to the business and ask the following question:

> What should the system do when an order cannot be fulfilled entirely because not all items are in stock?

The key here is the "when" in the question; it's not a matter of "if." It'll happen. Probably the business will tell us to accept the order. Warehouse stocks are elastic; we can replenish them; this means we can take the order, making it an internal partial order. Ships what we have, create a second internal partial order and ship it when items are back in stock.
Meanwhile, we can send the customers an email, apologizing for the issue telling them what to expect. Brutally said, it's a follow-the-money approach. In a complex system like the one we described, it's like that there is some analytics in place that captures low stocks for sold items and preorders them before they're going out of stock. If that's the case, the system will likely fulfill the pending partial order faster than the customer expects.

## Commands never fail

If we agree that there is no easy way to guarantee invariants, we have the opportunity to change the perspective. We can move from a model where business rules deny to a model where they open to different alternative paths. In the mentioned e-commerce use case, instead of preventing users from placing an order, we can always accept the order and then evaluate options, such as splitting the order into multiple sub-partial orders. Airline companies, for example, do that daily. They have statistics about passengers not showing up at gates. Based on that, they can safely sell more tickets; a practice called overbooking. Sometimes it happens that your seat gets moved, or as it occurred to me once, a bid is run at the gate because there were four more passengers than expected on the London City to Milan MXP Sunday night flight.

In any case, it's both a follow-the-money approach and an excellent way to avoid a business rule similar to "when booking online only one customer can select a given seat." Interestingly, airplane seats are unelastic, like hotel rooms. However, airline companies found exciting ways to work around the problem, other than the mentioned overbooking technique. They introduced different fares for different seats. At first look, different fares seem to be merely a sales technique; it's not only that, different fares for different seats allow creating seat clusters or something we could call transactional boundaries. They decrease the likelihood that two customers simultaneously booking the same flight will look at the same seat cluster, reducing conflicts.

## Conclusion 

The mentioned samples are an excellent demonstration of the "commands never fail" design approach. The idea is to move from invariants, or what I prefer to call a denial approach, to a more Italian-style approach where rules are meant to be bend. Trust me; I know what I'm talking about. The only way to guarantee an invariant is to use transactions; there are scenarios in which using transactions is perfectly legit. However, if we cannot use transactions, it's preferable to move away from invariants and approach use cases with a mindset that thinks compensating actions rather than rigid walls.

---

Photo by <a href="https://unsplash.com/@keemibarra?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">KEEM IBARRA</a> on <a href="https://unsplash.com/s/photos/hotel?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
  
