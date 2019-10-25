---
layout: event
status: 'done'
title: ".NET DeveloperDays 2019"
header_image: /img/events/net-developerdays-2019/header.jpg
location: "EXPO XXI - Pradzynskiego 12-14 Str. - Warsaw"
language: "English"
eventurl: "http://net.developerdays.pl/"
calendar:
  start: "2019-10-23"
  start: "2019-10-25"
  display: "23 - 25 October 2019"
sessions:
- title: "Designing a UI for Microservices"
  demos: http://bit.ly/dnd-wa-composition
  slides: http://bit.ly/dnd-wa-composition-slides
  speakers:
  - name: "Mauro Servienti"
    profileurl: https://milestone.topics.it/about-me/
- title: "Welcome to the (state) machine"
  demos: http://bit.ly/dnd-wa-state-machine
  slides: http://bit.ly/dnd-wa-state-machine-slides
  speakers:
  - name: "Mauro Servienti"
    profileurl: https://milestone.topics.it/about-me/
tags:
- SOA
- Microservices
---

## Designing a UI for Microservices

How do we design a UI when the back-end system consists of dozens (or more) microservices? We have separation and autonomy on the back end, but on the front end this all needs to come back together. How do we stop it from turning into a mess of spaghetti code? How do we prevent simple actions from causing an inefficient torrent of web requests? Join Mauro in building a Composite UI for Microservices from scratch, using .NET Core. Walk away with a clear understanding of what Services UI Composition is and how you can architect front end to be Microservices ready.

## Welcome to the (state) machine

Stateless all the thing, they say. In the last few years we’ve been brainwashed: design stateless systems, otherwise they cannot scale, they cannot be highly available, and they are hard to maintain and evolve. In a nutshell stateful is bad. However complex software systems need to do collaborative processing, that is stateful by definition. Stateless myth busted! Collaborative domains deal with long running business transactions and need to interact with distributed resources. The traditional distributed transactions approach, even if tempting, is a time bomb.

This is when Sagas come into play. Sagas allow to model complex collaborative domains without the need for distributed transactions and/or orchestration across multiple resources. Join Mauro on a journey that aims to disclose what sagas are, how they can be used to model a complex collaborative domain, and what role they play when it comes to designing systems with failure and eventual consistency in mind.

(It’s all right, I know where you’ve been)
