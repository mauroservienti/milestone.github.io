---
layout: post
header_image: /img/posts/own-the-cache/header.jpg
title: "Own the cache!"
author: Mauro Servienti
synopsis: "Caches are everywhere and power the internet. When it comes to distributed systems, they are an essential tool in our tool belt. However, special care needs to put into defining who owns the cache."
tags:
- Architecture
- Distributed systems
- ViewModel Composition
---

When an HTTP client invokes a remote resource, it can use the following header to (try to) control the caching logic:

```
Cache-Control: max-age=<seconds>
```

The client request instructs the server or any request handler in the middle to return a cached value for the requested resource if it's not older than the `max-age` provided value. Similarly, a server can instruct to not store the response in any caching layer by adding the following header:

```
Cache-Control: no-store
```

## Who's the owner?

No one. It's by design. And it is also the beauty of the internet.

So, is it true that no one owns the resource's cached version?

I guess the answer is two-fold. The physical ownership belongs to the caching infrastructure; for the sake of the sample, a web proxy owns the cached assets. However, the logical ownership is somewhere else. The resources belong to the server that produced them in the first place. It's the server that can affect the lifecycle of the cached items (e.g. `no-store`).

## There is no such thing as "partial" invalidation

The owner of a cached resource can request the invalidation of one or more cached items. For example, let's imagine that we cached the HTML response of a web request. The server can set the `Expires` HTTP header, or the `Cache-Control` one, to indicate to the caching layer how long the resource should stay in the cache. However, the owner cannot request partial invalidation. For example, a server cannot add an HTTP header telling a caching infrastructure to remove from line 20 to line 25 of a cached HTML asset.

The main reason for the lack of partial invalidation is the inherent complexity the protocol clients would need to use to understand what to do. For example, imagine a client requesting a remote resource. Upon a HEAD request, the server replies with a "hey, it's cached, but I'm not sure if it's all cached." The client then needs to go to the caching layer to request the cached resource, discover if something is missing, and go back to the server, asking what's missing. At the same time, the server needs to know how to retrieve only the missing parts; otherwise, it's a waste of resources.

We don't want to design such complex systems, hence the decision not to support partial invalidation.

> It's true that ASP.NET supports partial responses (HTTP 206). However, it is primarily used for binary range requests when downloading large files. I'm not sure there is any way to build partial cache invalidation on top of that. More information in [HTTP Range Requests and Partial Responses With ASP.NET Core](https://khalidabuhakmeh.com/partial-range-http-requests-with-aspnet-core) by [@buhakmeh](https://twitter.com/buhakmeh).

For the same reasons, we should not build read models that are not explicitly owned. Otherwise, it's like relying on a cache no one owns, which also needs to support partial invalidation. A read model no one owns is a cache. Something a nightmare would call a nightmare.

## Why and when we need read/view models

Let's dive into the problem using a sample. Let's imagine the requirement to design a product page whose only information is the product name and product price. The catalog service owns and stores the name of the product, the sales one the product price. Both of them need to be on the same page. We apply [ViewModel composition techniques](https://milestone.topics.it/categories/view-model-composition) to produce the required view model and move on. The following diagram summarizes the discussed scenario:

![cache layer in front of the composition gateway](/img/posts/own-the-cache/outside.png){:class="img-fluid mx-auto d-block"}

After a while, we realize that the frontend has some performance issues while visualizing product pages. So, easy peasy, we set up a caching layer in front of the composition gateway to cache the composed view model. After that, performance gets back under control.

## Prices change, but names don't.

What appears to be a solution turns out to be a significant issue. Over time, with variable frequency, product prices change, and web pages must reflect that. However, the whole product view model is cached. Therefore, the only option for the system is to invalidate all cached resources for which prices changed. As we demonstrated earlier, there is no such thing as partial invalidation; it makes no sense to implement it.

The variability in prices causes a significant issue for the catalog service, though. Whenever a price changes, the product view model cached version gets invalidated and removed from the cache. The next time that product gets requested, the system needs to hit the catalog service to retrieve what was previously cached but not changed. In essence, whenever prices change, the impact goes to the catalog service and not to the sales one. From the catalog perspective, the crucial aspect is that the effect is unexpected and, more importantly, unpredictable. The change is happening somewhere else, in sales.

## Caches as a source of runtime coupling

Interestingly, the lack of ownership of the cached resources is causing issues similar to what coupling between catalog and sales would have caused. The presented caching approach couples the involved services hindering their ability to evolve. In the case of the given sample, the coupling impedes or limits the ability of sales to change prices. However, a similar issue would surface if we were to change the schema of one of the services. Suddenly, all the cached resources would have been invalid, causing even a more significant impact on innocent services—an absolute tsunami of requests due to a change in one service.

## Shall we stop caching resources?

No. There is a more straightforward solution. We just need to move the caching layer inside the service boundaries. For example, the sales service needs to have its cache and maybe catalog too. If sales owns the cache, it can decide to change prices, change the schema, or randomly wipe items from the cache storage without affecting anyone else in the system. The same applies to any other service.

Given that we have [ViewModel composition techniques](https://milestone.topics.it/categories/view-model-composition) in our tool belt, it doesn't matter much the caching layer is in front or behind the composition gateway. Sure, having it behind has an impact on the overall system performance. It's probably negligible.

The following diagram summarizes the proposed solution:

![cache layers between services and the composition gateway](/img/posts/own-the-cache/inside.png){:class="img-fluid mx-auto d-block"}

One other advantage of repositioning the cache is that services can have different caching and invalidation policies. For example, the sales service can decide that product price time to live (TTL) is five minutes, and the catalog can store names and descriptions for weeks. All in such a way that they don't step on each other toes.

## Conclusion

We need caches. However, we need to be careful not to blindly accept the requirement. Where the caching infrastructure is located might unpredictably impact the architecture and even the system's runtime behavior. As in many cases when it comes to distributed systems, profoundly analyzing and understanding ownership and boundaries helps frame better solutions. If you own it, it won't hold you.

---

Photo by <a href="https://unsplash.com/@chewy?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Chewy</a> on <a href="https://unsplash.com/s/photos/owner?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
