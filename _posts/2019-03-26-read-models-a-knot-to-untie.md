---
typora-copy-images-to: ..\img\posts\read-models-a-knot-to-untie
typora-root-url: ..
layout: post
header_image: /img/posts/read-models-a-knot-to-untie/header.jpg
title: "Read models: a knot to untie"
author: Mauro Servienti
synopsis: "Read models can be a tempting solution when it comes to presenting data in a distributed system. Before going down this route it's important to disclose the very nature of the choice we're going to make. It's a knot to untie."
tags:
- soa
- viewmodel-composition
category: view-model-composition
redirect_from: "/2019/03/26/read-models-a-knot-to-untie.html"
---

When dealing with distributed systems it's very tempting, and apparently easy and simple, to solve the "we need to present data to users" problem by building read models. Read models designed to satisfy presentation requirements, containing data coming from different services.

> This series of articles is not focused on CQRS. There are amazing resources available out there about the topic.

## Choices

Traditionally read models are presented in a very fancy way. I performed a [Google Images search](https://www.google.com/search?q=read+model&source=lnms&tbm=isch&sa=X&ved=0ahUKEwii7OfopJ_hAhVKsaQKHT3rCc0Q_AUIDigB&biw=1707&bih=818) and picked one:

![Related image](https://i.stack.imgur.com/eKU6r.png){:class="img-fluid mx-auto d-block"}

Most of the proposed implementations imply that there is some sort of synchronization between the write storage, `RDBMS` in the image, and the read storage, the incredibly fast thing.

There is nothing preventing us to sync, in some way, data from different services to the incredibly fast read storage. For example:

- *Marketing* sends name and description.
- *Sales* sends price.
- *Warehouse* sends availability.
- *Shipping* sends shipping options.

Given that all services share the same identifier, a _Product_ read model can be crafted and stored.

### Keep It Simple Stupid

Is there a simpler solution? So far we've used code snippets like:

```csharp
class SampleHandler : IHandleRequests
{
   public bool Matches(RouteData routeData, string httpVerb, HttpRequest request)
   {
      /* omitted for clarity */
   }
   
   public async Task Handle(dynamic vm, RouteData routeData, HttpRequest request)
   {
      /* omitted for clarity */
   }
}
```

the infrastructure executing the above code could, at runtime, store the resulting ViewModel, the `dynamic vm`, in a dedicated incredibly fast storage, and query that storage for all subsequent requests for the same URL. We've basically created a read model at runtime at the first request. So far, so good.

### You know what?

*That's a cache*. It's the sad truth, but we should be honest with ourselves: what we just designed is a cache.

## Cache introduces an ownership dilemma

As soon as the solution is identified for what it is, and especially given the distributed system context, it immediately shines as something we probably don't want.

> Caching comes with its own set of issues, distributed caching is far worse.

One of the biggest architectural issues that comes along with caching composed read models is that there is no service owning it anymore.

### Businesses change their mind

A business requirement in _Marketing_ could change the way data should be presented to users, in essence invalidating all the cached read models. _Marketing_ doesn't own the resulting model, thus the only option we're left with is to invalidate the whole set. _Product_ read models are wiped from the "cache" and:

- in the first scenario, the fancy diagram, we end up with an incredibly fast but empty read storage. The storage needs to be re-synchronized, with the risk of huge delays
- in the second scenario, the cached ViewModel, we end with an empty cache that has to be gradually rebuilt

In both scenarios we'll end up with a huge load on the entire system. All services will be hammered, in one way or another, for the sake of nothing since the only thing that changed is _Marketing_.

This is very good sample of coupling.

### Not everything can be cached

_Shipping_ owns shipping options. Shipping options depend on the currently logged in user. If they live in Italy and are trying to ship from the US, available options are different than if they live in the US. It might even happen that something is not available at all if shipped outside of the US.

This simply means that shipping options need to be evaluated on the fly, for each request, taking into account different factors.

Shipping options cannot be cached, unless we want to cache all possible combinations.

## Conclusion

Read models are an interesting solution, and like all solutions they are not a silver bullet. We described two scenarios in which read models cause pain that we can avoid by using ViewModel Composition. This doesn't mean that read models should be avoided like the plague: they have their place, and we'll talk about that in a future article. There is a place for caches as well, but we need to uncover full vertical slices first.

#### Articles in this [series](https://milestone.topics.it/categories/view-model-composition):

- [What is Services ViewModel Composition, again?](https://milestone.topics.it/2019/02/06/what-is-services-viewmodel-composition-again.html)”
- [The Services ViewModel Composition maze](https://milestone.topics.it/2019/02/20/viewmodel-composition-maze.html)
- [Into the darkness of ViewModels Lists Composition](https://milestone.topics.it/2019/02/28/into-the-darkness-of-viewmodel-lists-composition.html)
- [ViewModel Composition: show me the code!](https://milestone.topics.it/2019/03/06/viewmodel-composition-show-me-the-code.html)
- [There is no such a thing as cross-service ViewModel Composition](https://milestone.topics.it/2019/03/13/there-is-no-such-a-thing-as-cross-services-composition.html)
- [The ViewModels Lists Composition Dance](https://milestone.topics.it/2019/03/21/the-viewmodels-lists-composition-dance.html)

---

Header image: Photo by [Ksenia Makagonova](https://unsplash.com/photos/KiAZ61Sh17k?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/knot?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
