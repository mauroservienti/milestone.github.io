---
layout: post
header_image: /img/posts/linguistic-limitation/header.jpg
title: "A linguistic limitation"
author: Mauro Servienti
synopsis: "The language we use is crucial to get the right message through. The words we use have to be as specific as we can to avoid misunderstandings. It seems we have space for improvement, and we should be doing a better job."
tags:
- ubiquitous language
---

I have a feeling this is going to be a short one. I have no answers, only doubts.

A couple of weeks ago, I was chatting with a friend, discussing some architectural designs. At a certain point, we mentioned publishing an event as a solution to one of the issues. All of a sudden, we stopped and asked the question: what kind of event? A domain event or a pub/sub-one?

As a result, we stopped discussing the initial architectural concern and moved to a completely different topic: the ubiquitous language or the lack of a proper one.

Martin Fowler [defines the ubiquitous language](https://www.martinfowler.com/bliki/UbiquitousLanguage.html) as follows (emphasis is mine):

> Ubiquitous Language is the term Eric Evans uses in Domain Driven Design for the practice of building up a common, *rigorous language between developers and users*. This language should be based on the Domain Model used in the software - hence the need for it to be rigorous, since software doesn't cope well with ambiguity.

We were not in the context of a discussion between developers and users, and we were not discussing any business concerns. The sentence that triggered the follow-up discussion was more or less the following:

> The endpoint could initiate the process by raising an event. It'll make the background processing asynchronous.

I immediately see three points of confusion. What's an endpoint? Is it an HTTP endpoint, a ReST endpoint, or something else entirely?

The second issue, and it's a worse one, is the word event. Is that a domain event? Or is that a pub/sub kind of event? It's also worth noting that these two questions assume that it's an event on a queue. What if it was a plain old C# event, a simple delegate in a linked list invoked in process on the same thread as the publisher?

Defining what an event is might be even trickier than defining what an endpoint is. Luckily, in both cases, we can use a companion word to bring clarity:

> The HTTP endpoint could initiate the process by raising a pub/sub kind of event. It'll make the background processing asynchronous.

It's much better now. We communicate that the publisher is an HTTP endpoint and the type of the event is a pub/sub one, which implies being a lightweight kind of message in contrast to a domain event that would be richer in information. Theoretically, we could also shorten the sentence to:

> The HTTP endpoint could initiate the process by raising a pub/sub kind of event.

There is no need to specify that processing will be asynchronous. It's implicit with the decision to use a message on a queue (though it doesn't hurt to be explicit either).

Asynchronous, though, is the third concern. To be honest, asynchronous is problematic. What does asynchronous mean? Is it asynchronous as handled by a different thread? Or is it asynchronous as in a new task when using the async/await keywords? Or is it asynchronous because it's an entirely different process on another node?

Let's imagine two developers discussing a design. They are discussing how to handle an incoming HTTP request. They decide that it has to be handled asynchronously. There are at least two possible implementations:

```csharp
public async Task<HttpResponseMessage> DoSomething(SomeData payload)
{
   var result = await processor.ExecuteSomething(payload);
   return Ok(result); //HTTP200
}
```

or something like:

```csharp
public async Task<HttpResponseMessage> DoSomething(SomeData payload)
{
   await queue.Send(new DoSomethingCommand()
   {
      Payload = payload
   });
   return Accepted(); //HTTP202
}
```

Both implementations are asynchronous. However, the first one, from a higher-level perspective, is synchronous. The HTTP client will wait for a response. In the second example, the processing is _genuinely_ asynchronous, and the client will wait for the completion of the request but, in the meantime, won't receive any meaningful business response.

There is no easy way out in this last scenario. No companion word comes to mind that we could use to clarify what kind of asynchronicity we're discussing.

## Conclusion 

In this article, I limited myself to three nebulous concepts: endpoint, event, and sync/async. Since the devil is in the details, it seems evident that we should prefer a more specific term to describe something rather than a more general one that may cover other things as well. We need a more precise language, raising questions about the true nature of things.

---

Photo by <a href="https://unsplash.com/@mrthetrain?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Joshua Hoehne</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
