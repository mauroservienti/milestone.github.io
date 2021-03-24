---
layout: post
header_image: /img/posts/to-api-or-to-not-api/header.jpg
title: "To API, or not to API. Is this a real problem?"
author: Mauro Servienti
synopsis: "Breaking a public API is scary but sometimes unavoidable. Versioning an API is complex and error-prone. In many cases, I observed teams breaking an API that should not have been there to begin with, or fighting with versioning issues. The problem, though, was not the API."
tags:
- Design
- Architecture
- SOA
- Coupling
- Versioning
---

I'm taking this opportunity to answer another question that got asked during one of my recent presentations:

> How do you design evolvable APIs in a distributed system?

Before being able to answer that question, we need to dive a bit into the problem space and ask a different question first:

> Where do we need APIs?

One could argue that we need APIs in three places:

1. To serve content to the UI (or to clients consuming data, UI is one of these)
2. To integrate with third parties
3. To allow cross-service communication 

Let's start from the end. In ["Slice it"](https://milestone.topics.it/view-model-composition/2019/04/09/slice-it.html), I introduced vertical slices and their relationship with the ViewModel Composition architectural concept. In my ["All our aggregates are wrong"](https://milestone.topics.it/talks/all-our-aggregates-are-wrong.html) talk, I look at vertical slices from a slightly different angle. Towards the end, I state that once we have full vertical slices, thanks to service isolation, cross-service communication can be implemented using thin events that can be as thin as `Name` and `Identifier`.

![slide screenshot](/img/posts/to-api-or-to-not-api/screenshot.png){:class="img-fluid mx-auto d-block"}

> The presentation recording is available on YouTube; for example, [this one from the NDC Conference](https://youtu.be/hev65ozmYPI) in Copenhagen.

The essence is that there is no cross-service communication of any sort that requires sharing data. That means we don't need APIs to allow services to invoke other services. If the owning service already stores, there is no need for a service to request any data from other services, or microservice if you will. If data is misplaced, then we have a service boundaries problem that we need to address.

Services use messages to communicate. One could argue that messages are an API, messages have contracts, and expose an API surface to all services. That's correct. However, if data is already in the right place, we can design extremely thin messages. A message that crosses service boundaries can be as light as its name and identifiers (e.g., primary keys). As I say, primary keys don't change; if in your system, primary keys schema change over time, you have a much larger problem.

If there is no need for APIs to allow services to talk to each other, we're left with the other two scenarios: third parties integration and UIs. They are not different scenarios; most of the time, we look at them from different angles because they come with additional requirements and implementations. However, from a data exposure/sharing perspective, they are the same thing. In both cases, we're crossing a boundary. The only notable difference might be that we're pushing data in integration scenarios, and in UI type of scenarios, clients pull data.
When exposing an API to a third party, we're letting data flow from the system to the third party. When exposing an API to a user interface, we're letting data flow from the system to the users' devices. We don't have control over the third party as we have no control over the client device. The fact the on the client device, there is an HTML output rendered by our web application gives us the illusion of control.

Let's dive a bit into the problem space before looking at possible solutions. We all agree that we have zero control over third-party software systems. That's set in stone. When it comes to the user interfaces or the client applications that we develop, it's easy to fall into the "we control it, because we develop it"-trap. If the client application runs on a device and is intermediated by a store, like the Google Play Store or the Apple Store, they have control we don't. We decide when to release; they choose when to deploy. And users choose when to update.

A similar problem applies to single-page applications, SPA. The SPA is nothing else than a browser-hosted rich client. By being a rich client, users control when they press F5 to refresh the browser. Sure, we can nudge them. However, if we want to be loved, we cannot force them to update; imagine a user's reaction in the middle of long UI-intensive work faced with a forced-update that will cause all unsaved work to be lost; they would hate us. The only user interfaces we have full control of are the ones that do nothing: read-only user interfaces or APIs that support only the "get" verb.

The described problem is not limited to distributed systems. It's a common one. I'd argue it's a problem for every large system, which probably comes with a sizable public API surface, and for all systems with a vast and diverse client device base. The more clients a system has, the more likely it is that there is zero control.

## Conclusion

The conclusion we can draw is that we have to support public APIs more or less forever. Sure, we can deprecate them at a certain point. It's common practice to state that with a specific version, an API subset is deprecated, and starting the following version, it'll be removed. Such an approach usually gives enough time to prepare for the upgrade. For example, take a look at what [Cloudflare has been doing recently](https://blog.cloudflare.com/deprecating-cfduid-cookie/).

The drawn conclusion allows me to identify a few practices:

1. Share the minimum required: the more data shared, the higher the breaking change risk. Do not allow clients to consume data that they don't need.
Intermediate data access with proxies: having a "proxy in the middle" kind of thing allows injecting transformation logic and rules into the data consumption pipeline to guarantee backward compatibility. For example, the [ViewModel Composition](https://milestone.topics.it/categories/view-model-composition) API style is based on a reverse proxy architecture style.
2. Do not leak private details: data shared through an API is flowing out of our control. To reduce at the minimum the versioning impact, we can apply the same proxy logic (2) to the API DTO schema. For example, suppose we need to put a primary key in the DTO. In that case, we should avoid putting the database's primary key and instead use a proxy one to protect the public API from internal schema changes (if we are terrified that primary keys can change).
3. Use API versioning techniques like headers versioning or URL versioning. Inject into the URL the API version, for example, `/api/{version}/customers/{id}/orders`, or document that clients can request access to a specific version of the API adding a `version` header to their requests.
4. Consider technologies like GraphQL that approach the problem from a completely different angle: GraphQL, for example, drives us in designing an API that is client-driven and not server-controlled, leading to a situation where versioning is rarely required. GraphQL is not a silver bullet; it comes with its challenges.
 
It's always a trade-off.

---

Photo by <a href="https://unsplash.com/@randallbruder?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Randall Bruder</a> on <a href="/collections/1702019/api?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
