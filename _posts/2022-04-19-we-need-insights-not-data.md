---
layout: post
title: We need insights, not data
author: Mauro Servienti
title: "Gauges and graphs attract software engineers like honey for bees. We spend hours implementing distributed logging solutions or monitoring systems, and still we have a hard time understanding what's going on."
header_image: /img/posts/we-need-insights-not-data/header.jpg
tags:
- personal
- distributed-systems
---

I used a [Whoop](https://www.whoop.com) device for about 18 months. What's Whoop, you might wonder?

Quoting from their website:

> The latest, most advanced fitness and health wearable available. Monitor your recovery, sleep, training, and health, with personalized recommendations and coaching feedback.

I stopped using it because I got no personalized recommendations and coaching feedback. I mentioned this at the [end of 2021 in "Do I still need a smartwatch?"](https://milestone.topics.it/2021/12/27/do-I-still-need-a-smartwatch.html):


> The reality is that I'm looking for a coach. And I've been trying to solve the problem through a device for a while, and I failed. It was probably expected.

## I was wrong

First, I contradicted myself and bought the new Garmin Fenix 7. Gorgeous.

Second, what Whoop promised, Garmin does.

The following is a screenshot from the Garmin Connect app:

![Garmin Connect screenshot](/img/posts/we-need-insights-not-data/garmin-screenshot.jpg){:class="img-fluid mx-auto d-block"}

Notice that "Training status: unproductive" thing. That's telling me that I'm doing it wrong.

## How it all started

I train regularly. My training ranges from bike rides to swimming to short interval training sessions.

After a few days of wearing the new watch, the "Training status: mantaining" appeared in the Garmin Connect reports. What does maintaining mean?

> Your current training load is sufficient to maintain your fitness level. To see improvement, try working out longer or more often.
>
> Load focus - High Aerobic Shortage

Let me translate that for you: too much endurance and zone two training. I was swimming at a regular pace and performing long bike rides with no variation. As I continued with my training habits, the status changed to unproductive. And it's here that things get interesting.

Garmin's training status feature, instead of simply reporting your current status, comes with suggestions on how to change your training routine to be more productive. My tips were to either train more often or, better yet, change the training sessions to be more interval-style and more challenging for my cardiovascular system. For example, instead of bike riding for 80 kilometers twice a week, do four sessions, three of which could be shorter and focused on aerobic and high aerobics intensity.

The great thing is that the device even comes with suggestions for today's session. It uses the body recovery status to determine what's best, including resting. So, today's advice might be to do nothing and focus on relaxing. Interestingly, the Garmin algorithm uses the same raw data Whoop captures. The Fenix device has a heartbeat and pulse oximeter sensor similar to the Whoop one. It tracks more or less the same raw data, such as resting heartbeats, respiration, sleep, heart rate variability, etc. 

In my specific case, what's reassuring is that Garmin insights are well aligned with the topics I recently discussed with my friend [Daniel](https://twitter.com/danielmarbach). Daniel is not only a brilliant software engineer, but he's also a sportsman that knows a lot about training. I presented him with my issues and gut feelings, and he gave me the same advice Garmin gave me a couple of weeks later.


## What about software systems?

For a very long time, I had this gut feeling that monitoring dashboards were useless at best. All those gauges and graphs attract us—bells and whistles of the digital era. If a monitoring dashboard provides only raw data, we need an external coach to understand what actions we need to move forward and improve.


I'd want a monitoring system to tell me "scale out the system" or do it automatically if elastic scaling capabilities exist. And scale down when the additional power is not needed anymore. If you're thinking, "serverless does that." Yep, that's it.

I'd want a monitoring system to understand my business and implement business process monitoring (BPM). BPM would help move from "let me look at the logs to try to understand what's happening" to "oh, processed orders are violating SLAs because of XYZ."

That's exactly what a coach would do. A coach wouldn't present an athlete with raw numbers and an accompanying "help yourself" suggestion. The coach would analyze data and present suggestions for improvements to athletes.

Similarly, a monitoring system should tell me what to do instead of showing raw data.

## Is it part of the core domain?

My hunch is that the answer is yes, it is. 

Getting the data doesn't belong to the core domain. We should reach out to third-party vendors to acquire tools for distributed logging, metrics capture, and system health monitoring solutions.

It's tough for a vendor to supply solutions that provide the insights we need. Unless the vendor is focused on a single business and we're giving access to raw data like Garmin can do.

Analyzing the data and understanding what to do is our core responsibility. It's part of the business. For example, if we sell goods online, making sure that SLAs are met is on us, not on the distributed logging solution vendor, to name one.

## Conclusion

Raw data are complicated to use, present, and digest for consumers. It's crucial to provide analysis and insights with accompanying suggestions for improvement.

When it comes to me, Garmin is not perfect. A coach would be a better option, anyway. However, what Garmin offers is a huge step forward for me. The moral of the story is that I don't need a device. I need Daniel 😎

---

Photo by <a href="https://unsplash.com/@patrick_schneider?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Patrick Schneider</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
  
