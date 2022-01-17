---
layout: post
header_image: /img/posts/too-stressed-about-vendor-lock-in/header.jpg
title: "We're too stressed about (vendor) lock-in"
author: Mauro Servienti
synopsis: "Developers and managers are worried about (vendor) lock-in. They build castles of cards in a vain attempt to work around what they perceive as a problem. Is this a different form of over-engineering?"
tags:
- processes
---

I talk to managers and developers daily. I often realize they face the vendor lock-in dilemma.

Managers and developers fear that selecting a specific vendor's technology locks them. Consequently, switching to a different solution incurs massive costs and challenges.

Nowadays, cloud solution providers like Amazon AWS, Microsoft Azure, or Google Cloud, to name a few, are good examples of vendor lock-in. The reasoning usually goes like this: If we buy into technology X, e.g., AWS Lambda functions, it'll be expensive to move to a different platform in the future.

## History repeats itself

It reminds me of one of the main selling points of ORMs ([Object-relational mapping](https://en.wikipedia.org/wiki/Object%E2%80%93relational_mapping)): you can switch the underlying database.

In 22 years, not once have I seen a company switch database vendors. I developed many solutions built on that claim, but they've never benefited from it. So I'm guilty too!

## (vendor) lock-in

The word vendor lock-in is misleading; it points fingers at vendors. Vendors change over time. Yesterday it was ORM; today are cloud providers; tomorrow, it'll be something else. Let's remove vendors from the equation and focus on lock-in only.

## The many forms of lock-in

Lock-in can surface in many different shapes. The already mentioned cloud providers' lock-in is the one that shines today. We select a vendor solution and design our solution to work with that. Cloud vendors are the ones we've been talking about lately. But we may also choose .NET as the development stack, and we're locked into the .NET ecosystem. Surprisingly, we don't perceive it as lock-in.

Another form of lock-in is what I call OSS lock-in. It's not that different, on the surface, from the vendor's one. It comes with a subtle difference, though. We select OSS libraries for their functionalities. However, the selection process rarely considers the governance model. If we dig deeper, we might discover that one person maintains the open-source project. And that's their third hobby! 
Suddenly, they change their mind. We had no intention to switch, but we find ourselves locked in, with no other option than to change. Sure, we can fork the project and maintain it ourselves...

We represent an even more subtle form of lock-in. To avoid lock-in, we diverge from business problems and build infrastructure code. On many occasions, I observed consultants or colleagues designing solutions to prevent some form of lock-in. Then the consultant or the colleague moved on to a new project. Surprise: the original intent is now a cage we need to maintain.

## Uncertainty

Lock-in is pervasive. So, why are we apprehensive about lock-in? That is because of the uncertainty that comes with it. It's not lock-in itself the problem. It's the "what if" question the issue.

What if AWS changes its mind and abandons Lambda? What if [their strategy shifts](https://www.zdnet.com/article/bob-muglia-microsoft-changing-its-approach-to-interoperability/) and they decide to kill Silverlight?

Those things happen every day. Can we do something about it? Sure, we could write our ActiveX, convince users to install it, write our UI framework, and support it for all the time we require it. We also need a ton of money. Are we worried about being lock-in into AWS Lambda? Choose [Apache OpenWhisk](https://openwhisk.apache.org/) and make your considerations if it's worth it.

When it comes to uncertainty, there is no way out. There are only mitigation strategies. We can throw money at the problem. For example, we can pay a vendor to extend support beyond the official retirement of the technology. Or we can decide to select a technology and live with it for the rest of our days.

I hear you saying that it's impossible—however, the [Rosetta project](https://www.nasa.gov/rosetta) witnesses that it's doable. They launched in 2004 to land on a comet ten years later, in 2014. And the engineering work started years in advance. Do you think they could do an OTA (Over The Air) update to the software running on the lander? They landed with something we would not consider worth it nowadays, even for an incredibly cheap smartwatch. Again, it's a matter of priorities. They fixed the uncertainty problem by never changing the selected technology. Inherently, they threw money at the problem.

## What can we do about it?

For example, we can select only solutions based on standards. No one is concerned with being locked into HTML or e-mails (or maybe we all are, but there is no way out ;-P). They are established standards for which there are several offerings from different vendors. However, one could argue that they are a sort of legacy. That is true; they are not cutting-edge technologies. But for fast-evolving cutting-edge technologies, we cannot expect to find established standards. It's a chicken and egg problem.

Another approach is componentization. For example, distributed systems are polyglot by definition. Services and components autonomy enables selecting the best technology for each of them. Being polyglot can also be a set of many minor lock-in problems. We can solve those small and well-isolated problems much quicker.

## Total cost of ownership (TCO)

Before concluding, it's worth mentioning the total cost of ownership. An example is worth a thousand words. Let's say that we select Apache OpenWhisk for our serverless deployments. From the engineering perspective, we are happy. Yet, Operations have to support the required operating system, hardware, or virtual machines. Finally, do we need to run a custom deployment pipeline, or can we use standard tools available on the market?

All that is not to say that OpenWhisk is the wrong solution. I'm sure there are scenarios in which it makes perfect sense. I urge you to highlight that it's not only a software engineering concern.

## Conclusion

Even if lock-in is pervasive, that's not a good reason to ignore it altogether. At the same time, realizing that's pervasive is key to understanding how to face the problem and judge if it's genuinely a problem. Being too stressed about it makes us blind, makes it harder to evaluate how much it affects the project we're developing. And that comes with the risk of over-engineering solutions to non-existing problems. All that at the cost of ignoring the real business problems we're tasked to address.

---

Photo by <a href="https://unsplash.com/@helloimnik?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Hello I'm Nik</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
