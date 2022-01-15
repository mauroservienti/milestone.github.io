---
layout: post
header_image: /img/posts/too-stressed-about-vendor-lock-in/header.jpg
title: "We're too stressed about (vendor) lock-in"
author: Mauro Servienti
synopsis: "Developers and managers are worried about (vendor) lock-in. They build castles of cards in a vain attempt to work around what they perceive as a problem. Is this a different form of over-engineering?"
tags:
- processes
---

When talking to managers and developers, I often realize they face the vendor lock-in dilemma.

Managers and developers fear that they'll be locked in by selecting a specific vendor's technology. It'll be complex to switch to a different solution, e.g., another vendor, to solve the same problem without incurring massive costs.

Nowadays, one good example of vendor lock-in is represented by cloud solution providers like Amazon AWS, Microsoft Azure, or Google Cloud, to name a few. The reasoning usually goes like this: If we fully buy into technology X, e.g., AWS Lambda functions, it'll be tremendously expensive to move to a different platform in the future.

## History repeats itself

It reminds me of one of the main selling points of ORMs ([Object-relational mapping](https://en.wikipedia.org/wiki/Object%E2%80%93relational_mapping)): you can switch the underlying database.

In 22 years, not once have I seen a company switch database vendors. I developed many solutions built on that claim, but they've never benefited from it. So I'm guilty too!

## (vendor) lock-in

The word vendor lock-in is misleading; it points fingers at vendors. Vendors change over time. Yesterday it was ORM; today are cloud providers; tomorrow, it'll be something else. Let's remove vendors from the equation and focus on lock-in only.

## The many forms of lock-in

Lock-in can surface in many different shapes. The already mentioned cloud providers' vendor lock-in is one of many ways lock-in manifests itself. That's probably the most apparent type. We select a vendor solution and design our solution to work reliably with that. Cloud vendors are the ones we've been talking about lately. But we may also select .NET as the development stack, and we're locked into the .NET ecosystem. Strangely, we don't perceive it as lock-in.

Another form of lock-in is what I call OSS lock-in. It's not that different, on the surface, from the vendor's one. It comes with a subtle difference, though. We select OSS libraries for their functionalities, but the selection process rarely considers the governance model. If we were to dig deeper, we might discover that one person maintains the open-source project, and that's their third hobby. Suddenly, they change their mind, and even if we have no intention to switch to a different solution, we find ourselves locked in and with no other option than to switch. Sure, we can fork the project and maintain it ourselves...

An even more subtle form of lock-in is represented by ourselves. In an attempt to avoid vendor, OSS, or any other form of lock-in, we start diverging our focus from the business problems we intended to solve, and instead, we start building infrastructure code. On many occasions, I observed consultants or colleagues designing solutions to avoid some form of lock-in. Then the consultant or the colleague moved on to a new project, leaving us with some infrastructure code that needs to be maintained over time and effectively represents a form of lock-in.

## Uncertainty

Lock-in is pervasive. So, why are we apprehensive about lock-in? I believe that is because of the uncertainty that comes with it. It's not lock-in itself the problem. It's the "what if" question the issue.

What if AWS changes its mind and abandons Lambda? What if [their strategy shifts](https://www.zdnet.com/article/bob-muglia-microsoft-changing-its-approach-to-interoperability/) and they decide to kill Silverlight?

Those things happen every day. Can we do something about it? Sure, we could write our ActiveX, convince users to install it, write our UI framework, and support it for all the time we require it. We also need a ton of money. Are we worried about being lock-in into AWS Lambda? Choose [Apache OpenWhisk](https://openwhisk.apache.org/) and make your considerations if it's worth it.

When it comes to uncertainty, there is no way out. There are only mitigation strategies. We can throw money at the problem, for example, by paying a vendor for extending support beyond the official retirement of the chosen technology. Or we can decide to select a technology and live with it for the rest of our days.

I hear you saying that it's impossible—however, the [Rosetta project](https://www.nasa.gov/rosetta) witness that it's doable. They launched in 2004 to land on a comet ten years later, in 2014. And the engineering work started years in advance. Do you think they could do an OTA (Over The Air) update to the software running on the lander? They landed with something we would not consider worth it nowadays, even for an incredibly cheap smartwatch. Again, it's a matter of priorities. They decided to fix the uncertainty problem by never changing the selected technology and inherently throwing money at the problem.

## What can we do about it?

For example, we can select only solutions based on standards. No one is concerned with being locked into HTML or e-mails. They are established standards for which there are several offerings from different vendors. However, one could argue that they are a sort of legacy. That is true; they are not cutting-edge technologies. But for fast-evolving cutting-edge technologies, we cannot expect to find established standards. It's a chicken and egg problem.

Another approach is componentization, and distributed systems are one way of componentizing complex software systems. Distributed systems can be polyglot by definition. The components and services autonomy enables selecting the best technology for each component. As we used to say, a distributed system is a set of small ugly balls of mud. Being polyglot can also be a set of many minor lock-in problems. Those problems being small and well isolated, can be solved much easily.

## Total cost of ownership (TCO)

Before concluding, it's worth mentioning the total cost of ownership. An example is worth a thousand words. Let's say that we select Apache OpenWhisk for our serverless deployments. From the engineering perspective, we might be happy. However, we might have forgotten that Operations now has to support the operating system and hardware (or the virtual machines) required to run OpenWhisk. Finally, do we need to run a custom deployment pipeline, or can we use standard tools available on the market?

All that is not to say that OpenWhisk is the wrong solution. I'm sure there are scenarios in which it makes perfect sense. I urge you to highlight that it's not only a software engineering concern.

## Conclusion

Even if lock-in is pervasive, that's not a good reason to ignore it altogether. At the same time, realizing that's pervasive is key to understanding how to face the problem and judge if it's genuinely a problem. Being too stressed about it makes us blind, makes it harder to evaluate how much it affects the project we're developing. And that comes with the risk of over-engineering solutions to non-existing problems, all that at the cost of ignoring the real business problems we're tasked to address.

---

Photo by <a href="https://unsplash.com/@helloimnik?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Hello I'm Nik</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
