---
layout: post
title: "I built a Node.js library over a weekend. I don't know Node.js"
author: Mauro Servienti
synopsis: "After my vibe-coding experiment, I went back for round two: a transactional session for Node.js, the outbox pattern, NServiceBus compatibility, published to npm and NuGet. Fun, surprisingly easy, and a lot less couch-and-broken-leg drama than last time."
header_image: /img/posts/zusammen/header.jpg
tags:
- ai
- nservicebus
- messaging
- distributed-systems
---

## TL;DR

I built [Zusammen](https://github.com/mauroservienti/Zusammen). It means "together" in German. It's a transactional session for Node.js: business data and outgoing messages are committed together, or not at all. It's the [NServiceBus transactional session](https://docs.particular.net/nservicebus/transactional-session/) idea, brought to a platform I can barely spell.

I built it with [Claude Code](https://claude.com/product/claude-code). It was fun. It was also, and this annoys me a bit, surprisingly easy.

And yes, it's real. `npm install @zusammen/core@next`. It's an alpha, and I'm a Node.js ignorant, so be gentle :-)

## Round two

Last Christmas (stop singing... ;-)), I [tried vibe-coding](https://milestone.topics.it/2026/02/11/vibe-coding.html). I had a half-broken leg, a couch, and a credit counter going down like a Ferrari pit stop. The parrot got stuck in loops, I played dumb, and things went sideways. The lesson was clear: stop playing dumb, be the manager.

So this time, I did exactly that. The rule stayed the same, though: a technology I know nothing about. Node.js, TypeScript tooling, pnpm, ES modules, npm publishing. I know what a `package.json` is. That's it. That's the list. What I do know is the problem space. Messaging, the outbox, NServiceBus. I could judge the "what". I couldn't judge the "how".

> Spoiler: knowing the problem matters way more than knowing the language. Who would have thought.

## So, what did we build?

The problem fits in one sentence:

> A web request stores an order and publishes an `OrderPlaced` event.

Two operations, two infrastructure pieces, one crash away from a ghost message or a zombie record. I already wrote about [what an outbox is and why we need it](https://milestone.topics.it/2023/02/07/outbox-what-and-why.html), so I won't bore you twice.

This is what it looks like in Node.js:

```typescript
await using session = await factory.open();

await orders.insertOne(order, { session: session.transactionContext });
await session.publish(new OrderPlaced(order.id));

await session.commit(); // data and messages, atomically
```

How it works, in four points:

- `send()` and `publish()` don't send anything yet. The messages wait in memory until `commit()`.
- On `commit()`, the outgoing messages are stored in an outbox record, in the same MongoDB transaction as the business data.
- Right after the database commit, still inside `commit()`, the messages are dispatched to RabbitMQ, and the outbox record is marked as dispatched. With the web framework adapters, this happens before the HTTP response leaves. In the normal case, by the time the client gets its `201`, the messages are already on the broker.
- Before committing, a control message also goes to RabbitMQ. It's the safety net, not the delivery path. If the immediate dispatch fails, or the process dies right after the commit, whichever instance receives the control message finishes the job. There's no polling. Most of the time, it arrives, finds everything already dispatched, and does nothing.

And if the commit takes too long, the control message stores a tombstone. A late commit fails instead of sneaking in without a safety net.

### Wait, a tombstone?

Yes. It sounds dramatic. It's actually a very small thing that solves a nasty problem.

The control message is sent _before_ the commit. That's on purpose. If we sent it after, a crash between the commit and the send would leave committed messages with nobody to dispatch them. The safety net is meant to be there first.

But that creates a race. The control message can arrive before the commit lands. It looks for the outbox record and finds nothing. Now what? There are two possibilities:

- The commit is still on its way. It's just slow.
- The commit will never happen. The process crashed, or the transaction rolled back.

From the outside, the two look identical. No record is no record.

So the control message waits and checks again, a few times, with growing delays. But it can't wait forever. Sessions that never commit would keep control messages bouncing around forever.

At some point, it has to give up. And that's the dangerous moment. Imagine giving up, and then the slow commit lands one second later. The business data is committed. The outgoing messages are in the outbox. The process will try to dispatch them right away, sure. But if that dispatch fails, or the process dies a millisecond after the commit, nobody is coming to rescue them. The safety net already went home. Data without messages: exactly what the outbox was supposed to prevent.

The tombstone closes that gap. When the control message gives up, after the commit window (15 seconds by default), it doesn't just walk away. It writes an empty outbox record with the same session ID, already marked as dispatched. A tombstone: "this session is dead, don't come back."

Now the late commit tries to insert its own outbox record. Same session ID, and that ID is unique. The insert fails, so the whole transaction fails, including the business data. The user gets an error. Nothing is half-done.

In other words, either the commit wins and its messages are guaranteed to go out, immediately or through the control message, or the tombstone wins and the commit fails. Exactly one of the two. Never both, never neither.

And tombstones don't pile up. They expire like any other dispatched outbox record.

The idea comes straight from the [NServiceBus transactional session](https://docs.particular.net/nservicebus/transactional-session/#failure-scenarios-commit-takes-too-long), which solves the same race the same way.

What's in the box:

- The core, MongoDB persistence, and a RabbitMQ transport.
- Express, Fastify, NestJS, and Hono adapters. They commit before sending the response, so the client never sees success for a failed commit.
- Opt-in NServiceBus wire compatibility, plus an optional tiny NuGet package for the receiving side.
- More than 180 tests, with Testcontainers, and compatibility tests against a real NServiceBus 10 endpoint.
- Eight npm packages, with provenance and trusted publishing, and one NuGet package.

## The plan came first

I didn't start from code. I started from a plan document I had written. Claude's first move was to poke holes in it.

My plan said "exactly-once". Claude said: no, that's an overclaim. It's at-least-once dispatch, and receivers must be idempotent, unless they have outbox support. Fair.

From there, it was nine phases. Each one was a branch, and later a pull request. My job was mostly reading, deciding, and typing "merge and continue". Repeat.

> The plan is the product. The code is a side effect.

## Being the grown-up in the room

Being the manager doesn't mean saying "yes" to everything. A few times, the parrot needed a firm hand:

- The processor role: Claude wanted a separate processor, as NServiceBus supports it as optional. I explained why it exists in NServiceBus and Zusammen doesn't need it for now. Gone.
- The long-running consumer: Claude said processing control messages needs a long-running process. I disagreed. Once the session is committed and the control message is out, the process could die in hell. Another instance picks up the message. Claude agreed, and then overcorrected with a whole handler-and-host abstraction.
- I asked: on RabbitMQ, isn't monitoring the queue simply the handler's job? It took three messages to land on the obvious design. Typical Monday, but on a Saturday.
- Resources: Claude happily created queues and collections at startup. In real life, ops people own those. Now it's opt-in, with `createResources: true`. By default, it only checks that everything exists and fails with the list of what's missing.
- NServiceBus everywhere: At first, NServiceBus compatibility was mandatory. I made it opt-in. RabbitMQ has many requirements, but when SQS comes, things will be more relaxed. No reason to pay that price everywhere.

## Where it surprised me, in a good way

The tests found real bugs. And Claude didn't just retry them until they turned green.

**The happy path with duplicates.** A RabbitMQ test passed, then failed when Claude ran it again to check for flakiness. The same event arrived twice. The control message reached the consumer before the immediate dispatch had marked the outbox record as dispatched. At-least-once allows that, but in production, duplicates would have become routine. The fix: delay the first control message. Simple, once you see it.

**MongoDB doesn't say what you expect.** When the tombstone wins the race, MongoDB answers with a write conflict, not a duplicate key error. Claude didn't guess. It wrote a throwaway probe against a real MongoDB container to see what actually happens. Then it mapped the error.

**The NServiceBus source code.** To verify the wire format, Claude read the NServiceBus.RabbitMQ source. It found that, on receive, the AMQP `type` property silently fills a missing `NServiceBus.EnclosedMessageTypes` header. That would have broken my design for unmapped message types. I've worked at Particular for 13 years, and I still do. Yeah.

**Proving the tests work.** A few times, it broke its own code on purpose, just to prove the tests catch it. Then it restored it.

> I was ready to ask, "how do you know the test actually tests something?" It asked itself first. Rude.

## Where it face-planted, also fun

Let me be honest. It wasn't all roses.

**The first release failed.** The workflow ran `npm publish npm/zusammen-core-0.1.0-alpha.1.tgz`. npm read `npm/zusammen-core...` as a GitHub repository and tried to clone it over SSH. Ahahah. Nothing was published, luckily. The lesson: dry-run the publish loop, not only the packing step.

**The confident README.** It overwrote the wrong table in the README. It noticed, restored the file, and redid the edit. Another time, it wrote "MongoDB 4.4+ supported". Nothing tested that. It caught itself and wrote what the tests actually cover.

**npm and the four minutes of panic.** After publishing, npm answered 404 for every package. For four minutes. I was getting nervous. Claude just polled the registry until the packages showed up. Calmer than me, I have to admit.

**Me, from the iPad.** I tried to move the release tag from my iPad, through SSH to my Mac. Nothing happened, and I wasn't sure. "Can you check the tags?" It could. It fixed it. Who's the junior now?

**NServiceBus being NServiceBus.** The compatibility tests needed a real NServiceBus endpoint. Assembly scanning picked up an installer we didn't configure. The RabbitMQ management API was on a random port. The .NET MongoDB driver saw our test replica set as a standalone server. None of these were Claude's fault. All of them were fixed, one by one.

## The boring stuff that isn't boring

On side projects, this is the part nobody does. Here, it got done along the way:

- A README, a README per package, guides, and two runnable samples.
- CI on Node.js 22, 24, and 26, plus .NET.
- A protected main branch, squash-only pull requests, and Dependabot. TypeScript is pinned to 6 for now, because typescript-eslint and TypeScript 7 aren't friends yet. There's an issue for that.
- Tag-based releases, SemVer, npm provenance, and trusted publishing. Including the chicken-and-egg problem: npm can't trust a package that doesn't exist yet.
- A conformance matrix against the NServiceBus TransactionalSession acceptance tests, with a weekly check that fails when upstream adds a new test.

## So, is it easy now?

Yes. Surprisingly. But only because I knew what I wanted and could tell when an answer smelled off.

Compared to the vibe-coding experiment, the difference is huge. No credit-burning loops. No couch, but also no broken leg ;-P. Just a plan, phases, pull requests, tests, and me saying "merge".

Knowing the domain beats knowing the language. I still can't tell you how pnpm resolves workspace dependencies. I didn't need to. Should I learn it? Probably. Maybe later.

What's next? Receiving and handling incoming messages, with an inbox. That would make Zusammen an NServiceBus implementation for Node.js. Then Azure Service Bus, SQS and SNS, PostgreSQL, MySQL, and SQL Server. The issues are open. Contributions are welcome, from humans and parrots alike.

Give it a try. `npm install @zusammen/core@next`, and tell me what breaks. Something will. It's an alpha, and I don't know Node.js ;-)

---

Photo by <a href="https://unsplash.com/@lingapp?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Ling App</a> on <a href="https://unsplash.com/photos/the-word-together-spelled-with-scrabble-tiles-on-a-wooden-surface-qo455fyS_Vw?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
