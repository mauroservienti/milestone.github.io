---
layout: post
author: Mauro Servienti
title: "Do we need to debug distributed systems?"
synopsis: "We're humans. We are designed to apply previous experience and knowledge to new problems. When faced with distributed systems, we want to debug them. Do we need that? And, can we debug distributed systems?"
header_image: /img/posts/do-we-need-to-debug-distributed-systems/header.jpg
tags:
- distributed-systems
---

Human beings are resistant to change. Simultaneously, we prefer reusing what we already know. That's understandable. By reusing, we apply existing experience to new problems, and we avoid inventing new solutions for what might be the same problem under a new vest.

When we're presented with a distributed system, in its more straightforward form, two different processes communicating over a channel (e.g., HTTP), we apply previous knowledge and ask: "how do we debug that thing?". And we mean it literally: how do we debug, as in how do we set a breakpoint in one process, another one in the second process and observe the code flow from one to the other. Exactly like if we were debugging procedural code in a monolithic process.

> In this post, I'm referring to debugging in the context of automated debugging tools in an IDE.

Let's pause for a second and discuss why we feel the need to debug. Generally, that's connected to complex design, spaghetti code, or lack of tests. Mind that I'm not saying that the opposite is true. Simple design, simple code, and tests don't eliminate the need for debugging. However, they significantly reduce it.

Complexity makes it hard to understand what's happening, especially when observing unexpected behaviors. To untangle complexity, we need to go through every step to detect where the issue is.

One way to deal with complexity and its consequences is to untangle it earlier. Componentization is a way to reduce complexity. If we design components following the single responsibility principle (SRP), we can produce smaller black boxes that we can test and understand better, reducing the need to resort to debugging.

Another way to reduce complexity is to remove [unnecessary abstractions](https://milestone.topics.it/2021/12/20/you-dont-need-that-abstraction.html). Abstractions can increase the time it takes to fully grasp what's going on by looking at a piece of code.

Can we state that componentization and fewer abstractions lead to more testable code? I think so, yes. However, it's the wrong question. We should be looking for more test effectiveness than more testable code.

We need to be aware that if we go too far with componentization, we risk ending up with somewhat anemic components that are trivially easy to test but meaningless from the business perspective. We want to look for a signal when we need to use many components to satisfy a business requirement. That is a sign that we probably pushed too far toward componentization. It's hard to give away numbers. However, my rule of thumb is that there isn't a one-to-one relationship between business requirements and components. At the same time, it's not one-to-fifty either.

My favorite signal is when there are _too many components to address one business requirement_: You probably experienced it yourself. Investigating a web application, for example, controllers are invoking business services. Business services depend on repositories, and finally, repositories access the database. There is little to no value in all these hops. It's hard to see where the business process is happening. In many cases, all those abstractions are there to return some DTOs to the caller. Again, we need to question whether we need an abstraction.

When designing a distributed system, we tackle complexity by [breaking the system apart](https://milestone.topics.it/2022/01/03/is-it-complex-break-it-down.html). The result is autonomous components that can be tested in isolation and are also meaningful from the business perspective. The goal is simplicity; distributed systems are already complex enough that we don't want to add additional complexity by, for example, introducing unneeded abstractions.

It seems to me we have a good enough answer to the opening question. We don't need to debug distributed systems. We might need to debug autonomous components in isolation. That's fine. Those are regular classes that we can test and debug.

A more appropriate question might be: can we debug distributed systems? And the answer is no, not really.

We can build distributed systems samples with debugging in mind. Compared with the real world, they are trivial and, in many cases, full of hacks to make them runnable from a developer's machine. For example, we build them using one tech stack like .NET.

Let's face it. Do you think there is a locally installable version of the "amazon.com" solution? That we can open our favorite IDE (Integrated Development Environment) and start a debugging session?

Not to mention that we don't have a single stack trace or memory dump. We'll have multiple of those coming from different machines. Everything will be more complicated thanks to [clock drift issues](https://en.wikipedia.org/wiki/Clock_synchronization). It makes it harder to understand what happened before what.

## Conclusion

When faced with new challenges, it's OK to apply previous experience and reuse what we already know, including the tools we're acquainted with. Simultaneously we need to be careful. We may want to pause and step back and evaluate if our approach fits the challenge. There is a chance that the set of available tools is inadequate, and we need to learn something new or apply different techniques.

For more information, you can reach out to me or my dear friend and colleague [Laila](https://twitter.com/noctovis), who's [presenting on the topic](https://techorama.be/speakers/session/message-processing-failed-but-whats-the-root-cause/) at Techorama.

---

Photo by [Jonathan Kemper](https://unsplash.com/@jupp?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
