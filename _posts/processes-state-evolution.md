---
layout: post
author: Mauro Servienti
title: "Distributed systems evolution: processes state"
synopsis: "Evolving distributed systems architecture is challenging. Addressing message evolution is one aspect. Another one is evolving existing processes and their persisted status."
header_image: /img/posts/processes-state-evolution/header.jpg
enable_mermaid: true
series: distributed-systems-evolution
tags:
- distributed-systems
---

In the first two articles of the [distributed systems evolution series](https://milestone.topics.it/series/distributed-systems-evolution), we described the [challenges](https://milestone.topics.it/2022/06/11/distributed-systems-evolution-challenges.html) and discussed what [evolving message contracts](https://milestone.topics.it/2022/07/04/messages-evolution.html) implies.

Like message contracts, we want and need to evolve long-running processes and their persisted state.

Hold on, Mauro. That's too fast.

## What's a long-running process, again?

I've written extensively about [long-running processes and sagas](https://milestone.topics.it/tags/sagas.html) before. In a nutshell, a long-running process is a process that spans multiple invocations, triggered by different events, and whose state is persistent across the various requests. It's crucial to highlight that long-running has nothing to with the time it takes to execute. It could be 2 minutes or 10 years. It's just something that doesn't happen _right now_.

For example, an image optical character recognition (OCR) process is long-running. It's initially triggered by uploading the image to process. Then the image is queued for processing. When processing starts, the process state is changed to indicate that and the subsequent processing progress. Finally, the processing completes, and the process state is updated accordingly. The following is the visual representation of the process:

<div class="mermaid">
sequenceDiagram
   Web client ->> Rest API: HTTP request
   Rest API ->> Backend: Queue message
   Backend ->> Long-running process: Trigger long-running process
   Long-running process ->> Database: Manipulate data
   Long-running process ->> Backend: Process completed
   Backend ->> Rest API: Topic event
   Rest API ->> Web client: WebSocket message
</div>

In the [previous article](https://milestone.topics.it/2022/07/04/messages-evolution.html), we imagined that the new business requirement is to add an option for users to choose from multiple payment methods. We analyzed how the need affects message contracts and how to address the many challenges.

For the sake of the discussion, let's now imagine a new business requirement: we must comply with GDPR requirements. To do so, we need to show users the privacy policy and keep track of whether users accepted the privacy policy for each OCR processing request.

Sounds trivial. Ultimately, it's a boolean value that only needs a checkbox on the user interface. First, we need to carry that value around, and to do so, we need to update message contracts.

Second, Let's look at how that affects a relational database.

We could add a new column to the schema if we need to keep track of the privacy acceptance. A bit type sounds like it's enough. However, that comes with some headaches. If we change the schema, we immediately break the compatibility with running and completed processes. They know nothing about privacy acceptance. We assume they didn't accept the policy, or we decide to add the new column as nullable. If the value is null, the process is from when that requirement was non-existent; otherwise, we respect the set value.

It's not pleasant, but it works. Let's now extend the requirement a bit. Imagine some countries do not require any privacy policy acceptance. That complicates the data schema a lot. Besides the nullable bit column, we need a country column. The new country column must be nullable, too, to be backward compatible.

I guess you see the problem. As we implement new requirements, the code becomes an explosion of permutations to handle all the possible scenarios. A mitigation strategy could be having a column representing the process version. The code can make assumptions about the database schema based on the version number.

> To be precise, the problem doesn't arise because of the rigid nature of relational databases. The same situation applies to any storage type. The problem manifests in code if we use a key-value store or a document database.

## Do we have to store everything in the same table?

The quick answer is no. We tend to do that because we're used to it and because requirements usually dictate processes' evolution or extensions. Those words are tricky and lead us to think there is an excellent reason to extend the current process instead of creating a brand new one. The object-oriented programming mindset also kicks in, telling us that inheritance is an excellent technique to evolve something. Extension, again.

As for messages, I advise creating a new process that handles the new requirements. Sooner or later, all the instances of the old process will be complete enabling us to remove the handling code and set a timebomb on the data based on the applied retention policy.

If you're using [NServiceBus sagas](https://docs.particular.net/nservicebus/sagas/) to handle long-running business processes, create a new saga type for the new process. NServiceBus will take care of the rest.

## Retroactive vs non-retroactive

Let's start by saying that in the last twenty years, it happened to me a handful of times to witness the requirement for retroactive changes. It happened primarily in the context of the Italian tax system, which is a mess on its own, and in the context of fixing errors introduced by previous requirements, which was rare.

What we outlined so far helps in dealing with non-retroactive changes. There is a new requirement, and a new process is created to handle that. Old instances will continue using the old method.

Dealing with retroactive changes requires at least one of the following approaches:

- Stopping the affected portion of the system and altering the data schema.
- Having control over the data loading/mapping process to alter schema on the fly

The first is the simplest one. A retroactive change requires changing running process instances. To do so, we must change the handling code and data simultaneously. It's indeed a breaking change. Altering the schema must be done along with changing the code. Stopping the portion of the system responsible for that process becomes a must. That's one of the beauties of distributed systems, though. We could stop only the services affected by the breaking requirement and keep the rest of the system running.

The latter is a bit more involved and comes with some technical prerequisites. Let's imagine we're using a document database or a key-value store.

We could change our code to intercept data load operations and alter the data on the fly before they are available to the service needing them. It's a powerful advanced technique that allows to gradually change data schema retroactively as the system touches them with no big upfront, downtime-prone, data-altering effort. Unfortunately, that technique depends too much on the storage technology, the SDK access, and the data retrieval pattern.

### Can we use a similar technique for message retroactive changes?

Of course, we can. If we were using NServiceBus, the [Pipeline](https://docs.particular.net/nservicebus/pipeline/) would be the perfect extension point to mutate incoming or outgoing messages and transform them into what we need to satisfy new requirements. That means a message of type A can become of type B before being processed, effectively applying breaking changes to in-flight messages.

## Conclusion

The technique described in this article is not that different from the one I suggested for evolving message contracts. As in many other cases, the most straightforward approach is preferable. Do not try to extend what we already have; there is a high chance it will become an over-engineering nightmare. Instead, benefit from the autonomous nature of distributed systems and introduce new structures to handle the new requirements.

---

Photo by <a href="https://unsplash.com/@ideasboom?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Qingbao Meng</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
