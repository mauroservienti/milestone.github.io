---
typora-copy-images-to: ..\img\posts\businesses-dont-fail-they-make-mistakes
typora-root-url: ..
layout: post
header_image: /img/posts/businesses-dont-fail-they-make-mistakes/header.jpg
title: "Businesses don't fail, they make mistakes"
author: Mauro Servienti
synopsis: "Sooner or later the system will fail. Doesn't matter if it'll be for an infrastructure failure or a bug. It'll fail. Dealing with failures can be tricky especially when business failures are handled like if they were infrastructure ones."
enable_mermaid: true
tags:
- NServiceBus
- Messaging
- Failed messages
---

It will eventually happen. Our beloved message-based system sooner or later will fail and the error queue, created as a safety net a long time ago, will be filled with failed messages.

I was in a meeting at a customer, a long time ago, when the monitoring system started screaming. A few messages just failed unexpectedly. There was a bunch of people from the DevOps team sitting around the table with me and, as expected, their attention was dragged away by the sounding alarm.

The customer is a bank. The system is an internal system whose primary business role is to handle `cash order` payment requests, and validate and store them. Once the `cash order` is notified to the debtor, the system keeps track of payments and delays.

Italian bank regulations state that the debt identified by a `cash order` cannot expire on a non-working day, a bank holiday in Anglo-Saxons terminology.

> Note: I'm oversimplifying, for simplicity, both the business scenario and they way it failed in production. Nitty gritty details are not required in this case.

## The glitch

After a few minutes of debugging, the team realized that all the failed messages are related to `cash order` requests due to them expiring on Easter Monday, a clear violation of the aforementioned business rule.
A couple of hours later the glitch was found: the end user front-end application is affected by a bug related to the way the Easter date is calculated causing Easter Monday not to be considered a holiday.

At that point I decided to chime in asking what I thought was a very innocent question:

> How come a business failure caused a message to end up in the error queue?

## Eyes staring at me

They immediately started explaining the root cause of the issue. Javascript validation code at the front-end was misbehaving, causing a command to be sent from front-end to back-end services that upon message handling time were reevaluating the business rule and throwing an exception due to the validation failure.

Being a message-based system, the message retry engine was kicking in and eventually failed messages were ending up in the error queue.

The root cause was clear and pretty straightforward. However I asked the same question again:

> How come a business failure caused a message to end up in the error queue?

At which point, I had their attention.

## Business failures are not errors

When dealing with failed messages in a message-based system there are two important questions we should ask:

* Is there any good reason to retry, in a tight loop or manually later, a message failing due to a well-known business failure?
* Is there something that an Operations Team can do, other than stating the obvious, when faced with a message that failed for a business reason?

In a scenario, such as the above one, there is no point in retrying the create `cash order` request, given its actual state; it will always fail. Blindly retrying the failed message will cause an infinite loop, it'll fail again, and again, and again.

### Design for (business) failures

Designing for failures is one of the leading mantras when it comes to distributed systems. The same approach should be applied to business scenarios by modelling failures using messages. The aforementioned failing business scenario is outlined (in its simplified version) in the following diagram:

<div class="mermaid">
graph LR
   A[fa:fa-globe Client] -->|CreateCashOrder| B[fa:fa-server Back-end]
   B -->|Exception| C[Error Queue]
</div>

Once the back-end services fail to handle the `CreateCashOrder`, the message is delivered to the `error` queue, monitored by Operations. As we've seen Operations is left with no options, the message cannot be retried as it'd fail again. In such case the only option would be to ask the development team to introduce, in the back-end message handling code, a special case:

- if a message comes in with an invalid date
- automatically find the next available date, where available means available according the defined business rules.

This is clearly not an option: it would end up creating something very similar to corrupted data. The original request came in with a date, date also returned to the user requesting the operation. But then the real operation will be executed on a different date.

In the mentioned case, what the back-end services should do is reply to the request originator with a specific message describing the failure encountered and, if required, compensating actions that can be performed to fix the business rule violation. Designing the interaction with the business failure in mind is represented in the following diagram:

<div class="mermaid">
sequenceDiagram
   participant C as Client
   participant B as Back-end
   C ->> B: CreateCashOrder
   activate B
   B ->> B: SuspendCashOrder
   B -->>C: CashOrderCreationError
   deactivate B
   Note over B,C: Reason: invalid date
</div>

The system has now many options to react to the business failure: for example an email could be sent to the user warning them that the previously entered `cash order` failed the validation process, and has been suspended.

## Conclusion

Business errors should be treated differently than infrastructure failures or bugs. We should spend time modelling the business failures using the same technique used for the rest of the system: messages. When handling a message causes a business rule violation, the system should not simply crash, instead it should reply with a message that clearly explains the failure reasons, and if it makes sense offering options to fix the failing scenario.

*For more information on error management in messages based systems refer to the excellent ["But all my errors are severe!"](https://particular.net/blog/but-all-my-errors-are-severe) by [David Boike](https://www.make-awesome.com/).*

---
Header image: Photo by [Daniela Holzer](https://unsplash.com/@matscha?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/mistake?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
