---
layout: event
status: 'upcoming'
title: "KanDDDinsky"
header_image: /img/events/kandddinsky-2019/header.jpg
location: "H4 Hotel, Karl-Liebknecht-Str. 32, 10178 Berlin, Germany"
language: "English"
eventurl: "https://kandddinsky.com/"
calendar:
  start: "2019-10-17"
  start: "2019-10-18"
  display: "October, 17-18"
sessions:
- title: "All our aggregates are wrong"
  speakers:
  - name: "Mauro Servienti"
    profileurl: https://milestone.topics.it/about-me/
- title: "Welcome to the (state) machine"
  speakers:
  - name: "Mauro Servienti"
    profileurl: https://milestone.topics.it/about-me/
tags:
- Sagas
- SOA
- Microservices
---

## All our aggregates are wrong

It always starts well. At first glance the requirements seem straightforward, and implementation proceeds without hiccups. Then the requirements start to get more complex, and you find yourself in a predicament, introducing technical shortcuts that smell for the sake of delivering the new feature on schedule.

In this talk, we’ll analyze what appears to be a straightforward e-commerce shopping cart. We’ll then go ahead and add a few more use-cases that make it more complex and see how it can negatively impact the overall design. Finally, we’ll focus our attention to the business needs of these requirements and see how it can shed light on the correct approach to designing the feature. Walk away with a new understanding on how to take requirements apart to build the right software.

## Welcome to the (state) machine

Stateless all the thing, they say. In the last few years we’ve been brainwashed: design stateless systems, otherwise they cannot scale, they cannot be highly available, and they are hard to maintain and evolve. In a nutshell stateful is bad. However complex software systems need to do collaborative processing, that is stateful by definition. Stateless myth busted! Collaborative domains deal with long running business transactions and need to interact with distributed resources. The traditional distributed transactions approach, even if tempting, is a time bomb.

This is when Sagas come into play. Sagas allow to model complex collaborative domains without the need for distributed transactions and/or orchestration across multiple resources. Join Mauro on a journey that aims to disclose what sagas are, how they can be used to model a complex collaborative domain, and what role they play when it comes to designing systems with failure and eventual consistency in mind.

(It’s all right, I know we’re you’ve been)
