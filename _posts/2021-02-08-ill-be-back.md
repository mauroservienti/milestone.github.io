---
layout: post
header_image: /img/posts/ill-be-back/header.jpg
title: "I'll be back"
author: Mauro Servienti
synopsis: ""
tags:
- Distributed Systems
- Timeouts
- Long running
- Sagas
- Delayed messages
---

Time, as a concept, is both elementary and incredibly complex, to the point that physicists like Carlo Rovelli say that [it doesn't exist](https://youtu.be/vgsoI4ZUkUA). If you spend some time (ironically, time exists if you can spend it) diving into the nuances, it's clear that time exists at a particular scale, it's not unique and ubiquitous, and it can be stretched and manipulated. And yes, at the quantum scale, it doesn't exist. Mind-blowing and fascinating.

If we look at time from the perspective of systems design, it has many nuances and complexities.
On the one hand, there is clock drift: different machines have different views of time; it's not unique and ubiquitous. On the other hand, there is the conceptual complexity of modeling the passage of time. Modeling the passage of time as a clock does seems to be a natural thing to do. It translates the [user mental model](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html) into the system design well and provides a reliable solution. However, if we look deeper, it might not be so good as a solution.

## Clocks are batch jobs

Time ticks away, human beings observe the ticking of time and react.

Imagining a clock scale of 1 day, in which clocks will only tell which day of the week is today. We will be in a situation where there is a long list of things to do today and someone that picks from the list and executes the corresponding task. It'll be a big mess, 24 hours is quite a long chunk of time, and those to-do lists can become quite long. It's very tempting to increase the scale and make it so that a clock ticks every hour instead of every 24. Has anything changed? Maybe, we might be lucky and discover that the granularity of a one-hour scale in our context is better. Regardless of the clock scale of choice, we're approaching the problem with a batch job oriented solution. We'll be sitting there waiting for a clock tick to kick off an allocated slot to perform some work regardless of the amount of work.

Let's say that for the amount of work that we need to do during office hours, a one-hour scale seems a good fit. Every hour, from nine to five, "the clock" kicks off a job. The goal is to get done most, if not all, pending charges by the end of the week. The flip side of the coin is that, weekly, the "do xyz" job is kicked off 64 times for no good reason, during non-office hours, weekends included. A huge waste. One could argue that a simple solution is to turn off the clock when offices are closed. However, this needs another ticking clock.

To better grasp the problems that a batch job oriented solution carries, we can translate the above conceptual view into a more real-world sample by describing an invoicing process.

Acme Inc. issues invoices on the last day of the month. All issued invoices are due in thirty days. It seems reasonable to set the "check overdue invoices" clock to tick on the 10th of the next month. Forty days after sending invoices, Acme checks payments and acts upon overdue invoices. One day Acme changes its business model and decides to issue invoices on the same day they sell goods or services. The Acme accounting department cannot anymore rely on the forty-day rule to check for overdue invoices because by not issuing invoices regularly, invoices can be outstanding more or less every day. The Acme Operations team's simple reaction is to adjust the ticking clock's scale, and instead of ticking on the 10th of the next month, it makes it tick every day.

The overall system performances are greatly affected. Every 24 hours, there is a job that scans the database looking for overdue invoices. Given that Acme doesn't sell goods or services every day, it doesn't issue invoices either. The check for unpaid invoices job ends up overloading the system daily for no good reason.

## Design problems at play

The problem we're facing is not a technical problem. Sure, we can scale up the database server and throw some money at the problem. However, it's only postponing the issue to a later time; it's like hiding the dust under the carpet. I remember talking with a customer where the infamous batch job ended up being so complicated that it could only run once every week. The job was taking up to 3 days to complete, and the 4-day buffer was required to guarantee a viable human intervention window in case something terrible happened.

Again, it's not a technical problem. It's a design issue.

We're replicating the user mental model. Users always worked this way, they sit down and check for unpaid invoices. It doesn't matter if they do it every forty days or daily; this is how most accounting departments worked for their entire existence.

### Flip the responsibility 

If, twenty years ago, we were to ask someone: how do you know what your duties are for today? The most common answer would have been: I check my agenda every morning.

The same question today gets an entirely different answer: I rely on my phone to notify me that something is due, for example, in the next hour.

We stopped relying on agendas and instead, we rely on the agenda taking care of us. We mostly look at the schedule to get an overall view of the day if we want.

What if we were to schedule in our calendar each time an invoice is issued that, forty days later, we have to check for the payment of that specific invoice? At this point, there is no need for a ticking clock to tell us regularly to check for overdue invoices; we'll rely on the agenda to come back to us with a notification that today there are invoices that we need to check. In a future article, we'll look at a possible technical solution to model the described "overdue invoices check" requirement using the agenda based pattern.

## Conclusion

Once again, we need to be very [careful at modeling software systems slavishly following the users' mental models](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html). The biggest problem is that users come with solutions; here is how we check for payments (with an implicit "we've always done it this way"), they have a tough time describing the underlying problems. Our primary job is to set aside the proposed solution and dissect the real problem requirements they intend to solve.

---

(credits here)
