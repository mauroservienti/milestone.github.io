---
layout: post
header_image: /img/posts/not-all-changes-are-born-equal/header.jpg
title: "Not all changes are born equal"
author: Mauro Servienti
synopsis: "We should not fear change. There are changes for good and changes for bad. As for change, we should not fear coupling. There is bad coupling and good coupling. The critical aspect is to understand the impact of the changes and the coupling."
tags:
- Design
- Architecture
- SOA
- Coupling
---

I recently gave an online talk titled ["Live long and prosper"](https://milestone.topics.it/talks/live-long-and-prosper.html). The conference session is in Italian and available on [YouTube](https://www.youtube.com/watch?v=YOJ0rQ2gn44). Unfortunately, the only recording of this conference session is in Italian; hopefully, I'll deliver the English version again soon and get the recording published.

During the usual after talk Q&A session, I had the opportunity to answer questions, among which the following two gave me the idea to write this post:

- Shouldn't a Microservices/Distributed architecture facilitate the ability of the system to change?
- Is it possible that a new business vision invalidates service boundaries?

> Original questions were in Italian; I took the liberty of translating them.

The short answer, a telegraphic one, to both questions is: yes. The longer answer requires a bit of history and requires starting from a different point of view.

## Coupling

We're terrified of coupling. We spend countless hours discussing how bad it is. And in the end, we risk overengineering the design and the solutions we put in place.

To begin with, why are we terrified by coupling?

Historically we've been brainwashed that "coupling is bad." Each of us has probably been bitten by coupling once or twice in our career, leading a project to end badly or fail. And once burned a couple of times, it's easy to become overcautious.

Let's step back for a second and ruminate on coupling. First, zero coupling is impossible. Zero coupling is one of those utopian goals not that different from a completely secure computer. An utterly safe computer is not connected to anything, including a human being. A zero coupling architecture is an architecture that does nothing; there is no connection between all the parts composing it.

When designing a system, the goal is to reduce coupling where it makes sense, accept coupling where it makes sense, encourage coupling where beneficial, and do not try to fight coupling where there is nothing to fight.

### Hold on, can coupling be beneficial?

Yes, it can. Let's use a logging library as an example. If we're designing a component to be used by others, we need to allow users to plug in the logging library they want. In this situation, the traditional approach is to rely on an interface, something like `ILogger`. The component we're designing depends on `ILogger`, and the user, when using it, will provide an `ILogger` implementation. This approach decouples our code from the logging library implementation details, and users can provide their logging library, whose only requirement is to respect the interface contract.
On the other hand, we want to couple code to the `ILogger` interface. If our code wasn't coupled to the interface, it means that we're not logging. Remember that zero coupling implies that we're doing nothing.

### What kind of coupling do we want to avoid?

The kind that forces us to make changes in portions of the codebase that, theoretically, should not be affected by the original change. When designing software, we encapsulate the data access logic so that any infrastructure change does not affect the infrastructure data access utilizer. The architecture uses encapsulation as a form of decoupling. The interface decouples the invoker's internal implementation; thus, any change to the implementation doesn't affect the caller. We can extend this sample to distributed systems and say that a shift in the internal behavior of a (micro)service should not affect any other (micro)service. If a cascade change occurs, they are coupled, which is probably not a good sign.

A real-life example would be something like this:

> If a company stores its goods in a warehouse, whether the warehouse is automated or not is irrelevant for other departments, e.g., marketing.

In other words, any change to the internal implementation of the warehouse is not visible to the outside. They are decoupled.
Another example is a new discount or pricing policy. If to change the pricing policy, there is a need to change multiple services, e.g., a products service and a sales service because product prices are in products, and the discount logic is in sales, it's clear that we have a coupling issue.

At this point, usually after a talk at a conference, people come to me with objections like this:

> What if a company that manufactures cars decides to start manufacturing also clothes? That has an impact both on the marketing department and the warehouse.

And many other services, I'd say. Usually, they continue with:

> the presented design/solution/idea doesn't address this problem. See, they're coupled anyway, so why bother?

We're not here to solve that kind of problem. Remember, earlier I said "reduce coupling where it makes sense and accept coupling where it makes sense". Does it make sense to design for the possibility that your car factory might, at some point, produce designer underwear? Maybe in some parts of Italy but for the rest of us, probably not.

That's a disruptive business change that is not that different from creating a new company that requires everything fresh from scratch, including a software system. There is no point in designing a software architecture that tries to absorb this type of change nicely. It's not a coupling problem.

As a side note, you can see the problem at play in many webshops. If you look for products defined by multiple attributes, like clothes, you'll notice how bad they are at managing them. The UI and the overall buying experience are not optimized for those types of products. The same goes for the search experience that doesn't factor in those attributes. Many sellers create a separate product for each combination of attributes, which is a bit better for them. However, it is still a problem for customers because the same shoes end up having multiple product SKUs based on different colors and sizes, and searching is always painful. It seems they prefer forcing sellers to adhere to the current status quo rather than coming up with a change that would probably affect many various services. That's understandable; the original domain was a different one, and the requested changes are disruptive because of the drastically different domain.

## Conclusion

Whenever we design a software system, we should look at the coupling impact from different angles and in the context of the requirements we're implementing. As we saw, there is a coupling that we should avoid, one that we should embrace, and even one that we should not consider. Coupling is not marred by design. Hopefully, this article also answers the questions raised; if that is not the case, please leave a comment, and I'd be more than happy to discuss further.

---

<span>Photo by <a href="https://unsplash.com/@markusspiske?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Markus Spiske</a> on <a href="https://unsplash.com/s/photos/different?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></span>
