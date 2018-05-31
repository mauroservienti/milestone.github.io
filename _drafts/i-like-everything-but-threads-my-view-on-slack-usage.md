---
typora-root-url: ..
typora-copy-images-to: ../img/posts

layout: post
title: "I like everything but threads. My view on Slack usage."
author: Mauro Servienti
synopsis: "Communication is one of the key aspects in every organization. For distributed and dispersed organizations communication is even more important. Nowadays Slack is probably one of the most used communication tools. Is it a solution to the infamous email nightmare?"
tags:
- Organizations
- Remote working
- Slack
---

I was reading [this excellent article](https://medium.com/@martinkonicek/how-to-slack-6f5bf9be71ba) on [Slack](https://slackhq.com/) usage by [Martin Konicek](https://medium.com/@martinkonicek) and I found myself reflecting on the way we use it in [Particular Software](https://particular.net).

In Particular Software Slack is, along with [GitHub Issues](https://guides.github.com/features/issues/), the main communication tool. Our rule of thumb is something like:

* Transient communication and disucssions happen in Slack
* Decisions are documented on GitHub Issues

I have to admit that we're not strict in respecting the above rules, however you get the main idea that drives our Slack usage. At the time of this wrting we have more than 100 channels, and we do our best to stay away from threaded conversations as much as we can.

Martin, in his article, already lists a set of great tips on how to improve the daily Slack experience. I'd like to focus this post on why we dislike threaded conversations on how we avoid them.

Slack is (most of the times?) perceived as the solution to the infamous e-mail overwhelming nightmare. Let's be honest with ourselves it's not only the tool that solve the problem, it's the way the tool is implemented and used.

Dumping all what previously were e-mail conversations into Slack is not going to change anything. Imagine a large group of people, sharing thesame space, discussing. There might be a seed topic, but soon conversations start to diverge. The result is that no conversation can happen, everyone will interfere with everyone. This is not different than a single large Slack channel, where everything happen, or the typical e-mail thread where everyone replies to all but by misusing quoted text comments on different portion of the content, effectively kicking off multiple concurrent discussions.

When discussions start to diverge the group of people, in the large shared space, will start to form sub-groups to follow conversations that spun off from the seed one. The larger the group is the easier is that:

* Multiple people are interested in multiple convensations
* The noise created by groups near to each other interferes with ongoing conversations

This is not different than threads, as soon as a threaded conversation is kicked off from a message in Slack, it creates a virtual sub-group in the channel. If the conversation grows soon the need for anouther thread will be faced. Leading to the need of threads of threads. What could possibily go wrong? :-)

We should accept the sad truth: human beings are bad at managing conversations in large groups. They will naturally for sub-groups, that soon will need to put distance between eachother to avoid interferences. Ending up looking for different rooms.

In the Slack world this simply means multiple channels. We have many channels focused on specific topics and we d our best to keep the conversation in the channel on topic. We use "transient" channels a lot as well. A channel is created to discuss a topic, might live for a week, and then is archived.
