---
layout: post
title: "I tried vibe-coding. It’s cool, indeed, but is it doomsday?"
author: Mauro Servienti
synopsis: "Is AI going to replace software engineers? I decided to road-test it with a real-life coding challenge: build an application from scratch using a technology I barely knew. The goal? Understand if all those claims about the programmer's doomsday have some foundation."
header_image: /img/posts/vibe-coding/header.jpg
tags:
- ai
- integration-testing
- testing
reviewed-by: [kbaley]
---

## TL;DR

Are LLM and AI the doomsday? In a sense, yes, they are. At least in software development, which is my field of expertise, they look like a revolution. I can probably summarize it with, “Code is dead, long live coders.” Or if you prefer, English is the new programming language.

> For this article, I’m referring to the use of AI and LLM in the context of software development, and not, for example, in the context of medicine development or hospital test analyses, [where things are anyway not (yet?) so great as generally pictured](https://worksinprogress.co/issue/the-algorithm-will-see-you-now/).

## What’s vibe-coding?

![A vibe-coding meme](/img/posts/vibe-coding/vibe-coding-meme.png){:class="img-fluid mx-auto d-block"}

If you haven't been living under a stone for the last couple of years, you should probably know that there is a group of people, not small, that believes we, software engineers, are all toast and destined to disappear because of AI. LLMs are so great at writing software that the no-code movement will take over, and with the help of LLMs, it’ll make software engineering a relic from the past.

Effectively, my LinkedIn feed is full of people, quite annoying to be honest, claiming that using AI, they’re producing software like never before, without even knowing what software engineering is.

## I wanted to see it with my own eyes

And thanks to a decently serious race bike crash—I tried to prove that doing a 360 and landing with a leg on the concrete edge of the sidewalk would have broken the edge, not the leg—I had some downtime. Luckily, I did not break a leg or the edge of the sidewalk, but I managed to injure myself seriously enough not to be able to walk for about ten days. All that forced me to the couch for a couple of weeks and allowed me to experiment a bit with something I'd wanted to try for a while: vibe-coding (as the cool kids say… I’m not cool and not a kid anymore). Before diving into my journey, from the initial crappy experience to the juice, let me quickly mention a couple of things.

I’ve been using LLMs more or less since day one. I have a [Claude](https://claude.ai/) subscription, and I’m pretty happy with it. I utilize it for a variety of tasks, from helping me with training plans to assisting with coding.

So far, my experience with LLMs has been that it’s critical to be able to validate the LLM's response. And water is wet, one could argue :-)

By being “able to validate,” I mean the following:

1. You have a clear understanding of the problem you’re trying to solve
2. You have enough knowledge of the possible solutions to validate them

In essence, you could solve the problem yourself, and the LLM is an accelerator, sometimes a very good and fast one.

Let me give you an example: If you’re reading this article directly on my website, you probably noticed that it now supports dark mode (in the top-right corner, there is a little icon to switch).

Dark mode has been one of my long-standing wishes, but to get to it, there were a couple of blockers:

- Upgrade Bootstrap to the latest version
- Find a replacement for the no-longer-supported carousel-like component running on the home page

Those were the typical steps for a side project like a blog, so daunting that I never had the energy to look at them, especially when the only time you can work on them is Sunday morning, when everyone else is still sleeping.

Last weekend, I opened VS Code, started the devcontainer, and installed [Claude Code](https://claude.com/product/claude-code). Once everything was set up, I explained to the LLM what I wanted, and I asked Claude two things:

- To create a plan to upgrade Bootstrap to the latest version: It started working, asked me several questions to better understand what I wanted and how to handle certain choices, and finally created a plan. A copy of the [plan is in the repository](https://github.com/mauroservienti/milestone.github.io/blob/master/docs/bootstrap-upgrade-plan.md).
- To prepare a summary as a future context reference: You can find that in the [REPOSITORY_CONTEXT](https://github.com/mauroservienti/milestone.github.io/blob/master/docs/REPOSITORY_CONTEXT.md) document in the GitHub repository.

I kicked off the implementation and let it work for quite some time. Once it was done, I had all I wanted: the latest Bootstrap, a new way to render the home page, and dark mode. We worked together to fix a bunch of issues and finally committed it all. Impressive, especially if you think that it took about 45 minutes.

I then left to bring the little one to one of those incredibly boring kids' birthday parties...don’t get me started. While there, I decided to have a look at the dark mode results on a mobile device. I was in a hurry and didn’t check them at first. They weren’t great. I went ahead and raised [an issue](https://github.com/mauroservienti/milestone.github.io/issues/336) in the repository and assigned it to Copilot. Copilot analyzed the problem, raised a [PR](https://github.com/mauroservienti/milestone.github.io/pull/337), and fixed it for me. It was not a complex bug, but still.

When I got back home, I decided to quickly check [PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/?url=https%3A%2F%2Fmilestone.topics.it%2F) for this website. Once the report was ready, I took screenshots of the desktop and mobile results and uploaded them to Claude Code. It prepared a plan, asked me for confirmation, and did the following:

- Searched all the images that require optimizations
- Resized and compressed all of them
- Created a webp version for each one
- Updated the various HTML layouts to use the webp version and fall back to regular images when needed

Finally, it asked me if I wanted a new GitHub Action to do that automatically whenever a new image was uploaded. It did it all, and now those PageSpeed Insights are so much better. Since then, I have marked as completed plenty of GitHub issues that have been around for years.

## It’s not so easy, though. It’s like dealing with a junior developer

There is an important aspect to mention. If you take a look at the [above-mentioned issue](https://github.com/mauroservienti/milestone.github.io/issues/336) I crafted for Copilot, there is the following sentence at the end:

> While fixing the issue, make sure that the desktop version is not affected

You need to become a manager who needs to talk to a junior who doesn’t know how to organize themselves.

Let’s face it, the LLM is dumb; it’s way, way worse than the worst junior you can think about. It’s a stochastic parrot that is exceptionally good at “parroting,” but a parrot remains — unless given extremely clear instructions with clear boundaries, what could happen is sort of unpredictable. Requirements must be clear. For example, you have to ask the LLM to craft a plan, carefully review it, and then challenge some of the assumptions, because you realize that your requirements were not so clear.

<iframe width="560" height="315" src="https://www.youtube.com/embed/FN2RM-CHkuI?si=dONuXMeX_3wgBwbU" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

You're the kids, and dad is the LLM.

## December 26th: The experiment started

Let me walk you through what started as a “what could possibly go wrong” experiment and turned into beauty.

I started by playing dumb and pretending I knew little to nothing about coding. I also decided to use technologies I’m unfamiliar with.

I opened the terminal in VS Code and launched [Claude Code](https://claude.com/product/claude-code). I wanted to build a budgeting/expense-tracking application. I presented a set of basic functional requirements and asked for:

- AWS Lambda with .NET/C# for the backend
- DynamoDB as a storage
- Vue.js for the frontend
- Google Authentication support

I also requested the ability to execute the application locally on my MacBook Air using LocalStack to emulate AWS services.

Straightforward, not incredibly complex, but with a lot of moving parts. Could I do it myself? More or less:

- I have some familiarity with AWS Lambda and DynamoDB
- I think I know C#
- I know nothing about Vue.js and little about frontend development, even though I did quite a lot of that 15 years ago
- I worked with identity providers in the past
- I used LocalStack from time to time

It worked for ages, using up all my credit on the first day of vibe-coding. The result? It did not even compile. The problem was sort of trivial: package dependencies were messed up, causing all sorts of compilation issues. The thing is, the LLM was stuck in a loop, trying to update the code and change the dependencies simultaneously. It was updating the code to reflect the current dependencies, but changing the dependencies was making the updated code invalid again...

Remember, I knew what the problem was, but I was acting like a cool kid vibe-coding. I pretended I knew nothing. After the first credit exhaustion and waiting and waiting, what I had was:

- A set of projects:
  - A Vue.js application (I have not yet touched)
  - A .NET C# project with (compiling) AWS Lambda functions
- A Docker compose file to deploy LocalStack
- A set of bash files to
  - Deploy AWS resources, such as Lambda functions and DynamoDB, including table creation
  - Seed test data to the DynamoDB table

### I decided to ask the LLM what the next step should have been

Again, pretending I knew nothing, I asked the LLM what to do next. To my surprise, it created a TODO.md in the root of the git repo, with plenty of details about the next steps, including several business requirements, and suggested that we try what we had. I happily said, Let’s go!

I ran out of credits once more... the thing is, it got stuck in an incredibly bad, vicious loop (again): it deployed resources to LocalStack, created the DynamoDB table, seeded the data, and deployed Lambda functions. It then started the Vite HTTP server to serve the application's frontend and happily told me, "Everything works. Head to localhost:3000 and try it out."

Yeah, sure. The application was blowing up as if there was no tomorrow. HTTP 500 errors everywhere.

I still acted like I knew nothing and let the LLM envelop itself in finding a solution. The problem was that the functions it designed used DI to inject services into the function's constructor. After several failed attempts, the LLM stated that it was a LocalStack limitation that didn’t provide the required surrounding infrastructure.

> Checking now, while writing this post, I have a feeling that Claude blundered and simply wrote the worst possible Lambda functions.

A new, never-ending loop started, and I ran out of credits again. It tried to move away from constructor injection toward a service locator approach, but it didn’t work, and in retrospect, I believe it was simply about not wiring up dependencies into the `ServiceCollection`. Remember, I was playing dumb; that code is long gone, and I cannot validate my gut feeling anymore.

When credit was restored, I asked whether using Node.js for the Lambda functions would have been easier. And guess what? In a very condescending way, the LLM is always left-footed to the point of being condescending; it told me, "Yes!"

To my surprise, though, that worked, and in the blink of an eye, only interrupted by another credit burndown..., I got my AWS Lambda functions up and running.

### Did I?

Well, not so quickly. To give some credit where credit is due, the LLM proposed starting by converting only two functions, out of a dozen, to test them. Once the conversion was complete, it proposed testing them using `curl` to directly invoke the functions. Sure, good move.

It ran the Docker compose file, the various bash scripts to deploy everything, including the newly converted functions, and finally, executed the HTTP requests. It worked!

> Keep in mind that every single freaking action you ask or allow the LLM to perform consumes thousands of tokens, and that's your credit.

Anyway, was I done? Ahahah, I was hoping so, but: No.

I let the LLM convert the remaining .NET functions to Node.js and, after deploying the new code and starting the front-end application, a new nightmare emerged.

I know, you were waiting for it. My leg and I, not so much.

### Please welcome the API Gateway

The LLM completely missed the API Gateway configuration.

Reasonably, the front-end application had no way to talk to the back-end services. It was stuck for a while, and what unblocked it was me asking what the problem was. It seemed that describing the problem out loud helped it realize how to solve it. Claude tried, failed, and ran out of credits while configuring the Gateway in LocalStack.

I have no idea what the problem was. When the credit was restored, Claude concluded that LocalStack had poor Gateway support (I knew it wasn't the problem) and decided the solution was to change the Vue.js application's proxy configuration to talk directly to the functions... Guess what? It didn’t work, and I ran out of credits again.

> Running out of Claude credits was the soundtrack of my Christmas holidays on the couch with a half-broken leg.

### I started banging my head against the wall; I couldn’t play dumb anymore

> That is when I realized I had to be the manager managing the very junior developer.

This is the turning point. You must be a software engineer; you need that experience.

I went myself to the LocalStack documentation on configuring the AWS API Gateway and _not so kindly_ (when the judgment day comes, they’ll look for me, I know), suggested Claude read that link. It did it and finally correctly configured the Gateway. The front-end was still not working, as expected, because I knew what the other thing the LLM completely missed: CORS. But before I could instruct it to reconfigure the Gateway with CORS support, I ran out of credits. The LLM was, reasonably, unable to understand that the front-end and back-end were running on different hosts.

I then made the mistake of looking at the DynamoDB schema that had been created. In production, that crap would have melted my credit card (not my tokens/credits this time) in the blink of an eye. It was using table scans in so many places that I had to ask the LLM to go back to the drawing board and gently instruct it about what design to apply where. The only good thing was that the LLM automatically updated the bash scripts to seed the data and the corresponding Lambda functions upon changing the table schema for a specific entity.

At that point, I had a semi-functional (local-only for now) application. Claude was also completely missing any kind of security support. It’s worth mentioning that I didn’t ask for it. The result was that the API Gateway setup allowed everyone to talk to my Lambdas and thus access the DynamoDB data. Which is very bad.

> Again, it was my fault. By playing dumb, I simply left out the technical requirements and implementation boundaries. The LLM was groping in the dark, doing what it could.

Meanwhile, I realized another thing that has been triggering me for all that time: The LLM is a lap dog. It constantly tells you how great your ideas and suggestions are. You need to challenge yourself, or ask the LLM to challenge you. You must go through discussions and challenging conversations with the parrot.

## Was it good for something?

Oh, absolutely yes! When I stopped playing dumb, the world changed, and the experience was delightful.

### Front-end user interface, integration tests, security, and GitHub Actions

I decided to play in a different league and change my relationship with the LLM. The first thing I did was to craft a few [skills](https://code.claude.com/docs/en/skills) for the tasks I wanted to complete:

- A DynamoDB expert, specialized in [single-table design](https://aws.amazon.com/blogs/compute/creating-a-single-table-design-with-amazon-dynamodb/)
- A CI/CD specialist with integration testing skills
- A security reviewer
- And a front-end designer/coder skilled with Vue.js

Interestingly, I used GitHub Copilot to initially craft those skills, which I gradually refined to suit my needs. Skills impose boundaries on LLM behavior; whatever it does tends to conform to the rules and guidance defined by the selected skill.

I used some of the skills to review and improve code that was already written, and it worked great. I used the security reviewer skill to identify a major security flaw I already knew about: there was no security... I now have Google Authentication through AWS Cognito, and the API Gateway is configured to require JWT tokens for each API route. It even implemented token refresh logic on the front end to keep the token alive for longer sessions.

Finally, I greatly enjoyed interacting with the CI/CD and front-end specialists. These were the areas with little to nothing. I asked for a plan to implement what I wanted, iterated on it multiple times, and finally kicked off the implementation.

Let me use CI/CD as an example: I wanted to deploy to AWS automatically when tagging the repo. The LLM crafted a CI workflow to run front-end and integration tests for each commit/PR and a deploy workflow that, upon tagging, detects what’s changed, e.g., front-end, back-end, or both, and based on the change type runs the corresponding tests and finally deploys to AWS the changed artifacts using CDK and CloudFormation stacks.

## Final thoughts

I’m drawing several conclusions from this experience, which, by the way, is far from being completed.

### Are we screwed?

The most important thing is that I’m not sure where people are drawing the conclusion that our jobs are toast. Without an experienced software engineer with management capabilities and good business analysis and knowledge, the LLM remains a wonderful parrot. My concern is that whoever enters this industry today will have a hard time building the experience needed to manage AI and achieve their goals.

Along that line, the AI models' condescending nature is concerning. Whatever you say, the LLM makes you feel the best and that you're always right, and that's not great; it's the opposite, especially if you’re lacking the experience to challenge those answers. It’s dangerous. Challenging the LLM and asking to be challenged (yes, it works) are critical aspects of the human-to-AI relationship. But again, you need that long-term software engineering experience to do that.

### The art of the prompt

By taking the wrong path first, I realized that when the LLM gets caught in a chicken-and-egg problem, asking it to explain the problem is like asking a rubber duck for help. That’s why I have two of them ;-)

![My rubber ducks](/img/posts/vibe-coding/ducks.jpeg){:class="img-fluid mx-auto d-block"}

I also understood that open-ended prompts are the worst. Always provide a prompt with a clear definition of done; without that, the LLM never asks for clarifications and goes directly into the abyss. In line with this, each task must be as small as possible and well-structured, which raises an interesting question: How can I achieve project completion by providing only small, precise tasks, without becoming a micro-manager?

### What about security?

It’s a shit show, pardon my French, it’s non-existent. That means threats like prompt or skills injection are a severe concern. For the love of whatever you love:

- Do not allow the LLM to access the entire disk; scope the access to the directory you’re working on. Many of these tools have the concept of a sandbox
- Read the skills documents or any other document before linking or uploading it to the LLM if you do not trust the source, and sometimes even if you trust it
- Be careful about what you share with the LLM, unless you configured it to not use your data for training purposes, whatever you share will be kept forever; this is particularly important when it comes to company/employer-related data

### Analyze, plan, divide, and conquer

A waterfall-like approach really works well when dealing with AI to generate working and meaningful code. If you’re starting from an existing codebase, ask the LLM to analyze it and document its understanding in a markdown file. That, or those, files can be used later to give the LLM an initial context, removing the need to go through the codebase every time. Otherwise, it’s a token burner, a bottomless pit.

For a greenfield project, you can start with an analysis document and go through several rounds of back-and-forth chats with the LLM to define high-level requirements. You can ask the LLM to behave like a business analyst, and even craft a dedicated skill for that.

Once the context, in the form of an analysis or requirements, is ready, we can move to the planning phase and ask the LLM to go a bit deeper into the functional and technical requirements. Whatever works for you generally works for the LLM. You could use epics and user stories, event storming, or any other structure you're familiar with.

It’s now time to move to the task definition. Each phase of the plan can be further subdivided into more granular phases or tasks. Each one has clear requirements, a definition of done, and is not open-ended.

Once all that is ready, we can move to the implementation phase, letting tools like Claude Code have fun playing with writing code.

A very effective approach throughout all the presented stages is to ask the LLM to keep the context-related files up to date and add learnings. All that makes follow-up coding sessions even more effective and, again, cheaper in terms of token consumption. Similarly, to limit the dangerous condescending behavior, challenge the LLM and ask to be challenged. It’s fun when you succeed in making the LLM tell you that you are wrong.

Once you're familiarized with all that, move to a structured framework like [Get-Shit-Done](https://github.com/glittercowboy/get-shit-done) and have fun!

---

Photo by <a href="https://unsplash.com/@tinkerman?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Immo Wegmann</a> on <a href="https://unsplash.com/photos/a-piece-of-cardboard-with-a-keyboard-appearing-through-it-vi1HXPw6hyw?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
