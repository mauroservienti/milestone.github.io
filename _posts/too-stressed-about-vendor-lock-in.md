---
layout: post
header_image: /img/posts/too-stressed-about-vendor-lock-in/header.jpg
title: "We're too stressed about vendor lock-in"
author: Mauro Servienti
synopsis: "Developers and managers are worried by vendor lock-in. They build castles of cards in a vane attempt to workaround what they perceive as a problem. Is this a different form of over-engineering?"
tags:
- processes
---

When talking to managers and developers, I often realize they face the vendor lock-in dilemma.

Managers and developers fear that they'll be locked in by selecting a specific vendor. If possible, it'll be complex to switch to a different solution, e.g., another vendor, to solve the same problem without incurring massive costs.

Nowadays, one good example of vendor lock-in is represented by cloud solution providers like Amazon AWS, Microsoft Azure, or Google Cloud, to name a few. The reasoning usually goes like this: If we fully buy-in technology X, e.g., AWS Lambda functions, it'll be tremendously expensive to move to a different platform in the future.

## History repeats itself

It reminds me of one of the main selling points of ORMs ([Object-relational mapping](https://en.wikipedia.org/wiki/Object%E2%80%93relational_mapping)): you can switch the underneath RDBMS.

In 22 years, I never saw that happening. I developed many solutions built on that claim. They never benefit from it. So, I'm guilty too!

## (vendor) lock-in

The word vendor lock-in is misleading; it points fingers at vendors. Vendors change over time. Yesterday it was ORM; today are cloud providers; tomorrow, it'll be something else. Let's remove vendors from the equation and focus on lock-in only.

## The many forms of lock-in

Lock-in can surface in many different shapes. The already mentioned cloud providers' vendor lock-in is one of many ways lock-in manifests itself. That's probably the most apparent type. We select a vendor solution and design our solution to work reliably with that. Cloud vendors are the ones we've been talking about lately. In general, vendors. We select .NET as the development stack, and we're locked in into the .NET ecosystem. Strangely, we don't perceive it as lock-in.

Another form of lock-in is what I call OSS lock-in. It's not that different, on the surface, from the vendor's one. It comes with a subtle difference, though. We select OSS libraries for their functionalities, but the selection process rarely considers the governance model. If we were to dig deeper, we might discover that one person maintains the open-source project, and that's their third hobby. Suddenly, they change their mind, and even if we have no intention to switch to a different solution, we find ourselves locked in and with no other option than to switch.

An even more subtle form of lock-in is represented by ourselves. In an attempt to avoid vendor, OSS, or any other form of lock-in, we start diverging our focus from the business problems we intended to solve, and instead, we start building infrastructure code. On many occasions, I observed consultants or colleagues designing solutions to avoid some form of lock-in. Then the consultant or the colleague moved on to a new project, leaving us with some infrastructure code that needs to be maintained over time and effectively represents a form of lock-in.

## Conclusion

Lock-in is pervasive. That's not a good reason to ignore it altogether, though. At the same time, realizing that's pervasive is key to understanding how to face the problem and judge if it's genuinely a problem. Being too stressed about it makes us blind, makes it harder to evaluate how much it affects the project we're developing. And that comes with the risk of over-engineering solutions to non-existing problems, all that at the cost of ignoring the real business problems we're tasked to address.

---

Photo by <a href="https://unsplash.com/@helloimnik?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Hello I'm Nik</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
