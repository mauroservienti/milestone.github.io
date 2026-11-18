---
layout: post
title: "ADSD, now what? A map for the road after the course"
author: Mauro Servienti
synopsis: "Udi Dahan's Advanced Distributed Systems Design course packs a lot into a few days. The blog now has a curated page of resources, organized by course topic, to keep going once the course is over. Here's what's in it and how to use it."
header_image: /img/posts/adsd-resources/header.jpg
related:
- 2026-12-16-finding-service-boundaries.md
- 2019-02-06-what-is-services-viewmodel-composition-again.md
tags:
- soa
- distributed-systems
- training
---

Udi Dahan's [Advanced Distributed Systems Design](https://particular.net/adsd) course, ADSD for friends, is a lot. The online version is 33 hours of video. Fallacies, coupling, messaging, service boundaries, UI composition, CQRS, sagas, and a migration strategy for the big ball of mud we all have at home.

<!-- TODO: a personal hook. When did you take the course, or what made you build the page? -->

It's the kind of content that doesn't sink in on the first pass. The questions come later, when we go back to work and try to apply what we heard. Where did Udi talk about that? Is there a sample? Did someone write it down better than my notes?

That's why the blog has an [ADSD resources page](https://milestone.topics.it/resources/adsd/). It's in the Resources menu, and it's probably the least visible page on the site. Let's fix that.

## What's in it?

The page follows the flow of the course. Each section is one course topic:

- **The foundations:** the fallacies of distributed computing, coupling, and bus vs. broker.
- **The architecture:** service-oriented architecture, finding service boundaries, UI composition, and CQRS.
- **The behavior:** long-running processes and sagas, and domain modeling in an SOA context.
- **The way there:** evolving from a big ball of mud, observability, and NServiceBus tooling.

After the course topics, there are foundational papers and books, talks and webinars, community notes and course reviews, related blogs, and samples and demos.

Each section mixes external resources, such as Udi's blog posts, Particular articles, papers, and talks, with related articles from this blog. All in all, more than 150 links, each with a line on why it's worth your time.

## How to use it

It's not a reading list to go through from top to bottom. Please don't. It's a map.

When something from the course doesn't click, jump to the topic and pick what fits. Prefer reading? There are articles. Prefer watching? There are talks. Prefer code? There are samples, including the demos from my talks on [aggregates](https://github.com/mauroservienti/all-our-aggregates-are-wrong-demos), [sagas](https://github.com/mauroservienti/welcome-to-the-state-machine-demos), and [UI composition](https://github.com/mauroservienti/designing-a-ui-for-microservices-demos).

Haven't taken the course yet? Start with the first and the last sections. The first one links to the free [Distributed Systems Design Fundamentals](https://learn.particular.net/courses/distributed-systems-design-fundamentals-online) course, a good way to find out whether the full course is for you. Course reviews and community notes, near the end, give an idea of what to expect, from people who aren't me.

> Yes, I work at Particular Software, the company behind the course. Take my enthusiasm with a grain of salt, and theirs at face value ;-)

## One section that isn't in the course

The last section covers Dynamic Consistency Boundaries (DCB), a pattern Sara Pellegrini introduced in her "Kill Aggregate!" talk. DCB comes from the event sourcing community, not from ADSD. However, its take on consistency and aggregate design connects directly to the course's themes of data ownership and service decomposition. If the "All our aggregates are wrong" part of the course made you uncomfortable, DCB is a good next stop.

## Conclusion

The course gives the ideas. Applying them takes time, practice, and a lot of going back to the sources. The [ADSD resources page](https://milestone.topics.it/resources/adsd/) is where I keep those sources, organized so that finding the right one takes less time than remembering where I saw it.

The page is alive. When I find something worth adding, it goes there. If you know of something that should be on it, let me know.

<!-- TODO: how should readers suggest additions? A GitHub issue on the blog repository, a comment, LinkedIn? -->
