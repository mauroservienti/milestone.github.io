---
layout: post
title: "Who ships the hotel form? Delivering a service's components into hosts it doesn't own"
author: Mauro Servienti
synopsis: "A service owns more than its back end: it owns UI components and composition handlers too, and they run in hosts other teams own. How do they get there, and who decides when they ship?"
header_image: /img/posts/shipping-service-components/header.jpg
enable_mermaid: true
related:
- 2027-02-02-four-plus-one-views.md
- 2022-01-25-lets-get-logical.md
- 2019-04-18-the-fine-art-of-dismantling.md
- 2021-04-20-on-viewmodel-composition-and-ui-composition.md
- 2027-01-13-searching-paging-and-sorting.md
- 2027-03-03-heyi.md
tags:
- soa
- distributed-systems
- architecture
- logical-vs-physical
- viewmodel-composition
---

In ["How does the 4+1 architectural view model help shape distributed systems?"](https://milestone.topics.it/2027/02/02/four-plus-one-views.html), I wrote that how a service's user interface component gets into the application is a development view decision, and "a topic for another article." Famous last words.

<!-- TODO: confirm we want to name the reader and link the comment thread. -->
The same question showed up years earlier, in the comments of ["Let's get logical!"](https://milestone.topics.it/2022/01/25/lets-get-logical.html). Mark Phillips comes from microservices, where one container image ships one web app and its database schema. With logical services, one service's components end up in several hosts. In a Kubernetes world, we can't drop new DLLs into a running host: every image hosting the component must be rebuilt and redeployed. How does continuous delivery work, then?

It's the same question, asked from two sides. The 4+1 article asked it about UI components. Mark asked it about back-end ones. Let's answer both, with one example.

## What are we building?

The 4+1 article used payments. This time, let's go back to hotels. [Hotelly](https://github.com/mauroservienti/hotelly), the demo behind ["Searching, paging, and sorting in a distributed system: the complete picture"](https://milestone.topics.it/2027/01/13/searching-paging-and-sorting.html), has four services:

- **Registry:** hotels, their location, stars, and amenities.
- **Reservations:** rooms and bookings.
- **Marketing:** descriptions, ratings, and reviews.
- **Sales:** nightly rates.

<!-- TODO: link the Hotelly back office scenario once it's in the demo. -->
So far, Hotelly only has a search page. Let's add a back office: the page hotel managers use to look at and edit a hotel.

> Hotels aren't "created" at once, though. As ["The fine art of dismantling"](https://milestone.topics.it/view-model-composition/2019/04/18/the-fine-art-of-dismantling.html) puts it, nobody in the business says "I want to create a hotel." Registry onboards it, then Sales sets its rates, Marketing writes its description, and Reservations configures its rooms, possibly days apart, and done by different people.

The hotel page is a composed page. Each service contributes a panel showing the data it owns, and a form to edit it:

- Registry's panel edits the name, the address, the stars, and the amenities.
- Sales' panel edits the nightly rates.
- Marketing's panel edits the description.
- Reservations' panel edits the rooms.

Each panel saves on its own. There's no single "Save" button and no distributed transaction: a manager changing the rates doesn't touch the description.

## Two hosts, neither of them yours

Let's look at what Registry owns for that page. It's more than its back end:

- **A UI component:** the panel, with its form.
- **A composition handler:** it loads the hotel's details from Registry's database, for the panel to show.
- **A decomposition handler:** it receives the form post, and sends a command to Registry's back end.

The other three services own the same three pieces. None of them runs in the service's own host, though:

<div class="mermaid">
flowchart LR
  subgraph BackOffice[Back office application]
    RUI[Registry panel]
    SUI[Sales panel]
    MUI[Marketing panel]
    XUI[Reservations panel]
  end
  subgraph Gateway[Composition gateway]
    RH[Registry handlers]
    SH[Sales handlers]
    MH[Marketing handlers]
    XH[Reservations handlers]
  end
  RUI --> RH
  SUI --> SH
  MUI --> MH
  XUI --> XH
  RH --> R[(Registry)]
  SH --> S[(Sales)]
  MH --> M[(Marketing)]
  XH --> X[(Reservations)]
</div>

The panels run in the back office application. The handlers run in the composition gateway. Both hosts belong to someone else, usually a team that owns the application, and they host code from every service.

> Hotelly already works this way for search. The composition gateway hosts the services' composition handlers and search providers. In the demo, the gateway references them as projects, because everything lives in one repository. In a real system, it wouldn't be that simple, and that's what the rest of this article is about.

The decomposition handler, by the way, is exactly the kind of HTTP endpoint that sends a message, and needs to do it atomically. That's what ["Should the HTTP endpoint do the work?"](https://milestone.topics.it/2027/03/03/heyi.html) is about.

## How does the panel get into the back office?

There are three options, and each one couples Registry's releases to the back office's in a different way.

### A package the application references

Registry publishes its panel as a package, for example an npm package or a Razor class library. The back office references it, like any other dependency.

It's the simplest option, and the most coupled one. A new panel version reaches production only when the back office team bumps the reference, rebuilds, and redeploys. Registry can't ship on its own.

Packages also share the application's dependencies. If the back office moves to the next major version of its UI framework, every panel has to follow, at the same time.

### A micro frontend loaded at runtime

Registry deploys its panel somewhere it controls, and the back office loads it at runtime, for example with module federation or web components.

Registry ships whenever it wants: the next page load picks up the new version. That's the main selling point, and it's a real one.

The price is a runtime contract. The shell and the panel must agree on how the panel is mounted, which inputs it gets, like the hotel ID, and which events it raises, like "saved." The design system is shared at runtime too, so a panel built against a different version can look out of place, or break. The contract is still there: it moved from compile time to runtime, where nothing checks it.

<!-- TODO: add a personal take on micro frontends, if any. -->

### Server-side composition

The back office asks the server for the hotel page, and the server composes it from fragments rendered by each service's handlers. That's [ViewModel Composition](https://milestone.topics.it/series/view-model-composition.html), with HTML instead of JSON, or with JSON and a client that renders each service's part.

This moves the problem rather than solving it. The panel lives on the server now, in the composition gateway. That's the second host, and the second half of the question.

> ["On ViewModel Composition and UI Composition"](https://milestone.topics.it/view-model-composition/2021/04/20/on-viewmodel-composition-and-ui-composition.html) goes deeper into the difference between composing data and composing UI.

## How do the handlers get into the gateway?

That's Mark's question. The gateway is a container image. Registry's handlers are compiled into it. A new handler version means a new gateway image.

### Packages, again

Registry publishes its handlers as a NuGet package. The gateway references it, at a specific version. When Registry releases, something bumps the reference in the gateway repository: a person, or a bot like Dependabot or Renovate. The pull request builds a new image, and the gateway's pipeline deploys it.

<!-- TODO: does the gateway team review and merge bumps, or does an automerge rule do it? -->
It's not as bad as it sounds. With automated bumps, Registry's release reaches production in the time it takes the gateway pipeline to run. The gateway team doesn't have to do anything unless the build or the tests fail.

### Loading assemblies at startup

Another option is for the gateway to load handlers at startup from a folder, instead of compiling them in. Each service publishes its handlers as an artifact, for example an OCI image with only the assemblies, and the gateway's pods mount them, for example with init containers.

ServiceComposer scans assemblies at startup, so it works. It also means that the gateway's tests never run against the handlers that go to production. A Registry release can break the gateway at startup, and the gateway team finds out from the pager.

<!-- TODO: do we want to recommend one of the two? My inclination: packages plus automated bumps. -->

## Who presses the deploy button?

In both hosts, the real question isn't technical. Who decides when a new version of Registry's components reaches production: Registry, or the team that owns the host?

The answer I like is: Registry decides that a version is ready, by releasing it, and the host decides when to take it, by merging the bump. Neither team waits for the other, as long as one rule holds:

> Hosts upgrade at different times, so every new version must work with the old version of everything around it.

Registry's components run in at least three places: its back end, the gateway, and the back office. They never upgrade at the same moment. For a while, the new panel talks to the old handlers, or the new handlers read from a database schema the old back end is still using. The contracts between the pieces of the same service are what make that work:

- **The composition contract:** the view model the handlers produce, and the panel reads.
- **The messages:** the commands the decomposition handlers send to the back end.
- **The database schema:** the composition handlers read Registry's database directly, as the Hotelly search does, so the schema is a contract too.

They're contracts between parts of the same service, owned by the same team. That makes them easier to change, not free to change. Expand first, then contract: add the new field, ship everything that writes and reads it, then remove the old one.

## Does the repository layout matter?

A bit. With one repository per service, Registry's panel, handlers, and back end live together, and the hosts consume packages. That's what the development view in the 4+1 article suggested.

With a monorepo, the gateway can reference Registry's handlers as projects, as Hotelly does. Every change to the handlers rebuilds the gateway, and the bump disappears. The coupling doesn't, though: a Registry change still deploys the gateway, and with it every other service's handlers. The monorepo makes that faster, not optional.

<!-- TODO: anything from Particular's own experience worth adding here? -->

## Conclusion

A service owns more than its back end. Its UI components and its composition and decomposition handlers are its code, even if they run in hosts other teams own. Getting them there is a development view decision, and each option trades release independence for safety in a different way:

- Packages are the most coupled, and the easiest to test.
- Micro frontends and assemblies loaded at startup ship independently, and move the contract to runtime.
- Server-side composition moves the UI problem into the gateway, where it becomes a back-end packaging problem.

Whatever we choose, the deploy button isn't the hard part. Backward-compatible contracts between the pieces of the same service are. With those, Registry releases when it's ready, the hosts pick the release up when they're ready, and nobody waits.

<!-- TODO: link the Hotelly back office scenario once it's in the demo. -->

---

<!-- TODO: header image and Unsplash credit. -->
