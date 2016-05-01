---
layout: post
title: "Deadlines: are they a good thing? The acting and directing metaphor."
author: Mauro Servienti
tags:
- Work
- management
- process
---

You might already know that for living I work in the software industry, it has been my primary job for the last 16 years or so.
You might not know that my secret dream is to be an artist.

I studied classical dance when I was young and I always enjoyed being on stage. When it comes to dancing, classical dance in particular, getting older doesn't really help, so in the last few years my hobby moved from pure dancing to acting, singing and dancing in an amateur acting company.

Our current show is a reworked, and simplified, version of the awesome `Mamma Mia`.

Why am I telling you all these things?

> Well, last week I was asking myself: **are deadlines a bad thing?**

We, the software industry, tend to say yes, deadlines and roadmaps are evil, we immediately connect them to waterfall and its evil nature. I started thinking and comparing the software production process to what we did to setup the show and to be honest I'm not anymore so sure that deadlines and roadmaps are evil.

Let me walk you through what does it mean to set up such a show.

From day zero to the first show it took us roughly 20 months, rehearsing for 2/3 times a week (3 to 4 hours each time), that means, if my math is correct, something like **700 hours**. A huge effort, trust me, especially given that it's your free time, it's time subtracted to families and friends. Be aware that I'm not complaining, just highlighting a fact.

## Inception

It all started with a small group of people (POs? Stakeholders?) that came together, in our case it was 6 of us, and picked an idea: `Mamma Mia`. We then started working to retrieve the plot and the script, the first iterations were us reworking the script to adapt it to our idea, capabilities and first budget draft.

Once the script draft, yes still a draft, was good enough we outlined the list of people required, the crew, and started the huge work to find them all.

### The crew

19 people on the stage, 19 people among which 8 main characters and the corps de ballet. But the crew is just a piece of the story, there are also 1 dj, 1 light specialist and 1 jack of all trades.

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

The venue IS the deadline, full stop. Scenography requirements drive the venue choice, so far so good, as with third-party suppliers you simply cannot approach a theater a couple of weeks before the show and ask if they have a couple of nights for you. Even if this was possible you need to advertise the show long enough to sell enough tickets to reach you breakeven point.

The above numbers mean that the first venue must be booked at least 10 months to one year in advance: **here is your deadline**.

That's your end goal, can you miss it? for no reasons at all. And, trust me, in one year a lot of things happen and change and people come and go.

## Development

Where we are? we have:

* a draft architecture driven by requirements (script and plot)
* a crew, or something like a draft crew
* non functional requirements and third-party engagement process in place
* a deadline: the first show at the first venue

How does it work in the long-term? It is an agile SCRUM-like approach, where everything is planned, worked, re-worked and adjusted to meet the first deadline with the best possible outcome.

### Interim builds and CI

During the week groups of people come together and work on their things, say a choreography, a scene or a scene change/transition, they really act like SCRUM teams or task forces working on stories, issues and bugs. On Sundays other than working as usual what we have so far of the show is played from beginning to end, it works really like a continuous integration process where on every rehearsal we run unit tests and on Sunday during the build process we run acceptance tests as well.

### Refactoring and improvements

Running a CI process, as in the software industry, is key to raise issues and concerns that lead to refactoring and improvements, a certain scene doesn't work, a ballet doesn't really fit the venue stage a scene change is too complex and prone to too many errors, must be changed, however changing that might require a change in the main plot to adapt it to the new requirements.

Can we refactor and improve as we like? not really since there is a deadline and requirements and improvements must meet the deadline as well. Perfection is an _utopia_, live with that. As in the software industry you'll release with bugs and a deadline helps you in that regards, in 2 main ways:

* commitment
* focus improvement and refactoring on important things first

Three other very interesting things happen:

1. In some ways Kanban kicks in: the show must be as fluent as possible, so everything must be optimized to maximize the lead time
* You know what? the above means W.I.P. limits during setup period and during live show as well
* Last but not least what happens behind the scenes, if seen by a stranger, will be perceived by a nightmare that comes true, people running all around while other people change their costumes right in the back-stage with other people moving scenographies right above their head in a very dangerous way, back-stages are a non functional requirements with which you must live with. 

### Beta and RC versions

While you progress there is the need to test that all you have so far works, how to? Beta releases, again driven by deadlines. When you book the theater you can arrange rehearsals that the venues as well, depending on what type of rehearsals you need sometimes these deadlines are flexible and can be decided later in the process, but again once defined are deadlines. Beta intermediate deadlines, say the ones without costumes and maybe not yet with the full scenography are important and are quite easy to met since the dependencies are that complex. RC versions on the contrary are much more important, need costumes and the full scenography, you need to test the entire flow in a safe environment, where you know you can stop the line and make changes and improvements on the fly. 

### RTM

As you might imagine RTM cannot be missed: tickets sold, venue booked and paid, third-parties are ready and paid. Missing the RTM deadline is a huge failure, a catastrophic one in case of a show. Deadlines in the software industry might be a bit more flexible, might. However in any case having a clear end goal both in terms of time and in terms of requirements, thanks to a roadmap (the plot and the design) clearly helps in being committed and focused.

## Conclusions

We started with a question:

> **are deadlines a bad thing?**

In my opinion the answer is no, they are not a bad thing. Roadmaps as well are a very good thing, sill, IMO.

In case of a show roadmaps, or call it a plan if you like, are clearly private and can be adjusted on the go as you like, deadlines are clearly public, the date of the show needs advertising in advance.

In the software industry this might not be the case: high level roadmaps can be public, they help in engaging with customers, IMO, and deadlines unless not connected to public events might be private to reduce exposure to failures.
