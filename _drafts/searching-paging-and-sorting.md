---
layout: post
title: "Searching, paging, and sorting in a distributed system: the complete picture"
author: Mauro Servienti
synopsis: "Searching, filtering, sorting, and paging data owned by many services sounds like a recipe for coupling. It doesn't have to be. Let's put all the pieces together, with a runnable hotel search demo."
header_image: /img/posts/searching-paging-and-sorting/header.jpg
enable_mermaid: true
related:
- 2019-05-15-the-quest-for-better-search.md
- 2019-05-22-search-is-a-team-effort.md
- 2020-01-27-paging-and-sorting-in-distributed-systems-oh-my.md
- 2020-03-06-ok-mauro-but-i-want-to-do-paging-and-sorting.md
- 2019-03-21-the-viewmodels-lists-composition-dance.md
resources:
- "[Composing product lists with ServiceComposer](https://bloggingabout.net/2026/11/04/composing-product-lists-with-servicecomposer/), by Dennis van der Stelt"
tags:
- soa
- search
- viewmodel-composition
- distributed-systems
---

<!-- TODO: opening hook. "The Quest for better Search" (2019) promised "at least two more articles", one with an implementation using the hotel reservations scenario. One came out, the implementation never did. Famous last words. This is the one, seven years later, and it comes with a runnable demo. -->

<!-- TODO: thesis in one or two sentences: searching, filtering, sorting, and paging across services can't be composed after the fact; they need the data in one place. That place can still respect service boundaries: each service owns its own lean data and its own piece of the query. -->

## What are we building?

<!-- TODO: the requirements, from "Search is a Team Effort":
- search hotels by city
- optional check-in and check-out dates, to filter out sold-out hotels
- filter by stars, amenities, and guest rating
- facets with counts for stars, amenities, and rating bands
- sort by price, rating, or stars, and combinations like "price, then rating"
- nightly rates vary by season, so the price to sort by is the total for the requested stay
- page the results
-->

<!-- TODO: the decomposition:
- Registry: name, description, city, stars, amenities
- Reservations: availability
- Marketing: guest ratings and reviews
- Sales: seasonal nightly rates. New compared to the 2019 posts, needed for sorting by price.
-->

## Why can't we compose it?

<!-- TODO: short recap with links:
- ViewModel Composition works for a page of known IDs ("The ViewModels Lists Composition Dance").
- Paging alone works: the owner of the list pages it ("Paging and sorting in distributed systems, oh my!").
- Sorting by data owned by another service, and then paging, falls apart: sort first, then page, and that's a join ("OK Mauro, but I want to do paging AND sorting").
- Search adds filters owned by different services, plus facets. Moving IDs from service to service is the naive design from "Search is a Team Effort": the race car moving to the engineers.
-->

## One store, many owners

<!-- TODO: the shared PostgreSQL database:
- one schema per service (registry, reservations, marketing, sales), each with its own tables, keyed by hotel ID
- Sales stores its seasonal rates as date ranges with a nightly price, like Reservations stores availability
- each service writes only to its own schema; database roles enforce it
- only the data needed to search, filter, sort, and build facets: nothing more, nothing less (the pit stop)
- each service keeps it up to date from its own data, e.g. handling its own events
- eventual consistency: fine for Registry, critical for Reservations; keep the availability data lean
-->

<!-- TODO: Mermaid diagram: services writing to their own schemas in the shared database; the search component reading from all of them. -->

## Search is (still) a team effort

<!-- TODO: the search process, in code from the demo. The 2019 pseudo-code becomes real: services deploy search providers that add their pieces to a shared EF Core IQueryable. Who owns the search process? Nobody: like the composition engine, it's infrastructure that hosts the services' components. -->

### Filtering

<!-- TODO: each provider handles the criteria it owns: Registry the city, stars, and amenities; Reservations the dates, as a daterange overlap; Marketing the minimum rating. -->

### Facets

<!-- TODO: each service computes the facets it owns on the filtered set: stars and amenities from Registry, rating bands from Marketing. -->

### Sorting, then paging

<!-- TODO: sort providers for the fields each service owns; the order comes from the request (orderBy=price,rating) and becomes OrderBy/ThenBy across services. Paging happens last, in the database. Offset vs keyset paging, briefly. -->

<!-- TODO: sorting by price with seasonal rates: the price depends on the requested dates (a stay from Dec 28 to Jan 2 spans two seasons), so there's no single value to precompute and sort by. The Sales sort provider sums the nightly rates for the requested stay within the same query. This is why sorting must happen where the data is, and Sales still owns its pricing rules. -->

### What about dynamic pricing?

<!-- TODO: if the price is computed at request time by a pricing engine (occupancy, demand, who's asking), there's nothing stored to sort by, and computing it for every candidate on every search doesn't scale. Options:
- sort by an indicative "from" price that Sales refreshes in its table, and show the real price in the composed page ("prices may change"); the cost is that sort order and displayed price can diverge
- Sales recomputes and republishes prices on a schedule or on occupancy changes: more eventual consistency, owned by Sales
- compute the real price only for the visible page, when sorting isn't by price
Not in the demo. -->

## From IDs to a results page

<!-- TODO: the search returns a page of hotel IDs, the facets, and the total count. ViewModel Composition, with ServiceComposer, turns the IDs into the results page: each service adds its own data to each item (name and photo, price, rating). That's the process Mike described on Slack: index, query, order, page, compose. -->

<!-- TODO: compare with Dennis's approach in "Composing product lists with ServiceComposer": no shared store, Catalog raises an event with the candidate IDs and Marketing returns them sorted. When is that enough, and when does it stop scaling (it loads all candidate IDs)? -->

## What about Elasticsearch?

<!-- TODO: the comparison:
- Elasticsearch wins at relevance-ranked full-text search, fuzzy matching, geo queries, and many facets at scale (aggregations).
- No joins: services share one document per hotel, each owning a section of it, and share the index mapping; or they're back to moving IDs around.
- Cross-service sorting needs all fields in the same document.
- Availability by date is awkward (date_range or nested documents).
- Near real-time indexing adds to eventual consistency.
- Weaker ownership enforcement than per-schema database roles.
- PostgreSQL: joins, per-schema ownership, daterange, plain SQL facets; weaker text relevance and costlier facets at scale.
- So: what you're searching for decides the store. "You are Google, you are not Google."
-->

## Conclusion

<!-- TODO: zero coupling is an illusion. Searching, sorting, and paging across services need a place where the data meets; that place can still respect boundaries if each service owns its own data and its own piece of the query, and shares nothing more than needed. Link to the demo repository. -->

<!-- TODO: demo repository: name, location, and link. PostgreSQL in Docker, ServiceComposer, hotel domain. -->

---

<!-- TODO: header image credit -->
