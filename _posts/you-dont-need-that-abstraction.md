---
layout: post
header_image: /img/posts/you-dont-need-that-abstraction/header.jpg
title: "You don't need that abstraction"
author: Mauro Servienti
synopsis: "Abstractions, abstractions everywhere! We're obsessed with clean design and architecture. Do we need that, or does the introduced cognitive load come with more issues than benefits?"
tags:
- architecture
- soa
---

One of the beauties of service-oriented architecture (SOA) is simplicity.

## WAT? Aren't distributed systems more complex by definition?

Well, yes. But also no. In my experience, overall, a distributed system comes with slight complexity differences compared to a monolithic architecture. It's where the complexity is that is important and dramatically changes the day-to-day experience.

With a monolithic architecture, the entire system is at our disposal. Adding a reference to a project in the solution is trivial, and our preferred IDE IntelliSense will immediately show new types and new members. That is like honey for bees: it's hard to resist temptation. It's effortless to steer away from a well-designed monolithic architecture.

If that happens, or preemptively in an attempt to prevent that happening, we build abstraction layers. We cannot reference a project and use the defined types because they are internal or private to the package. Instead, we have to use that other package that ships the abstraction as interfaces. Finally, we must introduce dependency injection (DI) and inversion of control (IOC) techniques to resolve the concrete types at runtime.

Even if, on the surface, the architecture sounds clean, there is a lot of magic going on. When things go badly, and an error occurs, it's more complex to track what's happening.

My biggest concern with magic and I'm the first at fault, is that it's addictive. Once we start depending on magic, we want more magic, and the system becomes a big spaghetti mess with magic sauce.

The second reason why we need all those abstraction layers with monolithic architectures is testing. We need to mock dependencies so that we can unit test components in isolation.

Don't get me wrong; testing is a good thing, crucial, I'd say. However, here the problem is that integration testing is arduous or even impossible due to the monolithic nature of the system. That leads the design to need abstraction layers.

[Derek Comartin](https://codeopinion.com/) puts it very nicely in ["What's the cost of indirection & abstraction?"](https://codeopinion.com/whats-the-cost-of-indirection-abstractions/):

> The benefits are reuse, isolating complexity, encapsulation of dependencies, and more. But what's the cost of indirection & abstractions? Cognitive load to fully understand all of the layers of a request and limiting functionality.

## The SOA way

A service-oriented architecture can have a dramatic impact on the way we approach all those abstraction layers. Again, don't get me wrong, it's possible to design an utterly flawed SOA-based system, something usually referred to as a distributed monolith. However, SOA removes some of the barriers mentioned above that lead to the need for abstraction layers.

Autonomous components are one of the SOA building blocks. They are the essence of the single responsibility principle in a distributed system. Autonomy comes with significant advantages, one of which is isolation. A component that is both autonomous and isolated is also independent. Independence means that we're free to host it alone.

If a component has all the mentioned attributes, it can be easily tested, which is true in a monolithic architecture. What's different is the hosting aspect. If we can host a component alone in its process, [integration testing](https://milestone.topics.it/2021/04/07/nservicebus-integrationtesting-baby-steps.html) comes at ease.

If integration testing is one of the tools in our toolbox, there is less need for abstraction layers. An autonomous component whose responsibility is to deal, for example, with loyalty points in an e-commerce system, can directly access its storage without an abstraction layer. We can quickly test the composition with the storage as a dependency. That is especially true nowadays, thanks to containers. It's never been so easy to spin up a dependency, like SQL Server or PostgreSQL, like it is today.

Also, autonomous components drive more adherence to the single responsibility principle, and [NServiceBus message handlers](https://docs.particular.net/nservicebus/handlers/) are an excellent example. It means that the component can do one thing at a time. There is no simple workaround. It's much easier and riskier to add a method to a class in a monolithic architecture rather than adding additional behaviors to an autonomous component in a distributed system. There is so much more friction that we don't even try.

Finally, code simplicity comes with less cognitive load.

However, distributed systems come with their own set of complexity. Monitoring and debugging are representative samples of things that are harder than in monolithic architecture.

## Conclusion

As always, there is no silver bullet. The important message is to try to avoid unnecessary abstraction layers. That is especially true if the only purpose of the abstraction is clean architecture. It's effortless and sometimes satisfying to build abstraction layers for the sake of building abstractions. It's indeed over-engineering, but on the surface, it's a rewarding type of over-engineering. It's like honey for bees.

---

Photo by <a href="https://unsplash.com/@amenabarladrondeguevara?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Ignacio Amenábar</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
