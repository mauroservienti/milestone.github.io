---
layout: post
title: "Should the HTTP endpoint do the work? Heyi: atomic web endpoints for NServiceBus"
author: Mauro Servienti
synopsis: "A web request stores an order and publishes an event. Doing both atomically takes a handful of plumbing lines in every endpoint. I built a small library to make them disappear, and along the way asked whether the endpoint should do the work at all."
header_image: /img/posts/heyi/header.jpg
related:
- 2026-10-21-zusammen.md
- 2023-02-07-outbox-what-and-why.md
- 2023-06-27-reject-commands.md
- 2026-11-26-idempotency-deep-dive.md
- 2027-02-10-reserve-or-apologize.md
tags:
- nservicebus
- messaging
- distributed-systems
---

In ["I built a Node.js library over a weekend. I don't know Node.js"](https://milestone.topics.it/2026/10/21/zusammen.html), I brought the NServiceBus transactional session to a platform I can barely spell. That was round two. For round three, I went back home: .NET, a platform I know a little better. I hope.

This time, the transactional session was already there. What I wanted was the layer on top of it.

The transactional session does exactly what it promises: data and messages are committed together, or not at all. Using it from an ASP.NET Core endpoint, though, is a bit chatty. Open the session with the persistence-specific options. Send and publish through it. Make sure the database work shares its connection and transaction. Commit, but only if things went well, and before the response goes out. Dispose of it either way.

> Full disclosure: I work at Particular Software, so I'm allowed to tease our own APIs. Gently ;-)

None of it is hard. It's the same few lines in every endpoint that stores data and sends messages. And code copied everywhere eventually gets copied wrong somewhere: a commit after the response is written, a commit on a `400`, a `DbContext` that quietly opens its own connection.

So, I built a library to make those lines disappear. And along the way, I ended up asking a different question: should the endpoint do the work at all?

<!-- TODO: round two was about building with an AI coding agent. Decide whether round three mentions it too (one line, "AI coding agent", no product names), or keeps the focus on the design. -->

<!-- TODO: TL;DR? The Zusammen post had one. Something like: "I built Heyi (合一, "to become one"). It turns ASP.NET Core endpoints into handler-shaped endpoints: store data and send messages as one atomic operation, on top of the NServiceBus transactional session." -->

## The plumbing we write today

<!-- TODO: show the transactional session as used in an ASP.NET Core endpoint today, without Heyi: open with the persistence-specific options, use the session to send and to get the storage session, save, commit, dispose. Keep it short and fair: it works, and the Particular sample does it with an MVC filter. The problem is that it's ceremony, repeated, and easy to get subtly wrong. -->

What can go wrong in those few lines? Let's see:

<!-- TODO: the subtle mistakes, one line each:
- committing after the response is written: the client gets a 201 for an order that was never stored;
- committing on a 400 or a 409: the validation failed, but the messages went out anyway;
- the DbContext using its own connection instead of the session's: two transactions, no atomicity;
- forgetting to dispose on exceptions.
Link to "What's an Outbox and why do we need it?" (https://milestone.topics.it/2023/02/07/outbox-what-and-why.html) for why the outbox is needed in the first place, without repeating it. -->

## What if the endpoint looked like a handler?

<!-- TODO: the idea behind Heyi. A message handler never opens or commits anything: the infrastructure does it around the handler. Why not the same for HTTP endpoints? Introduce the name: Heyi, 合一, héyī, "to become one": data and messages become one operation. -->

The following is what an endpoint looks like with Heyi:

```csharp
app.MapPost("/orders", (PlaceOrder request, OrdersDbContext db, IOutgoingMessages messages) =>
{
    var order = Order.From(request);
    db.Orders.Add(order);
    messages.Publish(new OrderPlaced(order.Id));
    return Results.Created($"/orders/{order.Id}", order);
})
.WithTransactionalSession();
```

<!-- TODO: walk through the rules, as a list:
- the filter opens the session before the endpoint runs;
- it commits after the endpoint returns and before the response is written; a failed commit becomes a 500, never a success;
- only 2xx commits; exceptions and 4xx/5xx dispose the session, which rolls back data and messages;
- IOutgoingMessages is a facade over the open session; the endpoint never opens, commits, or disposes anything.
Then the setup: NServiceBus first, Heyi second (AddNServiceBusEndpoint, then AddHeyi and AddHeyiDbContext), and the startup checks that fail fast. -->

> Heyi doesn't add guarantees. The [NServiceBus transactional session](https://docs.particular.net/nservicebus/transactional-session/) and the outbox do the heavy lifting; Heyi adds the programming model.

<!-- TODO: design decisions worth telling, pick two or three:
- why commit before the response is written (and what it costs);
- why status codes decide, not exceptions only;
- sharing the connection and transaction with EF Core;
- send-only web apps and the remote processor endpoint. -->

## Should the endpoint do the work at all?

<!-- TODO: the ADSD angle, the heart of the post. The atomic endpoint still runs business logic inside an HTTP request: validation, rules, storage. What if it didn't? The edge accepts the command, returns 202 Accepted, and a regular message handler does the work, with retries, the outbox, and everything messaging gives us. Link to "What if my command was rejected?" (https://milestone.topics.it/2023/06/27/reject-commands.html): commands that are validated upfront rarely need to fail. And to "Reserve, or apologize?" (https://milestone.topics.it/2027/02/10/reserve-or-apologize.html) for when accepting first is the business's choice. -->

That's what accept-only endpoints are for:

```csharp
app.MapCommand<PlaceOrder>("/orders");           // Send, 202 Accepted
app.MapEvent<OrderRequested>("/order-requests"); // Publish, 202 Accepted
```

<!-- TODO: no database, no transactional session needed, routing comes from the NServiceBus configuration. Optional location to poll. Then the nuance: when the atomic endpoint is the right call (the client needs the result now, the UI can't cope with eventual consistency), and when accept-only is the better default. No silver bullet. -->

## What about retries?

<!-- TODO: idempotency at the edge. Clients retry, proxies retry, users double-click. The Idempotency-Key header (IETF draft: https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/) becomes the outgoing message IDs ({key}/{index}), so a retried request produces messages with the same identity and receivers can deduplicate them. Be honest about the limit: the transactional session doesn't deduplicate incoming requests, so a retried atomic request runs again and the database must reject the duplicate. Link to "Idempotent, you must be" (https://milestone.topics.it/2026/11/26/idempotency-deep-dive.html). Storing and replaying responses is a later step. -->

<!-- TODO: retries come in layers, and NServiceBus.Extensions.DispatchRetries (https://github.com/mauroservienti/NServiceBus.Extensions.DispatchRetries) is the server-side one. Its README opens with this exact scenario: an HTTP request turned into a message, a flaky connection to the broker, a 500 to the caller.
- Accept-only endpoints: a direct fit. MapCommand and MapEvent send through IMessageSession, outside a handler, so the dispatch goes through the outgoing pipeline and DispatchRetries retries it with a Polly policy (the batch policy, in this case) before giving up. A transient broker hiccup becomes a slower 202 instead of a 500.
- Atomic endpoints: no fit. On Commit, the transactional session sends its dispatch message straight through the transport dispatcher (IMessageDispatcher), not the pipeline, so DispatchRetries never sees it. If that send fails, the session rolls back and Commit throws: Heyi turns it into a 500, and the client's retry, with the same Idempotency-Key, is the retry. The messages themselves are dispatched later by the processor endpoint, from the outbox, where recoverability already retries.
- The layers, from the outside in: the client retries with an Idempotency-Key, the endpoint retries the dispatch (accept-only only), the receiver deduplicates by message ID. A dispatch retry after an ambiguous failure (the broker got the message, the acknowledgment got lost) resends the same message ID, so the receiver's deduplication covers that too.
- Mention it as an option for accept-only endpoints, not a recommendation: a short aside or blockquote, since it's an existing library of mine, not part of Heyi. Heyi's docs mention it the same way. -->

## Conclusion

<!-- TODO: restate: the plumbing belongs to the infrastructure, not to every endpoint. But the more interesting question is whether the endpoint should do the work at all. Where the code lives (repo and package, once public), how to try it, and an invitation for feedback. A wink to the name, if it fits. -->

---

<!-- TODO: header image and Unsplash credit -->
