---
layout: post
title: "Under pressure: when the tool is faster than my brain"
author: Mauro Servienti
synopsis: "I finally have a tool that can bring all my ideas to life. The catch? It's so fast that my brain became the bottleneck. Here's how I'm trying to keep up without burning out: scoped workspaces and a bird's-eye view of everything."
header_image: /img/posts/brain-is-the-bottleneck/header.jpg
series: lifehacking-101
related:
- 2021-11-17-slow-down.md
- 2022-09-19-one-list-to-rule-them-all.md
- 2022-01-10-lazy-check-list-for-everything.md
- 2026-11-02-ai-eats-or-amplifies.md
- 2026-10-21-zusammen.md
tags:
- ai
- time-management
- self-organization
---

I finally have a tool that can bring all my ideas to life.

For years, my ideas list grew faster than my free time. Blog posts, OSS features, demos, small tools to scratch an itch. Most of them stayed ideas. Now, with Claude Code, many of them become real in an afternoon.

However, the tool is so fast that my brain is the bottleneck.

## Where was I?

Let me give you an idea of what a couple of days look like. In roughly two days, I reviewed and merged a blog post, scheduled its LinkedIn promotion, drafted a brand new article from an idea card, fixed broken links the link checker reported, reviewed a skill I wrote for work, and renamed a folder that had a typo in its name.

None of that is hard. All of it requires me to make decisions. Is this wording right? Is this the right publish date? Should this be one article or two?

The tool doesn't get tired. It doesn't need to remember where it was yesterday, because I hand it the context. I do get tired. And I do need to remember where I was.

> I'm having a hard time keeping up. With a tool. That I'm supposedly driving. ;P

<!-- TODO: a personal note on how it feels: evenings, weekends, the "one more thing" temptation -->

## Watch out for burnout

There's a trap here, and I can see it clearly because I've fallen into similar ones before. When doing things becomes cheap, the temptation is to do all of them. Every idea gets a branch. Every branch gets a pull request. Every pull request needs my eyes.

The cost didn't disappear. It moved. It moved from typing to deciding, reviewing, and context switching. And those are exactly the activities that drain me the most.

I wrote about this years ago in ["Lifehacking 101: slow down"](https://milestone.topics.it/2021/11/17/slow-down.html). The advice still holds, maybe more than ever. Speed is not the goal. The tool can go as fast as it wants; I decide how fast I go.

But slowing down alone isn't enough. If I want to keep many things in flight without losing track of them, I need a management system. Something that tells me, at any moment, where I am.

I have two: scoped workspaces, mainly for work, and a project board for everything else.

## Scoped workspaces

At [Particular Software](https://particular.net/), a lot of my work happens in task forces: a group of people focused on one problem for a limited time. A task force usually touches several repositories, a mix of code, documentation, and planning.

For each task force, I create a workspace. A workspace is a folder under `~/dev/workspaces/<name>`, and it contains:

- **A `README.md`**: the source of truth for the workspace. It links the task force issue and its project board, and lists the repositories with one line on what I'm doing in each of them.
- **One clone per repository** the work touches.
- **Working notes**, such as a proposal I'm drafting.

The clones are standalone. They're not worktrees or symlinks to my everyday clones. My everyday clones are used for other work, and their branches change all the time. A workspace must not be affected by what I do elsewhere, and the other way around.

The interesting part is how a workspace is born. I wrote a Claude Code skill with three commands:

- **`new <issue-url>`** reads the task force issue, proposes a short name, creates the folder, and writes the README.
- **`suggest`** reads the task force project board and recommends which repositories to bring in, based on where the open work is: bring in, optional, or skip.
- **`add <repo>...`** clones the repositories into the workspace and updates the README.

When I open a session in a workspace, the README tells the tool (and me!) what this is about. The scope is the folder. Nothing else leaks in.

<!-- TODO: a concrete example of a task force workspace, if one can be shared publicly -->

## A bird's-eye view of everything else

Then there's everything I do outside work: this blog, [ServiceComposer](https://github.com/ServiceComposer), [Radical](https://github.com/RadicalFx), NServiceBus extensions, demos, and a long tail of small repositories.

Workspaces don't help there. The problem is different. I don't need focus; I need visibility. I want to know, at a glance, what's open everywhere.

So I created a single GitHub project board. Every issue and pull request opened in any of my repositories gets added to it automatically, using the [add to project](https://github.com/actions/add-to-project) GitHub Action. Today, that's 46 repositories across my personal account and the ServiceComposer and Radical organizations. The first sync brought in 287 items. Yes, 287. That number alone was a wake-up call.

The board has views for each group of repositories: ServiceComposer, NServiceBus extensions, Radical, and demos. When I sit down for some OSS time, I don't start from a repository. I start from the board, pick what matters, and only then open the repository.

<!-- TODO: link to the board if it's public, or a screenshot -->

## Two scopes, two questions

Looking back, the two tools answer two different questions:

- **A workspace answers "what am I doing here?"** It's narrow and deep. One problem, the repositories it touches, the notes that go with it.
- **The board answers "what's going on everywhere?"** It's wide and shallow. Everything open, grouped, at a glance.

Together, they let me stop and pick up again without relying on my memory. And that's the point. My memory is the scarcest resource in this setup, not the tool's speed.

## Conclusion

AI tools made doing things cheap. They didn't make deciding cheap, and they certainly didn't make my brain faster. If anything, they made it obvious where the real bottleneck is.

So I'm doing what I always do when something exceeds my brain's capacity: I write it down, and I build a system around it. Workspaces give me focus, the board gives me visibility, and slowing down gives me the rest.

Now, if you'll excuse me, I have a few pull requests waiting for my review. The tool opened them while I was writing this ;-)

<!-- TODO: double-check the last line is true when publishing, or reword -->

---

<!-- TODO: header image and Unsplash credit -->
