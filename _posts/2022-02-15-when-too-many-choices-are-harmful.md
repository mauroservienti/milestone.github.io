---
layout: post
author: Mauro Servienti
title: "When too many choices are harmful"
header_image: /img/posts/when-too-many-choices-are-harmful/header.jpg
synopsis: "I tend to be lazy and pragmatic when it comes to choices. It's also true that being exposed to too many options stresses me producing a negative result. I end up refusing to choose."
tags:
- personal
- processes
---

I prefer restaurants with short menus rather than encyclopedic ones. When sitting at a table, faced with pages of choices and the pressure the waiter puts on me, I have the urge to wake up and escape.

I recently had a similar experience while [looking for a new smartwatch](https://milestone.topics.it/2021/12/27/do-I-still-need-a-smartwatch.html) to track my fitness activities. I'm a Garmin user. If I ever buy a new device, there is no point in paying the price of switching to something else. The cost of transferring years of data is too high.

Recently Garmin released the Fenix 7. I hear my colleague [Christian](https://twitter.com/cquirosj) whispering, "have a look, Mauro. Have a look..." 😆

But, there is also the new Epix gen 2, the Forerunner 945, 745, 245, or the Swim 2, to name a few. Their menu is so long! Garmin offers so many smartwatches that the only guarantee is a headache. And that's only by looking at the plethora of products. If you look at all the different versions each product offers, your head can only explode. All that becomes particularly true if you start comparing them. Most of them provide the same functionality, and one starts arguing why. For example, take a look at [this comparison](https://buy.garmin.com/en-US/US/catalog/product/compareResult.ep?compareProduct=735611&compareProduct=760778&compareProduct=621922&compareProduct=713363) between four models. It's hard to spot the differences. 

Another important factor contributing to the Garmin headache is the price range. Hundreds of models with slight to no differences with incredible differences in prices. That makes it even harder to choose.

On the topic of too many choices ["The paradox of choice"](https://www.youtube.com/watch?v=VO6XEQIsCoM) is an enlightening TED talk. Another side effect of too many choices is the unavoidable insecurity "gifted" to choosers. If we present people with three options with crisp differences, it's simpler to make a decision and don't ruminate on it for the rest of their lives. On the other hand, when there are plenty of options with minor differences, people, and I'm a victim too, immediately feel insecure and show an inability to choose.

Then there is Apple. The Apple Watch comes in two versions that differ by size. The rest is just minor details. You can choose the color or the wristband. That's it. Apple applies the same lean approach to most of its products. An even more extreme thing is represented by a famous quote attributed to Henry Ford when asked what color you could get the Model T in: "any color so long as it's black."

## What has all this in common with software architecture?

At first sight, nothing. And maybe it's just me removing a pebble from my shoe. Yet, there are two critical learnings. Do your best to avoid having many ways to achieve the same result. And, when presenting options, provide crisp and meaningful differences.

When given too many options, most people shut down and let others choose for them. On the topic of making decisions when sailing in an ocean of possibilities, [Nudge, by Richard H. Thaler and Cass R. Sunstein](https://www.amazon.com/Nudge-Improving-Decisions-Health-Happiness/dp/014311526X/) is an excellent book.

### Many ways lead to undesirable questions 

For example, there are [many different ways](https://nodogmablog.bryanhogan.net/2022/01/a-few-ways-of-setting-the-kestrel-ports-in-net-6/) to set the Kestrel webserver port. While reading the article, I started asking myself, why is that? And I had the same feelings a long restaurant menu creates. Not to mention that, as Bryan Hogan said in the article, you'll start asking questions like:

- Is option A better than option B, and why is that?
- How do I override that setting if set with option A, and will it work the same using option B?
- How do I get the current value? Oh, does it depend on how I set it?

#### The more the options, the more the questions

Even if we spend hours documenting all the possibilities in a vain attempt to cover all scenarios, there are [well-known reasons](https://medium.com/helppier/read-product-documentation-40eeab82f04a) why users don't read manuals and instructions. It means that no matter the effort we put in the documentation, questions and confusion are just around the corner.

### Slight differences lead to confusion

The second but equally important aspect is how different the available options are. Crispness is crucial to guide users towards the pit of success. Let's imagine the menu offers a few pizzas, and the only difference is the presence of oregano for two of them. Also, they have the same price.

Exact question: why is that?

It sounds like the difference is a minor nuance that doesn't need its menu entry. Presenting one pizza and listing available toppings serves users better.

Now, imagine you are in a meeting, and the group is choosing the architecture to implement a new feature later. The group responsible for presenting options shows a few architectural approaches. Many of them are like the above pizza, all the same except for a few minor options. The generated cognitive load can only lead to undesirable questions.

There is a high chance the meeting gets derailed by fruitless questions connected to the nuances rather than focusing on the critical differences between the various options.

Many people are scared to make decisions and default to "let's just make it configurable" or "let's present all the options and nuances." If you look at the configuration section of some apps, you'll see what I mean. Plenty of knobs and dials to adjust.

## Conclusion 

When designing APIs or defining and presenting design choices, it's essential to avoid creating confusion and fruitless questions for the audience. When it comes to APIs, ask yourself why there is a need for multiple paths to the same result. And when presenting choices, make sure that critical decisions factors stand out. If it's not a crucial decision factor, it might be noise. We might serve our users better by not presenting it at all.

---

Photo by <a href="https://unsplash.com/@itsbrandonlopez?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Brandon Lopez</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
