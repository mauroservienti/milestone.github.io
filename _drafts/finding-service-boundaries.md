---
layout: post
title: "Back to Basics: how do we find service boundaries?"
author: Mauro Servienti
synopsis: "Everyone agrees that service boundaries matter. Fewer people explain how to find them. Let's walk through a few practical techniques, from modeling behaviors to anti-requirements, using a hotel booking system as an example."
header_image: /img/posts/finding-service-boundaries/header.jpg
tags:
- soa
- architecture
- back-to-basics
series: back-to-basics
---

I've written a lot about why service boundaries matter. In ["Back to Basics: service boundaries, autonomous components, and coupling"](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html), I described them as virtual fences that keep concepts belonging to different business concerns from melting into each other.

What I never did is explain how to find them.

It's a fair question, and the honest answer is that there is no algorithm. There are, however, techniques that help. None of them is enough on its own; together, they get us surprisingly far. Let's walk through them using an example.

## The example

A hotel chain wants a system to let guests book rooms online. After a couple of conversations with the business, we have a list of things the system deals with:

- Room name, description, and photos.
- Room type and maximum number of guests.
- Price per night, which changes with the season.
- Room availability for given dates.
- Guest name, email, and payment method.
- Reservation dates and status.
- Room cleaning status.

The natural reaction is to start drawing entities: `Room`, `Guest`, `Reservation`. Then services that match the entities: a Room service, a Guest service, a Reservation service. It feels right because it matches how people talk about hotels.

Let's not do that. Not yet, at least.

## Start from behaviors, not data

In ["Do not trust the user mental model"](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html), I argued that users describe data as still images: the state before and after something happens. The behavior that changes the data hides between the lines.

So, the first step is to collect behaviors. What does the system do? For example:

- Guests search for rooms available in a date range for a given number of guests.
- Guests book a room, and the system holds the amount on their payment method.
- Guests cancel a reservation, and the system applies a cancellation policy.
- Prices change based on the season.
- Housekeeping marks rooms as clean after a guest checks out.
- At check-in, guests get a room that's clean.

Behaviors tell us which pieces of data are used together. Searching for available rooms needs availability and the maximum number of guests. It doesn't need the description or the photos, even though users will see them on the search results page.

## Forget the names

Names like `Room` drag a lot of baggage with them. Everything that has something to do with a room ends up in the `Room` class.

A trick I like is to temporarily throw names away. Instead of entities, list the attributes, and group them by the behaviors that use them. If a group needs a name, use a color. Yellow, Green, Red. Colors carry no baggage, and they force us to look at what the group does rather than what it's called. Meaningful names can come back later, once the groups are stable.

## Anti-requirements

Here comes my favorite technique. Andreas Öhlund and David Boike described it in ["Using anti-requirements to find system boundaries"](https://particular.net/blog/antirequirements). The idea is to make up a fake requirement that ties two attributes together and present it to business stakeholders.

Let's try it with our hotel:

- "If a room description is longer than 500 words, the price per night goes up by 10%."
- "Rooms with more than five photos can't be booked on weekends."
- "If a guest changes their email address, the reservation dates move by one day."

If the business people laugh, and they will, the attributes probably have no logical relationship. Description and price can live in different services. So can photos and availability, or guest contact details and reservation dates.

Sometimes, they won't laugh. "If the room isn't clean, guests can't check in" isn't an anti-requirement at all: it's a real rule. Cleaning status and check-in are related. Interestingly, cleaning status and booking aren't. Nobody would refuse a reservation for next month because the room is dirty today. Anti-requirements are as valuable when they fail as when they succeed: a rule that isn't laughed at reveals a real relationship.

A word of caution. Some fake requirements sound absurd but turn out to be real. "The price goes up when there are only a few rooms left" sounds made up, but it's how many hotels work. Don't decide based on what we find absurd. Ask the business.

## What changes together stays together

The last technique is about consistency. For each behavior, ask which attributes must be consistent at the same time, in the same transaction.

When a guest books a room, availability must be updated in the same transaction as the reservation. Otherwise, two guests can book the same room for the same night. Availability and reservations change together, so they stay together.

When a guest books a room, does the payment authorization need to happen in the same transaction? It's tempting to say yes. However, if the payment authorization fails, the business can cancel the reservation and release the room. A few seconds of inconsistency are acceptable, as long as the process eventually reaches a consistent state. Payment and reservations can be in different services, coordinated through messages.

When the answer is "it must be consistent immediately," the attributes most likely belong to the same service. When the answer is "eventually is fine, as long as we know what to do if it fails," they can be separated.

## Putting it all together

Applying the techniques to the hotel example, we might end up with something like the following:

- **Content:** room name, description, photos, room type.
- **Pricing:** price per night, seasonal rules, cancellation policy.
- **Reservations:** availability, reservation dates and status, maximum number of guests.
- **Guests:** guest name and contact details.
- **Finance:** payment methods, authorizations, and charges.
- **Housekeeping:** cleaning status, and the check-in rule that depends on it.

Is it correct? I don't know. It's a starting point that will change as we learn more about the business. There's no product shaped `Room` anywhere, and the only thing all services share is the room identifier. As I wrote in ["How many (micro)services do I need?"](https://milestone.topics.it/2023/03/15/how-many-services.html), those are logical services. How many processes we deploy is a different question, to be answered later.

Then, to show a search result page, we compose the data from Content, Pricing, and Reservations. That's what [ViewModel Composition](https://milestone.topics.it/series/view-model-composition.html) is for.

## How do we know we're wrong?

We'll be wrong, at least a few times. A few signals that a boundary is in the wrong place:

- A single behavior requires synchronous calls to multiple services to make a decision.
- A change to a business rule requires changing more than one service.
- Two services need to be consistent immediately, and eventual consistency doesn't work for the business.
- A service is named after an entity, such as Room or Customer, and it keeps growing.

The good news is that, as long as boundaries are logical and we didn't distribute too early, moving them is cheap. It's a matter of moving code and data between modules, not between deployment units.

## Conclusion

There's no algorithm to find service boundaries. There are techniques: model behaviors instead of data, forget the names, test relationships with anti-requirements, and group what must change together. None of them gives the answer alone. Together, they make the conversation with the business much more productive.

And when someone laughs at a requirement, take it as good news ;-)

---

TODO: header image and credits
