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

What about the setup? NServiceBus comes first, Heyi second. Heyi doesn't configure or host NServiceBus: the endpoint is configured as usual, with the transactional session and the outbox enabled, and registered with the standard hosting integration. Then Heyi needs to know how to open the session:

```csharp
var endpointConfiguration = new EndpointConfiguration("Sales.Api");
// Transport, serializer, and routing as usual

var persistence = endpointConfiguration.UsePersistence<SqlPersistence>();
persistence.SqlDialect<SqlDialect.MsSqlServer>();
persistence.ConnectionBuilder(() => new SqlConnection(connectionString));
persistence.EnableTransactionalSession();
endpointConfiguration.EnableOutbox();

builder.Services.AddNServiceBusEndpoint(endpointConfiguration);

builder.Services.AddHeyi(options =>
    options.OpenSessionOptions(() => new SqlPersistenceOpenSessionOptions()));
```

Forgetting a piece of it doesn't go unnoticed. When the endpoints are built, Heyi checks that `AddHeyi` was called, that the transactional session is registered, and that it knows which options to open the session with, and fails with a message saying what's missing. ASP.NET Core builds all endpoints together, usually when the first request comes in, so a misconfigured app fails right away, not on the day a request finally reaches the transactional endpoint.

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

Two more decisions are worth telling: when to commit, and what decides whether to commit.

Heyi commits after the endpoint returns, but before the response is written. The endpoint returns a result, not a response: ASP.NET Core writes it afterward, and Heyi sits in between. That's the only place where a failed commit can still become a `500` instead of a `202` for a request that never happened. It comes at a cost: every response waits for the commit. That's a small control message to the broker, sent first so the outcome is atomic either way, and then the database commit. The endpoint's own messages aren't part of the wait: they leave later, from the outbox. I think it's a fair price: the alternative is a fast response that might be lying.

There's still one gap no server can close: the commit succeeds, and the response gets lost on its way to the client. The client sees an error and retries, but the work is already done. That's what the `Idempotency-Key` is for, more on that later.

As for what decides, it's the status code, not exceptions only. Endpoints say no the HTTP way, by returning a `400` or a `409`, not by throwing. A filter that commits whenever nothing throws commits those too, along with whatever the endpoint stored and sent before deciding to say no. Heyi looks at the result: only a `2xx` commits. It understands typed results such as `Results<Accepted, Conflict>`, looking at the one actually returned, and falls back to the response status code for plain return values.

## Should the endpoint do the work at all?

Look at the endpoint again. It doesn't cancel anything. It records that the user asked, and hands the work over to the backend. That's on purpose: I don't think HTTP endpoints should run business logic at all.

An endpoint that does the work runs it inside an HTTP request: no retries, a client waiting on the other end, and a timeout ready to cut everything short. A message handler runs the same logic with retries, the outbox, and everything else messaging gives us. The endpoint's job is to accept the request, turn it into a message, and get out of the way with a `202 Accepted`.

"But what if the request is invalid?" It depends on what "invalid" means. A request can be malformed: a missing field, a card number that fails its checksum, a SKU that doesn't exist. That's validation, and it belongs at the edge, before anything is sent, even when it needs a lookup, such as finding the SKU in the catalog. A request can also be well-formed and still go against a business rule: the product is out of stock, the order has already shipped. That's a decision, and decisions belong to the handler, which makes them with retries and on the state at the time the message is handled. As I wrote in ["What if my command was rejected?"](https://milestone.topics.it/2023/06/27/reject-commands.html), commands validated upfront rarely need to fail, and when they do, it's the business saying no, not the request being wrong. And when accepting first is the business's choice, the backend can still say no later, as in ["Reserve, or apologize?"](https://milestone.topics.it/2027/02/10/reserve-or-apologize.html).

So, where does that leave atomic endpoints? With task-based applications. When users start something that takes time, they want to see it, with its status, right away. The task isn't business logic: it doesn't decide anything, it records that something was asked. But it must be created together with the message that starts the work, and that's precisely the job atomic endpoints are for.

"Couldn't the client generate the task ID, send the command, and poll? A `404` means not started yet." It works as long as the client only tracks the task it just started. It falls apart as soon as the task must show up elsewhere: in the user's list of requests, on a colleague's screen, or in an audit trail that must show the request even when the message is stuck in a queue. Then the task has to exist the moment the request is accepted.

For everything else, really, use accept-only endpoints.

Heyi has those too:

```csharp
app.MapCommand<PlaceOrder>("/orders");           // Send, 202 Accepted
app.MapEvent<OrderRequested>("/order-requests"); // Publish, 202 Accepted
```

There's no database and no transactional session here: the request body becomes the message, and NServiceBus routing decides where it goes, as for any other send. A malformed body is a `400`, and nothing is sent. If the broker can't take the message, the response is a `500` problem details response, never a `202` for something that wasn't accepted. When the client needs somewhere to look for progress, the endpoint can say where:

```csharp
app.MapCommand<PlaceOrder>("/orders", location: command => $"/orders/{command.OrderId}");
```

What about the validation that belongs at the edge? Acceptance checks run before the message is dispatched:

```csharp
class SkuExists(IProductCatalog catalog) : IAcceptanceCheck<PlaceOrder>
{
    public async ValueTask<Acceptance> Check(PlaceOrder command, HttpContext httpContext) =>
        await catalog.Exists(command.Sku, httpContext.RequestAborted)
            ? Acceptance.Accept()
            : Acceptance.Reject(TypedResults.Problem(statusCode: 422, title: "The product doesn't exist."));
}

app.MapCommand<PlaceOrder>("/orders").WithAcceptanceCheck<SkuExists>();
```

A check is a class, so its dependencies come in through the constructor, and it can be tested on its own. Checks run in the order they're added, and the first rejection stops the request: nothing is sent. They're tied to the message type, so a check for the wrong message doesn't compile, and they're only available on accept-only endpoints. A check validates the request; it doesn't decide. When a check starts deciding, it's time to move it to the handler.

## What about retries?

Clients retry, proxies retry, users double-click. Each retry is a new request, and without help, a new set of messages the receivers can't tell apart from the first.

Heyi supports the `Idempotency-Key` header, an [IETF draft](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/) for exactly this. The key becomes the identity of the outgoing messages: the first message sent while handling the request gets `{key}/0`, the second `{key}/1`, and so on. A retried request with the same key produces messages with the same IDs, and receivers deduplicate them as they would any other duplicate, as I described in ["Idempotent, you must be"](https://milestone.topics.it/2026/11/26/idempotency-deep-dive.html).

I want to be clear about the limit. Heyi doesn't deduplicate incoming requests. A retried atomic request runs again: the messages are deduplicated downstream, but the endpoint records the task a second time unless the database says no, for example with a unique index on the key stored alongside the task. Storing responses and replaying them for retried requests is a possible next step, not something Heyi does today.

Retries come in layers. From the outside in: the client retries with an `Idempotency-Key`, and the receiver deduplicates by message ID. In between, the server can retry the dispatch itself.

> For accept-only endpoints, that's what [NServiceBus.Extensions.DispatchRetries](https://github.com/mauroservienti/NServiceBus.Extensions.DispatchRetries) does: its README opens with this exact scenario. Accept-only endpoints send through `IMessageSession`, so the send goes through the outgoing pipeline, where DispatchRetries retries it before giving up: a broker hiccup becomes a slower `202` instead of a `500`. It doesn't apply to atomic endpoints: on commit, the transactional session sends its control message straight through the transport, outside the pipeline. If that fails, the session rolls back, the client gets a `500`, and the client's retry, with the same key, is the retry. And if a dispatch retry resends a message the broker had already received, it resends it with the same ID, so deduplication covers that too.

## Conclusion

Storing a task and sending the message that starts it, atomically, shouldn't take a page of plumbing in every endpoint. The plumbing belongs to the infrastructure, and with Heyi, the endpoint is left with what it's for.

But the plumbing wasn't the most interesting part. Should the endpoint do the work? I don't think so. Validate the request, record a task when users need to see it, and hand the work to a message handler: atomic endpoints when there's a task, accept-only endpoints for everything else.

Heyi is available [on NuGet](https://www.nuget.org/packages/Heyi), and the code is [on GitHub](https://github.com/mauroservienti/Heyi). Try it, break it, and tell me what's missing by [opening an issue](https://github.com/mauroservienti/Heyi/issues). And the name? 合一, héyī, means "to become one". Data and messages, become one.

---

<!-- TODO: header image and Unsplash credit -->
