---
layout: post
title: "The pitfalls of request/response over messaging"
author: Mauro Servienti
synopsis: "Request/response is everywhere. It serves us very well and is a neat solution in many scenarios. It comes with a few pitfalls in distributed systems and needs to be handled with care."
enable_mermaid: true
header_image: /img/posts/pitfalls-of-request-response-over-messaging/header.jpg
tags:
- soa
- distributed-systems
---

Request/response as a communication pattern is pervasive. We use it in many different scenarios, and it works most of the time flawlessly. For example, the following is an HTTP request to a remote API:

```
GET /api/some/list HTTP/1.1
Host: a.remote.api
```

When successful, the response looks like the following:

```
HTTP/1.1 200 OK
Date: Sum, 06 Nov 2022 14:28:02 GMT
Last-Modified: Wed, 01 Dec 2021 20:18:22 GMT
ETag: "71152dc3-7448-475b075c2191b"
Accept-Ranges: bytes
Content-Length: 2345
Content-Type: application/json

{ 'blah': 'blah' }
```

If something goes badly, we get an error response stating what happened. Still, we get a response to our request.

There are many different technologies implementing request/response, HTTP, gRPC, .NET Remoting, and many of the WCF bindings, to name a few. The last two are for the archeologists among us ;-)

Request/response is a neat solution to a common problem. We need data to fulfill some business requirements and can request that data whenever necessary. For example, we can use Twitter for a while if the requirement is to waste time. The Twitter app will send one or more requests to the API and render responses. When new tweets are available, the remote API will send a push notification, and a new request/response exchange will populate the user interface with fresh tweets.

Request/response works exceptionally well—nothing to complain about. However, we need to be careful not to abuse its flexibility by using it in a context where it might cause some headaches.

## Request/response over messaging

Given its popularity and success, using request/response over messaging is very tempting. The idea might get more traction if we look into the scalability capabilities of a message-based architecture. The train of thought might be, "If messages scale out so well, it must be beneficial also when using request/response." Let me give you a couple of examples.

The application needs to query data to fulfill a business requirement. Queries are usually synchronous. Synchronicity implies that the system demands resources when the query happens. What if we send the query definition to a remote service using a message and wait for a response?

Similarly, the authentication request is synchronous when a user logs in to the system. The more users try to log in simultaneously, the more the authentication component will be a bottleneck. What if we could securely send credentials using a message to a remote authentication component and wait for a response?

## Once upon a time, there were two generals

Sending a message to a remote service for asynchronous processing is appealing. However, we must be careful. [Only the famous lady is sure that all that glitters is gold](https://youtu.be/Ly6ZhQVnVow). In the distributed system world, proof of receiving is a renowned problem, hard, if possible, to solve. The following story represents it well:

> Two generals are only able to communicate with one another by sending a messenger through enemy territory. They need to reach an agreement on the time to launch an attack, while knowing that any messenger they send could be captured.
>
> The first general may start by sending a message "Attack at 0900 on August 4." However, once dispatched, the first general has no idea whether or not the messenger got through. This uncertainty may lead the first general to hesitate to attack due to the risk of being the sole attacker.
>
> To be sure, the second general may send a confirmation back to the first: "I received your message and will attack at 0900 on August 4." However, the messenger carrying the confirmation could face capture and the second general may hesitate, knowing that the first might hold back without the confirmation.
> 
> Further confirmations may seem like a solution—let the first general send a second confirmation: "I received your confirmation of the planned attack at 0900 on August 4." However, this new messenger from the first general is liable to be captured, too. Thus it quickly becomes evident that no matter how many rounds of confirmation are made, there is no way to guarantee the second requirement that each general is sure the other has agreed to the attack plan. Both generals will always be left wondering whether their last messenger got through.

Source: [The Two Generals' Problem—Wikipedia](https://en.wikipedia.org/wiki/Two_Generals%27_Problem)

In both the above-presented scenarios, the sign-in process and the need to query for data, we are in the same situation as the two generals. The sender sends a message to the endpoint that's supposed to process that message and respond. However, there is no guarantee the message gets delivered or understood.

For the sake of the discussion, let's assume that delivery is guaranteed. Messages will arrive at the destination no matter what. That's the only assumption the sender can make. Receivers have a plethora of error conditions to choose from before being able to process incoming messages and reply to senders successfully. Even if that is successful, senders might still fail to process the reply.

## In a broader sense, messaging is unreliable

Watcha talkin' bout, Mauro? (Cit. — <https://youtu.be/Le6qeMe7-vM>)

> I'm sorry, that's another overloaded term, another instance of the [linguistic limitations](https://milestone.topics.it/2021/09/15/linguistic-limitation.html) we're facing.

We use to refer to reliable messaging in contrast to unreliable ones. That's usually in the context of queuing systems. For example, RabbitMQ has the concept of [Publisher Confirms](https://www.rabbitmq.com/confirms.html#publisher-confirms). If they are off, the broker acknowledges the send operation upon it receives the message. It makes the broker extremely fast, with the risk that if it fails to write the sent message to disk, it's lost. That's unreliable messaging. There are scenarios in which it makes sense. To turn it into reliable messaging, we enable publisher confirms. The broker will acknowledge requests only upon successfully processing them.

If we move one step up and try to include the destination in the reliable messaging concept, we'll need distributed transactions. The message receiver lives in a different process. That means we must coordinate three resources: the sender, the queue/broker, and the receiver. However, distributed transactions are one of the things we're trying to avoid by moving to messages and queues. In essence, we cannot solve the two generals' problem.

## Embrace coupling 

We could generalize the presented scenarios as the need to know that messages made it to the receiver and were successfully processed. If that's what we need, we should not try to avoid a synchronous request replacing it with messages—there is already a coupling between the sender and the receiver. Messages and queues will only generate a false perception of decoupling.

## But Mauro, isn't request/response a well-known messaging pattern?

Yes, but that doesn't mean it should sprout up everywhere. Let's look at a payment system for a second. I love payment systems; they seem trivial on the surface but hide many challenges.

While placing an order, users select the payment method. For example, they use a previously saved credit card. The requirement is that the chosen payment method is effectively used when we ship the order, not when users place it.

So far, so good. If payment happens only when the shipment happens, it's asynchronous to the user's request to place the order. There is no one in front of the screen waiting for a response. Second, looking at the internals of the payment process, we need to decouple our part of the payment system from the credit card provider part. We don't want our payment management to fail because the credit card provider is unavailable when we need it. That's where we can leverage request/response using messages:

<div class="mermaid">
sequenceDiagram
    autonumber
    Shipping-->>Finance: OrderShipped
    Finance->>PaymentGateway: ChargeCardRequest
    PaymentGateway->>Finance: ChargeCardResponse
</div>

Looks neat. However, that's prone to the two generals' problem described above. The payment gateway could fail to process the `ChargeCardRequest` and never reply with a `ChargeCardResponse`.

To solve the problem, we need to make things a little bit more complicated:

<div class="mermaid">
sequenceDiagram
    autonumber
    Shipping-->>Finance: OrderShipped
    Finance->>PaymentGateway: ChargeCardRequest
    rect rgb(200, 150, 255)
    Finance->>Finance: Request ChargeCardTimeout (10 minutes)
    end
    PaymentGateway->>Finance: ChargeCardResponse
</div>

The newly added highlighted section is the needed safety net. Finance sends the `ChargeCardRequest` message and sets a timeout to react in 10 minutes if there is no response from the payment gateway. That's only the beginning, though. We also need to design all the corrective measures to ensure the system pauses order processing, understands what happened with the payment, retries it, or gets back to the customer to involve them in solving any of the issues faced.

Synchronous requests are much more straightforward. The actor issuing them has all the information to decide how to react to failures. Why complicate things using messaging when it's only a query? If it's a simple query, issue the query.

## What does make it "simple"?

At this point, one could argue what simple means. My rule of thumb is that if what we're modeling is a business process, then it's not "simple" by definition. If it's not a business process modeling exercise, and a query to retrieve data is not, we should use a synchronous request/response style.

Another comment could be: what about generating a report? Collecting the needed data might take a while, and a synchronous request/response might timeout.

Sure thing. Let me make you know that generating a report is a process. It's not a "simple" query. On the same path, signing in hardly qualifies as a process. Signing up, though, is a process.

## Conclusion

There is no doubt that request/response is a neat solution in many scenarios. It's critical not to abuse it; otherwise, it'll quickly revolt against us, making our life miserable for no good reason. Request/response works very well in synchronous scenarios, HTTP being a good example. It must be handled with care when used in a message-based system.

---
Photo by <a href="https://unsplash.com/@ross_savchyn?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Rostyslav Savchyn</a> on <a href="https://unsplash.com/s/photos/pitfalls?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
