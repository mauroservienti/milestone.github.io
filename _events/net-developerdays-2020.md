---
layout: event
status: 'done'
title: ".NET DeveloperDays 2020"
header_image: /img/events/net-developerdays-2020/header.jpg
location: "online"
language: "English"
eventurl: "http://net.developerdays.pl/"
calendar:
  start: "2020-10-19"
  start: "2020-10-22"
  display: "19 - 22 October 2020"
sessions:
- title: "All our aggregates are wrong"
  demos: https://bit.ly/dnd-2020-aggregates-demos
  slides: https://bit.ly/dnd-2020-aggregates-slides
  speakers:
  - name: "Mauro Servienti"
    profileurl: https://milestone.topics.it/about-me/
- title: "Got the time"
  demos: https://bit.ly/dnd-2020-time-demos
  slides: https://bit.ly/dnd-2020-time-slides
  speakers:
  - name: "Mauro Servienti"
    profileurl: https://milestone.topics.it/about-me/
- title: "Workshop: Building Distributed Systems with Microservices"
  speakers:
  - name: "Mauro Servienti"
    profileurl: https://milestone.topics.it/about-me/
tags:
- SOA
- Microservices
---

## Got the time

“Check if overdue invoices are paid.” Seems simple enough. But when are invoices due? Are they all due on the same day?

“Apply discounts to customers whose balance is more than $500.” Well, that sounds simple too. But are customers’ balances and discounts stable? Or do they change over time?

When designing a system from “requirements”, it’s not always easy to spot the impact of the passage of time. It’s too easy to fall into the trap of solving a business problem with a technical solution. We end up using batch jobs to try to catch up, resulting in a plate of spaghetti.

In this talk, we’ll analyze what appears to be a straightforward billing system that needs to deal with invoices and discounts. How hard can it be? We’ll then add a few more use-cases that make it more complicated and see how that can negatively impact the overall design.

Finally, we’ll focus our attention on the impact of time on the design, and see how it sheds light on the correct approach to designing features.

(All we want, two, three, go! Time, got the time tick tick tickin’ in my head!)

## All our aggregates are wrong

It always starts well. At first glance, the requirements seem straightforward, and implementation proceeds without hiccups. Then the requirements start to get more complex, and you find yourself in a predicament, introducing technical shortcuts that smell for the sake of delivering the new feature on schedule. In this talk, we’ll analyze what appears to be a straightforward e-commerce shopping cart. We’ll then go ahead and add a few more use-cases that make it more complex and see how it can negatively impact the overall design. Finally, we’ll focus our attention on the business needs of these requirements and see how it can shed light on the correct approach to designing the feature. Walk away with a new understanding of how to take requirements apart to build the right software.

## Workshop: Building Distributed Systems with Microservices

Go beyond the hype and build a solid foundation of theory and practice with this workshop on SOA development.

Join for a deep dive covering architectural topics like:

- UI composition/decomposition
- Data ownership across the enterprise

You’ll also learn the nitty-gritty details of building production-ready systems including:

- Fault tolerance
- HTTP and queues
- Scalability, high availability & monitoring

Finally, get some hands-on experience in SOA development by building:

- Scalable command-processing endpoints
- Publish/subscribe event-processing interactions
- Long-running multi-stage business processes and policies

We’ll understand service-oriented architecture concepts, such as service boundaries and data ownership.

We’ll apply those concepts to build a simple, yet fully functional, e-commerce shopping cart sample with a microservices architecture, using patterns such as command processing, pub/sub and long-running sagas.
