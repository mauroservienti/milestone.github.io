---
layout: post
title: "Will AI eat our jobs, or multiply them? Yes"
author: Mauro Servienti
synopsis: "One half of my feed says AI will make developers obsolete. The other half says it will multiply what we can build. Both can't be right. Or can they? And what happens when English becomes the programming language?"
header_image: /img/posts/ai-eats-or-amplifies/header.jpg
tags:
- ai
---

There are two stories about AI and software development. In the first one, AI eats all the development tasks, and developers become obsolete. In the second one, AI multiplies what we can build, and one developer does the work of ten.

I think both stories describe something real. They only look at different parts of the job.

The bigger shift, though, is somewhere else. It's the entry barrier. We're moving, slowly, toward a world where English is the programming language. We're not there yet. But we're going there. And what doesn't go away, at least for now, is understanding the problem and judging the answer.

## Two stories on the same feed

Open LinkedIn. Scroll for thirty seconds.

The first story goes like this: developers are toast. No-code meets large language models, and in a couple of years nobody will write software anymore. You describe what you want, the machine builds it, done. I met this crowd already in my [vibe-coding experiment](/2026/02/11/vibe-coding.html). They're loud. They're very sure.

The second story goes like this: one developer now does the work of ten. Productivity goes through the roof. Teams ship features in hours instead of weeks.

The funny part? Often, the same people post both stories. A week apart.

Let's take them seriously for a moment, though. If output really multiplies, who consumes all that output? Who decides what to build? And if developers disappear, who's doing the multiplying?

These questions are more interesting than the stories.

## What history says, more or less

This is not the first time a technology promised to make programmers obsolete.

**Compilers and high-level languages.** Once upon a time, programming meant writing machine instructions by hand. Then high-level languages and compilers arrived. The machine wrote the assembly for us. Did programmers disappear? No. Programming became accessible to many more people, and the amount of software exploded.

**Spreadsheets.** Spreadsheets made everyone a little bit of a programmer. Every finance department suddenly had people writing formulas, which are programs, even if nobody calls them that. Accountants didn't disappear. Their work changed. And, as a bonus, we got a whole new category of software disasters. A wrong cell reference can be expensive.

**The cloud.** The cloud was supposed to make operations people unnecessary. Instead, we got DevOps, platform engineering, site reliability engineering, and FinOps, because somebody has to understand why the bill is so high.

There's even a name for this pattern: the [Jevons paradox](https://en.wikipedia.org/wiki/Jevons_paradox). In the 19th century, William Stanley Jevons noticed that more efficient steam engines didn't reduce coal consumption. They increased it. When something becomes cheaper to use, we don't use less of it. We use much more.

Software could follow the same path. If writing software becomes cheaper, we'll write a lot more of it.

Is AI just the next step on that ladder? Or is it a different kind of step? I'd love to give you a confident answer. I don't have one. Anyone who has one is probably selling something.

## Where the output really goes

Let me use my own numbers.

Recently, I built [Zusammen](https://github.com/mauroservienti/Zusammen), a [transactional session library for Node.js](/~~date~~/zusammen.html), over a weekend. <!-- TODO: link to the Zusammen post once published --> Eight npm packages, one NuGet package, more than 180 tests, documentation, samples, CI, and automated releases. In a stack I don't know. Ten years ago, that would have taken weeks. Maybe months.

So yes, the output is real. The second story isn't wrong.

But something else happened during that weekend. I realized that writing code was never the slow part I thought it was. The bottleneck simply moved.

**Deciding what to build.** Before any code, there was a plan. Every phase started with a decision: which design, which trade-off, which guarantee.

**Reviewing.** Every pull request needed my eyes. Every claim needed checking. At some point, the AI wrote "MongoDB 4.4+ supported" in the documentation. Supported according to whom? Nothing tested that. It caught itself, but I was ready to.

**Saying no.** A few times, the right move was to say no. No to a separate processor role. No to creating queues and collections at startup. No to making NServiceBus compatibility mandatory. Every "no" required knowing why.

Now scale that to a company. If every team suddenly produces ten times more code, does review capacity grow ten times? Integration? Operations? Coordination between teams? Of course not. It's [Amdahl's law](https://en.wikipedia.org/wiki/Amdahl%27s_law), applied to organizations: the speedup is limited by the parts you can't speed up.

And there's another catch. More code is also more liability. More to maintain, more to secure, more to operate, and, one day, more to delete. Code is an asset when it works and a debt the rest of the time.

## The entry barrier: from syntax to understanding

This is the part I find most fascinating.

Until now, to turn an idea into software, you needed a developer. The developer was the translator between the problem and the machine. The domain expert explained the problem, the developer translated it into code, and a lot got lost in translation. Entire methodologies exist only to reduce that loss.

Now look at what I did with Zusammen. I built a Node.js library without knowing Node.js. What I knew was the problem space: messaging, the outbox pattern, NServiceBus. I described the problem in English. The machine handled the syntax. It wasn't so strighforward as it sounds, though.

Let's extrapolate. Picture an accountant who deeply understands their processes. A doctor who knows exactly what a clinic needs. A logistics planner who knows every corner case of a warehouse. Today, they need a developer to build their tools. Tomorrow, maybe, they describe the problem in English, and the software appears.

In my vibe-coding post, I wrote that English is the new programming language. I still think it's true. And it's a big deal. The people closest to the problem could build the solution. No more lost-in-translation requirements.

## We're not there yet

Before we celebrate, let me be honest.

When I played dumb in my vibe-coding experiment, things went badly. The AI got stuck in loops. It burned my credits. It designed a database that would have melted my credit card in production, and it forgot security entirely.

With Zusammen, it went smoothly. Why? Because I could tell when an answer smelled.

My own plan claimed "exactly-once" delivery. The AI corrected me, and I could tell it was right. It proposed a long-running consumer for control messages, and I could tell it was wrong. It found that an AMQP property could silently break my design for NServiceBus, and I could recognize the problem as soon as I saw it.

So the entry barrier didn't disappear. It moved. It moved from knowing the syntax to knowing the problem and being able to judge the answer.

That judgment is still engineering knowledge. Failure modes. Consistency. Security. Operations. You don't need to type it anymore. You need to recognize it.

And here's the scary part. The AI agrees with you way too easily. Whatever you propose, it tells you it's a great idea. If you have experience, you push back, or you ask it to push back on you. If you don't, you can't tell when you're wrong. Nobody is going to tell you.

## So, what happens to developers?

I see a few shifts.

**Less typing, more deciding.** The job moves toward specifying, designing, reviewing, challenging, and operating. The keyboard becomes less important than the whiteboard.

**Domain knowledge beats language knowledge.** Being "the Java person" matters less. Being "the person who understands payments" matters more. If English is the programming language, understanding is the compiler.

**The junior problem.** This one worries me. Seniors built their judgment by writing a lot of code, making a lot of mistakes, and fixing them at 2 AM. If juniors don't write the code anymore, how do they build that judgment? Where does the next generation of seniors come from? I don't have an answer. I only have the question, and I think we should ask it louder.

**Domain experts building software.** It's great for prototypes and internal tools. But someone still owns the 2 AM incident. Someone still does the security review, the data migration, the upgrade nobody wants to do. Will domain experts want that part too? Some will. Many won't. And that's where developers, or whatever we'll call them, will still be needed.

## Both stories are right, and wrong

So, will AI eat our jobs, or multiply them? Yes.

AI eats tasks, not jobs. At least not all of them. It eats the typing. It doesn't eat, not yet, the understanding and the accountability.

Output capacity explodes. But the constraint moves to deciding, reviewing, and operating. Ten times the code doesn't mean ten times the value.

The entry barrier drops, and that's the real revolution. Many more people will be able to build software. Not everyone, and not without understanding the problem. But many more than today.

In my vibe-coding post, I wrote: "Code is dead, long live coders." Let me update it a little: code is cheap, understanding is expensive.

And you? Which side of your feed are you on?

---

Photo by <a href="https://unsplash.com/@etiennegirardet?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Etienne Girardet</a> on <a href="https://unsplash.com/photos/a-pile-of-black-and-white-wires-and-a-cassette-OA0qcP6GOw0?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
