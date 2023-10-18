---
layout: post
title: "The power of timeouts to compensate for failures and other tales"
author: Mauro Servienti
synopsis: "There are scenarios when a chatty services relationship seems the only option, with the results of coupling quickly becoming our best friend. Not all hope is lost, we can try to ask different questions to untangle the knot."
header_image: /img/posts/timeouts-power/header.jpg
tags:
- sagas
- soa
- distributed-systems
---

The design of the new system proceeds swiftly and with few hiccups. A couple of times, one team asked another if they could publish a new event to signal something happening. Teams were in a "_what could possibly go wrong_" mood. They didn't pay much attention, considered those requests harmless, and implemented them straight away.

After a few months in production, support people started noticing some unexpected behavior. Customers were complaining that, occasionally, they couldn't complete an order, but the amount authorized on the card was not released as promised.

Everything else seemed fine. Customers could cancel the failed orders, and when placing new ones, everything worked fine. Further investigation revealed that what support personnel dealt with was the tip of the iceberg. The number of failed orders was higher than expected, and consequentially was the number of _locked_ cards. The ones surfacing were those who couldn't place a new order because of insufficient available credit after a failed order.

Everyone's attention was on failed orders. After quite some investigation time, it turned out the checkout process had a subtle bug. A number of things needed to happen to surface the problem, and reproducing it was not trivial at all. The bug got its deserved fix, and once deployed to production, everything got back under control.

## The diagnosis

The [postmortem](https://en.wikipedia.org/wiki/Postmortem_documentation) discussion focused on why the service initiating the order checkout process failed. Once that was settled, the attention moved to the payment service, and coupling entered the scene. 

The team started wondering why Payments did not cancel the card authorization. The authorization and charging process was configured to react to other service failures and cancel any previously issued authorization requests.

It took a couple of seconds to realize the colossal mistake at play. All those requests to other teams to publish non-business-related events to signal failures and errors caused an intricated spaghetti-style web of cross-service relationships.

The Payment service depends on the Order checkout to revert the card authorization. They were coupled instead of being autonomous. [It was one of those instances where the team's interpretation of the word _autonomous_ led in the wrong direction](https://milestone.topics.it/2022/09/05/autonomy.html).

Customers failed to proceed with the checkout process because the bug was causing an outage in the Order checkout service. The service couldn't publish any message, including those meant to signal the process failure. From the Payments service perspective, no news was good news, and it kept the card authorization in place.

## The cure

The group in charge started analyzing what they could have done differently. How can they change services to prevent something like this from happening in the future? In one word: how to untangle the knot?

One option is to leverage the power of timeouts, also known as delayed deliveries. I like to describe them as a neat way to react to things _not_ happening. That's precisely the case at play.

A timeout is a message sent in the future. The sender sets the desired delivery date and time, and the infrastructure delivers the message when requested.

If the Order checkout process fails, the Payments service wants to retract the card authorization. That's the way the business describes the thing.

We can look at it from the perspective of what's _not_ happening. The Payments service wants to retract the cart authorization if _it doesn't receive any signal from the Orders checkout within a particular time from the approval_.

For example, if on average (and be aware of the [risk of using averages](https://towardsdatascience.com/why-averages-are-often-wrong-1ff08e409a5b)) the Order checkout process publishes an event to signal its completion in 10 minutes, we could say that if within a day we heard nothing it's fair to assume that something went wrong and it's better to cancel the card authorization rather than holding the money.

In [Welcome to the (State) Machine](https://youtu.be/26xrX113KZc), I present a ticket-ordering scenario highlighting the issues discussed so far and how to address them using timeouts. I also crafted a [demo](https://github.com/mauroservienti/welcome-to-the-state-machine-demos) showing how to implement it using [NServiceBus](https://docs.particular.net/nservicebus/) (spoiler: I work for [Particular Software](https://www.particular.net/), the makers of NServiceBus).

## That's _not_ all, folks!

Reacting to things _not_ happening belongs to the larger "making decisions in the future" cluster. We can use timeouts to make all sorts of future decisions. Let me talk about a real-life scenario I had the chance to work on a few years ago.

We had a batch job to check for unpaid invoices. The scheduled task was running monthly on the tenth day. Everything worked perfectly until the business changed. The company changed the invoicing process from issuing them monthly to daily.

Previously, a 30-day due invoice would have expired at the end of the following month. Checking for overdue payments on the tenth was just fine. Invoice payments are due within 30 days, but with the change in the issuing frequency, they can become overdue daily.

The batch job became an issue. Running it daily put too much pressure on the infrastructure; unfortunately, the data schema was not as simple as "here is a bit column whose value is 1 for paid and 0 for unpaid invoices," and we had no authority over it.

Instead of fighting with the database schema, we completely wiped the batch job and replaced it with timeouts. Every time the system issued an invoice, it also scheduled an accompanying timeout set to expire a few days after the due date.

I presented that approach in [Got the Time?](https://particular.net/webinars/got-the-time) ([demos are available on GitHub](https://github.com/mauroservienti/got-the-time-demos)).

## Conclusion

Timeouts are a powerful way to handle time-dependent business processes, which likely are the vast majority ;-) Using timeouts, we can make asynchronous decisions in the future and answer questions such as "What has _not_ happened?"

Do you want more? Here is more!

- [Death to the Batch Job](https://particular.net/blog/death-to-the-batch-job) by [David Boike](https://twitter.com/DavidBoike)
- [Stop looking in the past; Start telling the future](https://particular.net/webinars/tell-the-future) by [Derek Comartin](https://twitter.com/codeopinion)

---

Photo by <a href="https://unsplash.com/@icons8?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Icons8 Team</a> on <a href="https://unsplash.com/photos/dhZtNlvNE8M?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
