---
layout: post
header_image: /img/posts/ok-mauro-but-i-want-to-do-paging-and-sorting/header.jpg
title: "OK Mauro, but I want to do paging AND sorting"
author: Mauro Servienti
synopsis: "Paging and sorting can be applied in isolation, even in distributed systems. When in need of paging AND sorting, the level of coordination required grows exponentially. It turns out that the problem is not that different from searching in distributed systems, and similar techniques can be used to address the paging and sorting dilemma."
tags:
- SOA
- Services ViewModel Composition
category: view-model-composition
---

It's a kind of [tornado of souls](https://www.youtube.com/watch?v=K-HzFACAedk) here. Coronavirus is all around where I live, and _smart working_, as Italians call remote working, is all the rage. Articles, posts, and twitter threads are all about how to be great at remote working.

One way or the other, I've been working remotely for the last ten years or so, and in the last six years, I've been 100% remote working.
Don't worry. I don't want to talk "remote working," at least not today.

This post assumes that you've read ["Paging and sorting in distributed systems, oh my!"](https://milestone.topics.it/view-model-composition/2020/01/27/paging-and-sorting-in-distributed-systems-oh-my.html) article. If this is not the case, go and read it. I'll wait here.

As you probably noticed, the approaches described to page data and sort data work in isolation, but immediately fall apart if we need to use them together. If the need is to apply "paging and sorting" in the same request, then the proposed solutions cannot be applied. Or, if implemented, can only result in a very chatty and performance-avert design.

## Paging and sorting is misleading

Data sorting needs to happen before paging can be applied. If we page and then sort, we're going to sort only the current page, which means that if the user transitions to another page, the sort doesn't make sense anymore. It should be "sorting and paging," but that sounds bad.

The problem is that if we have to sort first and the request coming in is like `/products?orderBy=price,description` then, as we already said, sorting is not so easy. The request reveals a relationship between the service owning prices and the service owning descriptions. If data are not in the same storage, the only option is first to load all the prices and sort them, then hand the result set over to the service that can load all the descriptions and sort the result set based on price and description. Only at this point paging can be applied.

## That's a join, Mauro

If we were to apply the outlined logic manually, it's like we're reinventing the wheel. And we've already discussed something very similar recently.

When we talked about searching in distributed systems, the suggestion was to ship data into a common place best suited to perform a search. The same rule applies here. If the need is to sort data across multiple services and apply paging to the sorted result set, it's way simpler to perform all these steps in a single place, for example, a SQL database or an Elasticsearch instance.

[Tomek](https://twitter.com/masternak) and I discussed at length how to do that in [The Quest for Better Search](https://milestone.topics.it/soa-search/2019/05/15/the-quest-for-better-search.html) and the follow-up [Search is a Team Effort](https://milestone.topics.it/soa-search/2019/05/22/search-is-a-team-effort.html). It's just a matter of applying the same logic in this case.

## Conclusion

When designing distributed systems, one of the goals is to keep coupling as low as possible. Zero coupling is an illusion, and we want to have in our tool belt all the tools that we might need to keep coupling low. Do we need to apply paging? We understood how to do that with almost no coupling. Do we need to sort data? It can be done. Do we need to sort and page data? Sure, there is a solution to that as well, but this time comes with a little coupling. As for searching, we want to be very careful and make sure that only data required to apply the sorting end up being stored in the storage. We don't want to pay the price of unneeded coupling.

---

Header image: Photo by [Kai Pilger](https://unsplash.com/@kaip?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/s/photos/no?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
