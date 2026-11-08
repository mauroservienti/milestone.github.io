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
- 2026-12-16-finding-service-boundaries.md
- 2021-07-15-own-the-cache.md
resources:
- "[Composing product lists with ServiceComposer](https://bloggingabout.net/2026/11/04/composing-product-lists-with-servicecomposer/), by Dennis van der Stelt"
tags:
- soa
- search
- viewmodel-composition
- distributed-systems
---

In May 2019, [Tomek](https://twitter.com/Masternak) and I wrote ["The Quest for better Search"](https://milestone.topics.it/2019/05/15/the-quest-for-better-search.html), and closed it with a promise: "There will be at least two more articles, one discussing the architecture of a distributed search, and another one showing a possible implementation using the Hotel Reservations scenario."

The first one came out a week later. The second one? Famous last words.

Seven years later, here it is. It ties together searching, filtering, sorting, and paging, and it comes with a runnable demo.

<!-- TODO: link to the demo repository once it exists. -->

The short version: searching, sorting, and paging across services can't be composed after the fact. The data needs to meet in one place. That place can still respect service boundaries, as long as each service owns its own data and its own piece of the query, and shares nothing more than needed.

## What are we building?

Let's go back to the hotel reservations scenario from ["Search is a Team Effort"](https://milestone.topics.it/2019/05/22/search-is-a-team-effort.html). Users want to:

- search hotels in a city;
- optionally, pick check-in and check-out dates, to filter out sold-out hotels;
- filter results by stars, amenities, and guest rating;
- see facets, with counts, for stars, amenities, and rating;
- sort by price, rating, or stars, or by combinations like "price, then rating";
- page through the results.

There's a twist compared to 2019: nightly rates vary by season. The price users want to sort by isn't the nightly rate. It's the total for the stay they asked for.

We won't get into how to find service boundaries here; I covered some techniques, with a hotel example too, in ["Back to Basics: how do we find service boundaries?"](https://milestone.topics.it/2026/12/16/finding-service-boundaries.html). Let's assume the following decomposition:

- **Registry** owns the hotel: name, description, city, stars, and amenities. Registry decides what a hotel is and whether it exists.
- **Reservations** owns availability.
- **Marketing** owns guest reviews and ratings.
- **Sales** owns the seasonal nightly rates.

## Why can't we compose it?

If you've been following the [ViewModel Composition series](https://milestone.topics.it/series/view-model-composition.html), the first instinct is to compose the results page. It works for a page of known items, as described in ["The ViewModels Lists Composition Dance"](https://milestone.topics.it/2019/03/21/the-viewmodels-lists-composition-dance.html): one service loads the IDs, the others add their data.

Paging alone is fine too. The service that owns the list pages it, and everyone else gets an already-paged list of IDs. I described it in ["Paging and sorting in distributed systems, oh my!"](https://milestone.topics.it/2020/01/27/paging-and-sorting-in-distributed-systems-oh-my.html).

Things fall apart as soon as we sort by something owned by another service and then page. Sorting must happen before paging. If we page first, we sort only the current page, and page two makes no sense anymore. And to sort by price before paging, Sales needs all the candidates, not a page of them. That's a join, as I admitted in ["OK Mauro, but I want to do paging AND sorting"](https://milestone.topics.it/2020/03/06/ok-mauro-but-i-want-to-do-paging-and-sorting.html).

Search makes it worse. Filters are owned by different services, and facets need counts over the whole result set, not over a page. Moving IDs from Registry to Reservations to Marketing to Sales, filtering at every step, is the naïve design from "Search is a Team Effort". It works, and it's very inefficient. It's like moving the race car to the engineers during a pit stop, instead of bringing the engineers, and only the tools they need, to the car.

So, let's bring the engineers to the car.

## One store, many owners

The demo uses a single PostgreSQL database dedicated to search. Each service gets its own schema and writes only to it:

- `registry.hotels`: hotel ID, city, stars, and amenities.
- `reservations.sold_out_nights`: hotel ID and night, one row for each night a hotel has no rooms left.
- `marketing.ratings`: hotel ID, average rating, and number of reviews.
- `sales.nightly_rates`: hotel ID, night, and rate.

> PostgreSQL range types would let Reservations and Sales store periods instead of single nights. One row per night keeps the demo, and the queries, simpler.

Each service has a database role that can write only to its own schema. Ownership isn't a convention; the database enforces it.

<div class="mermaid">
flowchart LR
  R[Registry] --> RS[(registry schema)]
  RE[Reservations] --> RES[(reservations schema)]
  M[Marketing] --> MS[(marketing schema)]
  S[Sales] --> SS[(sales schema)]
  subgraph Search database
    RS
    RES
    MS
    SS
  end
  SE[Search] -. reads .-> RS
  SE -. reads .-> RES
  SE -. reads .-> MS
  SE -. reads .-> SS
</div>

The tables contain only what's needed to search, filter, sort, and build facets. Nothing more, nothing less. The hotel description, the photos, and the reviews' text aren't there: they're needed to display results, not to find them, and composition takes care of displaying.

Each service keeps its tables up to date from its own data. That introduces eventual consistency. Registry doesn't care much: hotels don't change city or stars every five minutes. Reservations cares a lot: a hotel that sold out a minute ago shouldn't show up as available. That's why its table is as lean as possible: the nights with no rooms left, and nothing else.

### Keeping the tables up to date

The tempting answer is messaging: each service publishes an event when something changes, and a handler updates the search table. It works, but it's the wrong tool. Filling the search tables isn't communication between services. It's data synchronization within a service's boundary: the Sales search table is Sales data, stored somewhere else.

And messaging brings ordering to the table. Say Sales changes the rate for a night twice in a minute. Messages can be retried, delivered out of order, or processed in parallel, so the second change can land before the first, and the old rate wins. To fix it, we need a version on every row and handlers that discard stale updates. At that point, we're building a replication mechanism, badly, on top of a messaging infrastructure.

Databases are good at replication, and there are ways to sync data that don't make ordering our problem:

- **Change data capture:** the service's own database streams its changes, in commit order, to the search schema. If the service uses PostgreSQL, logical replication does it out of the box. Otherwise, tools like Debezium do.
- **Reading the current state:** when something changes, the sync process reads the current state from the service's database and overwrites the search rows. A notification can still trigger it, but it carries only the hotel ID. Nobody trusts its content, so the order notifications arrive in doesn't matter.
- **Periodic rebuilds:** the search tables are a copy, so they can be thrown away and rebuilt from scratch. It's too slow for Reservations, but it's a good safety net, and good enough for Registry.

Whatever the option, the sync is part of the service: the same team owns it, deploys it, and monitors it.

The demo uses logical replication. Each service has its own PostgreSQL server, and publishes only the columns search needs. Registry, for example:

```sql
CREATE PUBLICATION registry_search
    FOR TABLE registry.hotels (id, city, stars, amenities);
```

The hotel name and description stay in Registry. In the search database, Registry then subscribes its schema to that publication:

```sql
CREATE SUBSCRIPTION registry_search
    CONNECTION 'host=registry-db dbname=registry ...'
    PUBLICATION registry_search;
```

That's all the sync code there is. The subscription copies the existing rows first, then streams every change as it's committed. Logical replication matches tables by schema-qualified name, which is why Registry's own table lives in a `registry` schema too.

A publication can filter rows too. Search doesn't need to know how many rooms are left; it needs to know which nights are sold out. Reservations publishes only those:

```sql
CREATE PUBLICATION reservations_search
    FOR TABLE reservations.availability WHERE (booked >= rooms);
```

When a booking sells out a night, the row shows up in search. When a cancellation frees a room, it disappears.

What a publication can't do is reshape data. It picks tables, columns, and rows, but it doesn't aggregate, join, or compute anything. Take ratings: search sorts by the average rating, and Marketing stores reviews. The demo replicates one row per review, without the comments, and search computes the averages at query time. It's simple, but every query pays for it. The alternative is for Marketing to keep a per-hotel summary in its own database, updated in the same transaction as the review, and to publish that instead. Queries get cheaper, and sync code is back, but it lives in the service, in a local transaction: no messaging, no ordering problems. Either way, the shape of the search tables is the service's decision, like the queries that read them.

Interestingly, the order is the opposite of messaging. With messaging, the subscriber must subscribe before events are published: an event delivered while nobody's listening is gone. With replication, the publication must exist first. Subscribing late loses nothing, since the subscription starts with a copy of the current state. What the subscriber can't do without is the contract: the publication declares which tables and columns are available, and the subscription reads it when it's created. Messaging moves events; replication moves state. For search tables, state is what we need.

Let's be honest, though. The search database is a copy of data that lives somewhere else. That's a cache, and it comes with all the problems caches have: stale data, invalidation, and rebuilding it when it's lost. It's worse than that: it's a distributed cache. It lives outside the physical service, in a different database, maybe on a different server, and every service writes to it. A copy that falls behind, a sync that fails silently, or a database that's down affects search for everyone, not only the service that caused it.

What makes it manageable is the same thing that makes any cache manageable: ownership. I wrote about it in ["Own the cache!"](https://milestone.topics.it/2021/07/15/own-the-cache.html). Each service owns its schema, decides how fresh its data must be, and can wipe and rebuild its tables without asking anyone. Registry can rebuild nightly, and Reservations can't afford to be more than seconds behind. Nobody else is affected by those choices. The only thing services share is the infrastructure: the database server, its capacity, and its uptime.

What happens when the network between a service and the search database is flaky? With logical replication, not much. The subscriber reconnects on its own, and the publisher keeps every change the subscriber hasn't confirmed yet. Nothing is lost, nothing is applied twice, and changes still arrive in commit order. Search serves stale data for a while, and that's it.

The catch is on the other side. While the search database is unreachable, each service's database keeps all the changes search hasn't received yet. If the outage lasts long enough, they fill the disk: the cache being down hurts the source of truth. That's why each service sets a limit, `max_slot_wal_keep_size` in PostgreSQL, beyond which it stops waiting. Search then needs a full resync of that service's tables, the rebuild from scratch we already discussed. Once more, the decision stays with the service that owns the data: how much it's willing to keep before giving up.

Notice how the problem changed along the way. We started with an architectural problem: who owns what, and how data gets where it's needed. We ended up with a platform engineering problem: keeping servers, and the network between them, up. Uptime isn't something architecture can solve. Architecture can alleviate the effects of an outage, often trading them for other downsides, like the resync above. And it can decide what an outage means: when the search database is down, search degrades, and booking a hotel still works. Keeping things up, though, is someone else's job.

## Search is (still) a team effort

Data isn't enough. Services need to take part in the search process. In 2019, we used pseudo-code with search providers appending statements to an `IQueryable`. That's what the demo does, using EF Core.

<!-- TODO: replace the snippets in this section with the code from the demo, once it exists. -->

The search process starts from the list of hotels, owned by Registry, and asks each service to contribute. Services deploy providers, and the search process discovers them, the same way ServiceComposer discovers composition handlers. There are three kinds of providers: filters, facets, and sorters.

### Filtering

A filter provider looks like the following:

```csharp
public interface IFilterProvider
{
    IQueryable<Hotel> Filter(IQueryable<Hotel> hotels, SearchRequest request);
}
```

Each service handles the criteria it owns. Registry filters by city, stars, and amenities. Reservations, when the request has stay dates, removes sold-out hotels:

```csharp
class AvailabilityFilter(SearchDbContext db) : IFilterProvider
{
    public IQueryable<Hotel> Filter(IQueryable<Hotel> hotels, SearchRequest request)
    {
        if (request.Stay is not { } stay)
        {
            return hotels;
        }

        return hotels.Where(h => !db.SoldOutNights.Any(n =>
            n.HotelId == h.Id && n.Night >= stay.CheckIn && n.Night < stay.CheckOut));
    }
}
```

Reservations doesn't know what Registry filtered, and doesn't care. It adds its condition, and EF Core turns the whole thing into a single SQL query.

### Facets

Facets work the same way. Each service builds the facets for the data it owns, using the filtered set of hotels:

```csharp
public interface IFacetProvider
{
    Task<Facet> Build(IQueryable<Hotel> filtered, SearchRequest request);
}
```

Registry counts stars and amenities, and Marketing groups ratings into bands like "8+" or "9+". Each is a `GROUP BY` on the service's own table, joined with the filtered hotels.

> A detail that makes users happy: facet counts usually ignore the facet's own filter. If users select four stars, the stars facet still shows how many three- and five-star hotels match, so they can change their minds. To do that, the search process builds each facet on the hotels filtered by all the other providers.

<!-- TODO: check that the demo does this; if not, drop the note or adjust the IFacetProvider signature. -->

### Sorting, then paging

Sorting is where the 2020 posts got stuck. A sort provider looks like the following:

```csharp
public interface ISortProvider
{
    string Key { get; }

    IOrderedQueryable<Hotel> Sort(
        IQueryable<Hotel> hotels, SearchRequest request, bool descending, bool first);
}
```

`Key` is the value in the request's `orderBy` parameter that the provider handles: `price` for Sales, `rating` for Marketing, `stars` for Registry. The `first` argument tells the provider whether it's the primary sort, `OrderBy`, or a secondary one, `ThenBy`. That's how a request like `orderBy=price,rating` turns into "sort by price, then by rating", with each part owned by a different service.

Seasonal prices make Sales' sorter interesting. A stay from December 28 to January 2 might span two seasons, so there's no single price to precompute and store. The price to sort by is the sum of the nightly rates for the requested nights:

```csharp
class StayPriceSort(SearchDbContext db) : ISortProvider
{
    public string Key => "price";

    public IOrderedQueryable<Hotel> Sort(
        IQueryable<Hotel> hotels, SearchRequest request, bool descending, bool first)
    {
        var stay = request.Stay!.Value;
        Expression<Func<Hotel, decimal>> stayPrice = h => db.NightlyRates
            .Where(r => r.HotelId == h.Id && r.Night >= stay.CheckIn && r.Night < stay.CheckOut)
            .Sum(r => r.Rate);

        return (first, descending) switch
        {
            (true, false) => hotels.OrderBy(stayPrice),
            (true, true) => hotels.OrderByDescending(stayPrice),
            (false, false) => ((IOrderedQueryable<Hotel>)hotels).ThenBy(stayPrice),
            (false, true) => ((IOrderedQueryable<Hotel>)hotels).ThenByDescending(stayPrice),
        };
    }
}
```

<!-- TODO: sorting by price without stay dates: lowest upcoming nightly rate? Not allowed? Decide in the demo. -->

This is why sorting must happen where the data is. Sales still owns its pricing rules: how seasons work, and how a stay's price is calculated. The rule just runs inside the query, next to everyone else's.

Paging comes last, once everything is filtered and sorted. The search process adds a final sort on the hotel ID, so hotels with the same price and rating always come back in the same order, and two pages never show the same hotel. Then it skips and takes. The demo uses offset paging. For deep result sets, keyset paging, "the next ten after this one", is more efficient, but users rarely go past page three of a hotel search.

The whole search process looks like the following:

```csharp
var hotels = db.Hotels.AsQueryable();
foreach (var filter in filterProviders)
{
    hotels = filter.Filter(hotels, request);
}

var facets = new List<Facet>();
foreach (var facetProvider in facetProviders)
{
    facets.Add(await facetProvider.Build(hotels, request));
}

var total = await hotels.CountAsync();

IOrderedQueryable<Hotel>? sorted = null;
foreach (var (key, descending) in request.OrderBy)
{
    sorted = sortProviders[key].Sort(sorted ?? hotels, request, descending, first: sorted is null);
}

var pageIds = await (sorted?.ThenBy(h => h.Id) ?? hotels.OrderBy(h => h.Id))
    .Skip(request.Page * request.PageSize)
    .Take(request.PageSize)
    .Select(h => h.Id)
    .ToListAsync();
```

The search process knows nothing about cities, prices, or ratings. It runs whatever services contributed, in the order the request asked for.

### What about dynamic pricing?

Seasonal prices are known in advance. Dynamic prices aren't: a pricing engine calculates them at request time, based on occupancy, demand, or even who's asking. There's nothing stored to sort by, and calculating the price of every candidate hotel on every search doesn't scale.

There are a few options, each with a cost:

- **Sort by an indicative price.** Sales regularly refreshes a "from" price in its table, and the results page shows the real one. That's what booking sites do, and why they say "prices may change". The cost: the sort order and the displayed price can disagree.
- **Recalculate often.** Sales recalculates and stores prices on a schedule, or when occupancy changes. More eventual consistency, but it stays inside Sales.
- **Calculate only what's visible.** When users sort by something else, the real price is needed only for the page they see, and composition can ask Sales for it.

The demo sticks to seasonal prices.

## Isn't search just another Branding service?

In ["The price of freedom"](https://milestone.topics.it/2019/06/13/the-price-of-freedom.html), I described Branding as a service "defining contracts that other services needs to implement and respect if they want their data displayed on a UI they don't own." Doesn't search do the same?

Yes and no.

Yes, the search process imposes a contract on every service that wants to take part:

- the extension points: filter, facet, and sort providers, and when they run;
- the shape of requests and results: city, stay dates, `orderBy` keys, and facet names in; a page of IDs, facet counts, and a total out;
- some shared assumptions: the hotel ID is the join key, everyone contributes to the same query, and some parameters, like the stay dates, are used by more than one service.

And it comes with the same cost as Branding. Changing the contract affects every provider. Adding a filter means changing the search page and the service that owns the data.

No, because the contract doesn't include a data schema. Each service keeps its own tables and its own query logic; the contract says where to plug in, not what the data looks like. It doesn't include business rules either. As we said in "The Quest for better Search", if searching isn't a business capability, it isn't a service. The search process is infrastructure, like the composition engine. The vocabulary of the search, which criteria and which facets exist, belongs to whoever owns the search page, the same way Marketing owns the email model in ["Composing emails: one service owns the template, many own the data"](https://milestone.topics.it/2026/12/02/composing-email-templates.html).

The lesson is the same as with Branding: keep the contract small and technical.

## From IDs to a results page

The search returns a page of hotel IDs, the facets, and the total count. That's not a results page yet. Users want names, photos, prices, and ratings.

That's a job for [ViewModel Composition](https://milestone.topics.it/series/view-model-composition.html). In the demo, the search runs in the composition gateway, as part of the request for the results page, using ServiceComposer. Once the page of IDs is ready, a composition event notifies all services, and each one adds its own data to each item: Registry the name and the photo, Sales the price for the stay, Marketing the rating. It's the [lists composition dance](https://milestone.topics.it/2019/03/21/the-viewmodels-lists-composition-dance.html) all over again, with search in the role of the list owner.

<!-- TODO: snippet of the composition event and one handler from the demo. -->

Years ago, a friend and colleague named Mike described on Slack an engine he'd built along the same lines: services index the data they care about, answer the query with matching IDs, order the results, and then the page is paginated and fleshed out with ViewModel Composition. Different implementation, same steps.

> Dennis van der Stelt recently described a different approach in ["Composing product lists with ServiceComposer"](https://bloggingabout.net/2026/11/04/composing-product-lists-with-servicecomposer/). There's no shared store: Catalog raises an event with all the candidate IDs, and Marketing returns them sorted. It's simpler, and it's enough when one service sorts and candidate lists are small. It stops scaling when the candidates are many, or when sorting needs data from more than one service.

## What about Elasticsearch?

When Tomek and I talked about building a demo, Elasticsearch was his first idea. It's a great search engine, and it beats PostgreSQL at many things:

- relevance-ranked full-text search, fuzzy matching, and typo tolerance;
- geographic queries, like "within 5 km of the city center";
- facets: aggregations return all the counts in the same request as the results, and they scale to many facets and large data sets.

It has a problem with our design, though: it has no joins. There are a few ways around it:

- **One document per hotel**, with a section for each service. Each service updates only its own section, but they all share one index mapping, and a reindex affects everyone.
- **One index per service**, joined in code. That's moving IDs around again: the naïve design.
- **Parent/child relationships**, which are limited, slower, and still need a single index.

Sorting by price, then by rating, needs both fields in the same document. So we're back to the shared document. Availability is awkward to model, too: booked dates become date ranges or nested documents, and they're the data that changes the most. Elasticsearch also refreshes its indexes about once a second, which adds a little more eventual consistency. And anyone who can write to the index can write any field: there's no equivalent of a database role per schema.

That shared document has a familiar shape. The index mapping becomes a data contract all services depend on, much closer to the Branding coupling than the PostgreSQL design, where only the plug-in contract is shared.

PostgreSQL has its limits too. Its full-text search is basic compared to Elasticsearch, and many facets over large data sets get expensive.

So which one? It depends on what you're searching for. If users search free text and expect relevance, typo tolerance, and maps, and that's at the core of your business, it might be worth the coupling. Remember the 2019 mantra: "You are Google, you are not Google." A hotel booking site searching by city, dates, stars, and price isn't Google. PostgreSQL, with joins and a schema per service, keeps boundaries clearer.

## Conclusion

Zero coupling is an illusion. Searching, sorting, and paging data owned by many services needs a place where that data meets, and pretending otherwise leads to chatty, slow systems.

That place doesn't have to be a hodgepodge, though. If each service owns its own lean data, its own piece of the query, and its own facets and sorting rules, the only thing shared is a small, technical contract. Composition does the rest.

The demo has all the pieces: PostgreSQL in Docker, ServiceComposer, and the hotels we've been talking about since 2019. Better late than never ;-)

<!-- TODO: demo repository link and how to run it. -->

---

<!-- TODO: header image credit -->
