---
layout: post
title: "Deadlines: are they a good thing? The acting and directing metaphor."
author: Mauro Servienti
synopsis: "You might already know that for living I work in the software industry. It has been my primary job for the last 16 years or so. You might not know that my secret dream is to be an artist."
tags:
- management
- processes
---

You might already know that for living I work in the software industry. It has been my primary job for the last 16 years or so.
You might not know that my secret dream is to be an artist.

I studied classical dance when I was young and I always enjoyed being on stage. When it comes to dancing (classical dance in particular) getting older doesn't really help, so in the last few years my hobby moved from pure dancing to acting, singing and dancing in an amateur dramatics company.

Our current show is a reworked and simplified version of the awesome, `Mamma Mia`.

Why am I telling you all these things?

> Well, last week I was asking myself: **are deadlines a bad thing?**

We in the software industry tend to say yes, deadlines and road-maps are evil. We immediately connect them to waterfall and its evil nature. I started thinking and comparing the software production process to what we did to setup the show and to be honest, I'm not so sure anymore that deadlines and road-maps **are evil**.

Let me walk you through what it means to set up a show of this type.

From day one to the first performance took roughly 20 months, rehearsing 2/3 times a week (3 to 4 hours each time). That means, if my math is correct, approximately **700 hours**. A huge effort, trust me, especially given that it's your free time, it's time subtracted from families and friends. Be aware that I'm not complaining, just highlighting a fact.

## Inception

It all started with a small group of people (call them POs or Stakeholders if you wish) that came together, in our case it was 6 of us, and picked an idea: `Mamma Mia`. We then started working to retrieve the plot and the script, the first iterations were us reworking the script to adapt it to our idea, capabilities and first budget draft.

Once the script draft, yes still a draft, was good enough we outlined the list of required people, the crew, and started the huge work to find them all.

### The crew

19 people on the stage, 19 people among which 8 main characters and the *corps de ballet*. But the crew is just a piece of the story, there are also 1 dj, 1 light specialist and 1 jack of all trades.

Out of the 19 composing the main crew 3 of them are also managing all the choreography, 2 others all the logistic, 2 more all the legal stuff and finally 3 others take care of the direction, acting and singing, lights and music.

Is this in any way different from a large development team?

### Suppliers

It's not only the crew, we have suppliers as well. Scenographers and costumes makers. They are third-party suppliers that must be involved into the development process at specific stages and have their own schedules and stuff to manage.

Do development teams have external suppliers? Consultant for example. can development teams expect a third-party to be available on demand or the third-party schedule needs to be carefully planned?

Suppliers introduce an interesting aspect: they drive a portion (or the entire) release process. It's not because they are third-party external suppliers it's mainly because their work and the logistic around it takes a lot of time.  

### The logistic

Our scenography is amazing, especially given the amateur aspect. It is more than 10 meters large and 3 meters tall. It took a couple of months of work. When the scenography is that size you can't simply say tomorrow we'll be there, moving such a scenography requires a large truck and up to 6 people. The truck must be available as people must, thus the move must be carefully planned in advance.

Something similar happens with costumes, creating costumes took roughly 8 months.

The scenography introduces another couple of interesting aspects:

* stages have to be large enough to host it;
* theaters and back-stages have to be equipped and designed to let you move something like that

Large theaters are, however large theaters cost a lot, this means that picking up the venue is an important aspect. 

### The venue

The venue IS the deadline, full stop. Scenography requirements drive the venue choice, so far so good, as with third-party suppliers you simply cannot approach a theater a couple of weeks before the show and ask if they have a couple of nights for you. Even if this was possible you need to advertise the show long enough to sell enough tickets to reach you break-even point.

The above numbers mean that the first venue must be booked at least 10 months to one year in advance: **here is your deadline**.

That's your end goal, can you miss it? for no reasons at all. And, trust me, in one year a lot of things happen and change and people come and go.

## Development

Where are we? we have:

* a draft architecture driven by requirements (script and plot)
* a crew, or something like a draft crew
* non functional requirements and third-parties engagement process in place
* a deadline: the first show at the first venue

How does it work in the long-term? It is an agile SCRUM-like approach, where everything is planned, worked, re-worked and adjusted to meet the first deadline with the best possible outcome. Directors, choreographers and specialists act like SCRUM Masters and Stakeholders, we don't have anyone putting money on the table that can really be considered a stakeholder, we are self-founded.

### Interim builds and CI

During the week groups of people come together and work on their things, say a choreography, a scene or a scene change/transition, they really act like SCRUM teams or task forces working on stories, issues and bugs. On Sundays other than working as usual what we have so far of the show is played from beginning to end, it works really like a continuous integration process where on every rehearsal we run unit tests and on Sunday during the build process we run acceptance tests as well.

### Refactoring and improvements

Running a CI process, as in the software industry, is key to raise issues and concerns that lead to refactoring and improvements, a certain scene doesn't work, a ballet doesn't really fit the venue stage, a scene change is too complex and/or prone to too many errors and thus must be changed, however changing that might require a change in the main plot to adapt it to the new requirements.

Can we refactor and improve as we like? not really since there is a deadline and requirements and improvements must meet the deadline as well. Perfection is an _utopia_, live with that. As in the software industry you'll release with bugs and a deadline helps you in that regards, in 2 main ways:

* commitment
* focus improvement and refactoring on important things first

Three other very interesting things happen:

* In some ways Kanban kicks in: the show must be as fluent as possible, so everything must be optimized to maximize the lead time
* You know what? the above means W.I.P. limits during setup period and during live show as well
* Last but not least what happens behind the scenes, if seen by a stranger, will be perceived by a nightmare that comes true, people running all around while other people change their costumes right in the back-stage with other people moving scenographies right above their head in a very dangerous way, back-stages are a non functional requirements with which you must live with. 

### Beta and RC versions

While you progress there is the need to test that all you have so far works, how to? Beta releases, again driven by deadlines. When you book the theater you can arrange rehearsals at the venues as well, depending on what type of rehearsals you need sometimes these deadlines are flexible and can be decided later in the process, but again once defined are deadlines. Beta intermediate deadlines, say the ones without costumes and maybe not yet with the full scenography are important and are quite easy to met since the dependencies aren't that complex. RC versions on the contrary are much more important, need costumes and the full scenography, you need to test the entire flow in a safe environment, where you know you can stop the line and make changes and improvements on the fly.

### RTM

As you might imagine RTM cannot be missed: tickets sold, venue booked and paid, third-parties are ready and paid. Missing the RTM deadline is a huge failure, a catastrophic one in case of a show. Deadlines in the software industry might be a bit more flexible, might. However in any case having a clear end goal both in terms of time and in terms of requirements, thanks to a road-map (the plot and the design) clearly helps in being committed and focused.

### Major, Minor, bug fixing (AKA SemVer)

Bugs happen and can be fixed at each release, where a release is a new performance. Fixing bugs is again constrained by deadlines: you may find a bug on the Saturday night show and there is no way that it can be fixed in time for the Sunday night one, however you know you can fix it for next weekend.
Bugs are easy most of the time. Minor releases are much more complex, especially because with shows (and I don't think this applies to software) a Minor release might be valid for a couple of nights due to theater constraints, e.g. the stage has some unexpected constraints. The problem with minor releases and performing is that performing on a stage is the result of endless hours rehearsing, much like a Kata, and everything is so set in stone in your mind that is very complex to adapt to changes without advice and with very limited time.

Mostly due to the same Kata thing Major releases, so breaking changes, are simply a no go, it basically means something similar to start from scratch, we could say that we always must be backward compatible.   

## Conclusions

We started with a question:

> **are deadlines a bad thing?**

In my opinion the answer is no, they are not a bad thing. Road-maps as well are a very good thing, still, IMO. They can easily become a bad thing, for example when connected to a set in stone GANTT based release plan, and many more examples come to my mind.

In case of a show road-maps, or call it plans if you like, are clearly private and can be adjusted on the go as you like, deadlines are clearly public, the date of the show needs advertising in advance. In our case we set it 10 months before the first show but made it public when started advertising it 3 months before, we were confident enough to disclose it and publicly commit.

In the software industry this might not be the case: high level road-maps can be public, they may help in engaging with customers, IMO, and deadlines unless not connected to public events might be private reducing exposure to failures.

By the way, the simplified show version we're running lasts 2 hours and 15 minutes.
