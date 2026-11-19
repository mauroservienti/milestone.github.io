---
layout: post
title: "Should the HTTP endpoint do the work? Heyi: atomic web endpoints for NServiceBus"
author: Mauro Servienti
synopsis: "A web request records a task and sends the message that starts it. Doing both atomically takes a handful of plumbing lines in every endpoint. I built a small library to make them disappear, and along the way asked whether the endpoint should do the work at all."
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

So, I built a library to make those lines disappear: [Heyi](https://github.com/mauroservienti/Heyi) (合一, héyī, "to become one"). It turns ASP.NET Core endpoints into handler-shaped endpoints: they store data and send messages as one atomic operation, on top of the NServiceBus transactional session. And along the way, I ended up asking a different question: should the endpoint do the work at all?

## The plumbing we write today

Let's look at an example. A user asks to cancel an order. The cancellation itself is the backend's job, and it might take a while, but the user wants to follow its progress. So, the following minimal API endpoint records a cancellation request, the task the user can check on, and sends `CancelOrder` to the backend, using the transactional session by hand:

```csharp
app.MapPost("/orders/{orderId}/cancellations", async (Guid orderId, ITransactionalSession session, HttpContext httpContext) =>
{
    await session.Open(new SqlPersistenceOpenSessionOptions());

    // Resolved after Open, so that it uses the session's connection and transaction
    var db = httpContext.RequestServices.GetRequiredService<RequestsDbContext>();

    var cancellation = new CancellationRequest(orderId);
    db.CancellationRequests.Add(cancellation);
    await session.Send(new CancelOrder(orderId, cancellation.Id));

    await session.Commit();

    return Results.Accepted($"/cancellations/{cancellation.Id}", cancellation);
});
```

The task and the message must go together. A task without its message stays pending forever, and a message without its task leaves the user with nothing to look at.

That's not all. For the `DbContext` to join the session's transaction, its registration checks whether there is an open SQL storage session, builds the context on top of its connection, enlists it in its transaction, and asks the session to save the context's changes right before committing. About twenty lines, once per application. The [ASP.NET Core sample in the NServiceBus documentation](https://docs.particular.net/samples/transactional-session/aspnetcore-webapi/) shows them all.

It works, and it's correct. The sample even moves the open and commit part to an MVC filter, so that controllers don't repeat it. That's the right instinct, and it's where Heyi starts from. The sample keeps the filter short on purpose, though: it commits whenever the action doesn't throw, and leaves turning a failed commit into a proper error response as an exercise to the reader.

What can go wrong in those few lines? Let's see:

- **Committing after the response is written.** A middleware that commits after the rest of the pipeline has run is too late: the client already has its `202`, even when the commit fails and the cancellation request never exists.
- **Committing on a `400` or a `409`.** A filter that commits whenever nothing throws doesn't look at the result. The validation failed, the endpoint said so, but whatever it stored and sent before noticing goes through anyway.
- **The `DbContext` using its own connection.** Two connections, two transactions, no atomicity. And it takes very little: injecting the `DbContext` as an endpoint parameter is enough, since parameters are resolved before the endpoint body opens the session.
- **Sending through `IMessageSession` instead of the session.** It compiles, it works, and the message leaves immediately, outside the transaction. Hello, ghost message.

None of these fail loudly. Everything works on a good day, and the damage shows up only when something else goes wrong, which is precisely the case the transactional session exists for.

> If you're wondering why we can't just save and then publish, I wrote about it in ["What's an Outbox and why do we need it?"](https://milestone.topics.it/2023/02/07/outbox-what-and-why.html).

## What if the endpoint looked like a handler?

The following is what an endpoint looks like with Heyi:

```csharp
app.MapPost("/orders/{orderId}/cancellations", async (Guid orderId, RequestsDbContext db, IOutgoingMessages messages) =>
{
    var cancellation = new CancellationRequest(orderId);
    db.CancellationRequests.Add(cancellation);
    await messages.Send(new CancelOrder(orderId, cancellation.Id));
    return Results.Accepted($"/cancellations/{cancellation.Id}", cancellation);
})
.WithTransactionalSession();
```

The endpoint doesn't open, commit, or dispose anything. `WithTransactionalSession()` adds a filter that does it around the endpoint:

- It opens the session before the endpoint runs.
- Right after opening it, it moves the request's `DbContext` onto the session's connection and transaction, no matter when the context was created. Injecting it as a parameter is fine.
- After the endpoint returns, it looks at the status code. A `2xx` commits, before the response is written, and the session saves the context's changes as part of the commit: no `SaveChanges` call needed. Anything else, exceptions included, disposes the session, which rolls back data and messages.
- A failed commit becomes a `500`, never a success.
- `IOutgoingMessages` sends and publishes through the open session. Using it outside a transactional endpoint throws, instead of quietly sending right away.

<!-- TODO: the setup: NServiceBus first, Heyi second (AddNServiceBusEndpoint, then AddHeyi; AddDbContext plus AddHeyiDbContext is shown in the EF Core decision below, so keep it short here or move it), and the checks that fail fast when endpoints are built (AddHeyi missing, no transactional session registered, no open options). -->

Marking endpoints one at a time gets repetitive, too. Minimal APIs have an answer for that: route groups. A route group is a URL prefix plus configuration, such as authorization rules or filters, shared by every endpoint mapped in it. Heyi works on route groups as well:

```csharp
var order = app.MapGroup("/orders/{orderId}").WithTransactionalSession();

order.MapPost("/cancellations", ...);
order.MapPost("/returns", ...);
```

Both endpoints are transactional, each request with its own session.

> Heyi doesn't add guarantees. The [NServiceBus transactional session](https://docs.particular.net/nservicebus/transactional-session/) and the outbox do the heavy lifting; Heyi adds the programming model.

One decision deserves a few more words: how the `DbContext` joins the session. The usual approach builds the context in its DI registration: if there's an open SQL storage session, the context is created on top of its connection and transaction. It works, as long as the session is already open when the context is created. And that's not up to the registration: it depends on when something first asks for the context. An endpoint parameter asks before the endpoint body runs, so before the session opens.

Heyi turns it around. The `DbContext` registration stays the one you already have, and `AddHeyiDbContext` tells Heyi which context to take care of:

```csharp
builder.Services.AddDbContext<RequestsDbContext>(options => options.UseSqlServer(connectionString));
builder.Services.AddHeyiDbContext<RequestsDbContext>();
```

Right after opening the session, Heyi takes the request's context, creating it if nobody asked for it yet, and points it at the session's connection and transaction. Then it asks the session to save the context's changes right before committing. When the context was created doesn't matter anymore, since it's moved over after the fact. Outside transactional endpoints, nothing changes: the context uses its own connection, as registered.

<!-- TODO: other design decisions worth telling, pick one or two:
- why commit before the response is written (and what it costs);
- why status codes decide, not exceptions only;
- send-only web apps and the remote processor endpoint. -->

## Should the endpoint do the work at all?

Look at the endpoint again. It doesn't cancel anything. It records that the user asked, and hands the work over to the backend. That's on purpose: I don't think HTTP endpoints should run business logic at all.

An endpoint that does the work runs it inside an HTTP request: no retries, a client waiting on the other end, and a timeout ready to cut everything short. A message handler runs the same logic with retries, the outbox, and everything else messaging gives us. The endpoint's job is to accept the request, turn it into a message, and get out of the way with a `202 Accepted`.

"But what if the request is invalid?" Validation that only needs the request, such as required fields, formats, and ranges, belongs at the edge, and it happens before anything is sent. Validation that needs the business's state is a different story, but the edge can still look before it leaps. Reading a read model to turn away a request that would obviously fail, such as ordering a product that's no longer available, is fine. As I wrote in ["What if my command was rejected?"](https://milestone.topics.it/2023/06/27/reject-commands.html), commands validated upfront rarely need to fail. Rarely, not never: the check reads state that can change a moment later, so the handler still has the final say. And when accepting first is the business's choice, the backend can still say no later, as in ["Reserve, or apologize?"](https://milestone.topics.it/2027/02/10/reserve-or-apologize.html).

So, where does that leave atomic endpoints? With task-based applications. When users start something that takes time, they want to see it, with its status, right away. The task isn't business logic: it doesn't decide anything, it records that something was asked. But it must be created together with the message that starts the work, and that's precisely the job atomic endpoints are for.

"Couldn't the client generate the task ID, send the command, and poll? A `404` means not started yet." It works as long as the client only tracks the task it just started. It falls apart as soon as the task must show up elsewhere: in the user's list of requests, on a colleague's screen, or in an audit trail that must show the request even when the message is stuck in a queue. Then the task has to exist the moment the request is accepted.

For everything else, really, use accept-only endpoints.

Heyi has those too:

```csharp
app.MapCommand<PlaceOrder>("/orders");           // Send, 202 Accepted
app.MapEvent<OrderRequested>("/order-requests"); // Publish, 202 Accepted
```

<!-- TODO: what accept-only endpoints do: no database, no transactional session, routing comes from the NServiceBus configuration, an optional location to poll (location: command => ...), a malformed body is a 400 and nothing is sent, a failed send is a 500 problem details response. Then the validate hook for the upfront checks described above: it runs before dispatching, returns null to accept or a result (typically a 4xx problem details response) to reject, and nothing is sent when it rejects. Example from the Heyi README: MapCommand<PlaceOrder>("/orders", validate: ...) with IProductCatalog.IsAvailable and a 422. One line on the boundary: the check reads, it doesn't decide; if it needs to store something, it's an atomic endpoint. -->

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
