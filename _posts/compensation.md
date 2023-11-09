---
layout: post
title: "Compensation is all around us"
author: Mauro Servienti
synopsis: "In a message-based system we might feel lack of control, especially when in need of compensating changes spread across the system. Fear not! Real life deals with compesation every day! And it's better than rolling back a transaction or deleting some data in the database."
header_image: /img/posts/compensation/header.jpg
tags:
- architecture
- soa
- distributed-systems
---

A few months ago, I got a [follow-up question from Alisher](https://milestone.topics.it/2019/05/02/safety-first.html#comment-6166203046) on my ["Safety first!"](https://milestone.topics.it/2019/05/02/safety-first.html) article. The question is about compensation and downstream events:

> The more I think of write part of this whole approach (and microservices in general), the more questions arise - like, ok, I can probably compensate database mutations, but what about events that were already propagated downstream? I can't really send compensating event like "actually, it didn't happen".

Last weekend, we planned to go to [Turin for the chocolate fest](https://cioccola-to.events/2023-eventi/). Our daughter got sick a few days before, and we had to rearrange our plans. In the end, we canceled the trip. Rearrange turned out to be an understatement or wishful thinking, if you will.

It all started with a few [messages](https://milestone.topics.it/2023/05/25/back-to-basics-messages.html) across [autonomous](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html) family members to agree on what to do. Then, a command to book what needed to be booked. Finally, a [timeout](https://milestone.topics.it/2023/10/18/timeouts-power.html) to signal we needed to go. Later, an even signaled the daughter's illness. And a series of follow-up messages and commands led to canceling the trip.

That's compensation at play.

## Things are never so straightforward

Was all that above-mentioned straightforward? Well, in the context of distributed systems, yes, it is.

Alisher's comment is in the context of a much more complex scenario. It's still in the domain of distributed systems; however, the "Safety first!" article discusses handling write requests in a ViewModel (de)composition scenario. Let me summarize that in a few words.

A user is trying to achieve their goal using the system at play. The press of a button does something interesting for the user. When the system handles the user request, it does it by invoking more than one background service, splitting the incoming request payload, and allowing each service to deal with the part it owns.

> More information about ViewModel decomposition and the problem it solves in ["The fine art of dismantling"](https://milestone.topics.it/2019/04/18/the-fine-art-of-dismantling.html)

In that context, service A might receive some bits of the request and process it successfully. Simultaneously, service B receives another portion of the requests, but it fails to process it. The "Safety first!" article presents some options to mitigate the possible disruption from something like that. However, we need to prepare to handle the disruption. Chances are it'll happen.

We could use compensation techniques between services A and B to resolve the situation. Some of those options are described in ["What if my command was rejected?"](https://milestone.topics.it/2023/06/27/reject-commands.html).

## It could be worse, it could be like in real life

While handling its portion of the request, service A also publishes an event to signal its new state. Another service handles the downstream event and moves the system forward.

Can you see the problem?

Let me use one more real-life example. I wanted to go to the Iron Maiden concert in Milan with two friends. When tickets went on sale, I needed to be faster, and I didn't get a chance to buy three Gold Circle tickets (I'm too old for regular tickets, where you have to show up hours in advance to get a good spot). We called it a day and turned the page. We were not going to the concert.

A few months later, Gold Circle tickets appeared again. I sent a text message (the request) to my friends (the services), and instead of waiting, I went ahead and bought three tickets. In Italy, concert tickets are nominal. Without waiting for their response, I set their names on the two additional tickets (the downstream process kicked off by an upstream event).

Considering the time between the first attempt and this last one, it was plausible that one of my friends couldn't join anymore. If that would have happened, I would have had a nominal ticket assigned to someone not coming.

> In Italy, that's not a big deal. I went to many concerts, and no one ever checked the names on the tickets. We're so good at promulgating new laws and then ignoring them.

For concert tickets, there are a couple of options:

- The vendor offers a process to change the name and replace the ticket with a new one.
- The ticket can be sold through a secondary ticketing channel, and the name can be substituted.

Even if the process might sound complex, real life always offers ways to compensate. It can be straightforward or cumbersome and expensive, but there are options.

So, in essence, to answer Alisher's question:

> But what about events that were already propagated downstream? I can't really send compensating event like "actually, it didn't happen."

The system will send an "actually, that didn't happen" event to allow downstream components to do whatever they need to compensate for any previous action.

At this point, one could argue that the order of messages matters. If the "that didn't happen" comes before the "it happened" event, we might be in trouble. Well, we might be, and for that reason, a while ago, I wrote ["Isn't A supposed to come before B? On message ordering in distributed systems"](https://milestone.topics.it/2021/10/20/isnt-a-supposed-to-come-before-b.html).

## Is all that more complex?

It's indeed more complex. However, it is in a way that makes it simpler and less obscure.

In a non-message-based system, reverting a change could be as simple as deleting a bunch of rows in a database. There is a high chance such a data-related operation is much more obscure and not so self-explanatory as a series of business-related messages.

When I wrote ["Is it complex? Break it down!"](https://milestone.topics.it/2022/01/03/is-it-complex-break-it-down.html), I had precisely that in mind. Approach big, complex, and maybe ugly business scenarios by breaking them down into more manageable chunks of work and connecting them using business-expressive messages.

## Conclusion

At first sight, the ramifications of publishing a message that downstream components handle might seem like an irreversible operation. Mainly because we have designed the system with [autonomy](https://milestone.topics.it/2022/09/05/autonomy.html) in mind, and we know an upstream component cannot demand a downstream one to perform specific operations. That's bad; it's coupling!

Not all hope is lost. We can look at real life and model with messages what a group of humans would do without technology to compensate for what already happened. We'll probably write more code than a straightforward SQL delete statement, but it matches the business scenario. [And that's a good thing!](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html)

---

Photo by <a href="https://unsplash.com/@markuswinkler?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Markus Winkler</a> on <a href="https://unsplash.com/photos/green-and-white-typewriter-on-black-textile-7EwWeNyzSwQ?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
