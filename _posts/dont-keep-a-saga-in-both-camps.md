Recently I delivered a distributed systems workshop for an [Italian user group](https://www.craftedsoftware.org). Based on some of the conversations I had with attendees, I wrote, "[There is no such thing as orchestration](link to blog post)." More recently, in the user group Slack workspace, a member asked the following question:

> If a saga operates on multiple microservices, how can we adhere to the autonomy principle and make it so that they are independently deployable?
> _(adaptation from Italian is mine)_

We could argue that the mentioned post about orchestration is a good enough answer, and there is no need for further discussion. Or we could say that the question is misspelled and conflates the microservices theory lingo and the SOA one. Neither is true. The question makes sense and highlights that something we discussed during the workshop didn't get through enough.

For the sake of the discussion, let's rephrase the question a bit by changing one word:

> If a saga operates on multiple _autonomous components_, how can we adhere to the autonomy principle and make it so that they are independently deployable?

We're now using only the SOA lingo. Before continuing, an autonomous component is not a microservice. However, if we have to make a theory comparison, that's the best equation we can do. In the orchestration versus choreography post, when talking about the choreography approach, I presented the following diagram:

![choreography](link to image)

If we were to implement the above architecture using NServiceBus, we would use the following NServiceBus features:

![choreography with NServiceBus](link to image)

We're using a mix of [sagas](link to documentation) and regular [message handlers](link to documentation). One thing that captures the attention is that some saga communicates using events, and others using commands. The "do something" semantic of commands generates more coupling. Are those sagas, in reality, orchestrators?

## Transactions, transactions everywhere

Let's pause for a second the architectural discussion, and let's have a look at the technical implementation. The payment gateway component is part of the payment process. We're deploying it separately and mediating the communication using messages for a technical reason: We cannot enlist any of the payment gateway operations in a transaction. 

The system dialogues with the payment provider through HTTP, and web requests cannot be enlisted in ACID transactions. The finance policy implementation uses an NServiceBus saga. The saga state needs to be stored. The store operation is transactional and includes any outgoing message. For example, the following operations are all in the same transaction:

```csharp
async Task Handle(AMessage msg, IMessageHandlerContex ctx)
{
   Data.SomeData = msg.SomeData;
   await ctx.Send( new AnotherMessage() );
}
```

> if the underlying queuing infrastructure doesn't support transactions NServiceBus Outbox feature allows to guarantee an exactly-once message processing behavior.
> For those not used to the NServideBus API, the `Data` property is an instance of the saga state. The state gets serialized and stored to the underlying storage to persist across multiple message processing.

On the other hand, in the following example, the HttpClient web request cannot be enlisted in the same transaction as the other two operations:

```csharp
async Task Handle(AMessage msg, IMessageHandlerContex ctx)
{
   Data.SomeData = msg.SomeData;
   await httpClient.PostAsync( ... );
   await ctx.Send( new AnotherMessage() );
}
```

For that reason, we offload the non-transactional operation to a different handler and mediate the communication using a message:

```csharp
async Task Handle(AMessage msg, IMessageHandlerContex ctx)
{
   Data.SomeData = msg.SomeData;
   await ctx.Send( new PerformHttpRequest() );
   await ctx.Send( new AnotherMessage() );
}
```

The `PerformHttpRequest` message will be handled in isolation by a message handler and potentially in a different endpoint, whose only responsibility will be to perform the HttpRequest. It's the single responsibility principle (SRP) applied to distributed systems.

## Interesting, isn't that orchestration?

uhm...no. If the payment service were to say to the shipping service, now it's time to ship, using a command, that would have been orchestration. In the presented scenario, payment is talking to itself.

The crucial aspect is the difference between the logical boundaries and the physical deployment. If we look at the logical boundaries, the payment gateway is part of the payment service. The sole difference is that the payment gateway is deployed separately from the payment policy for technical reasons. On the other hand, any other service in the system is in a different logical boundary. Each logical service is composed of multiple autonomous components. Each component can be deployed differently depending on the business or technical requirements, but the deployment type doesn't change the logical ownership. For a different perspective about logical vs. physical, my colleague Dennis van der Stelt [recently wrote an excellent piece that touches on logical ownership](https://bloggingabout.net/2021/07/01/distributed-monolith/).

## Conclusion 

Distinguishing the physical aspects of a system, also known as the deployment concerns, from the logical ones is critical to determine what is not allowed and what is acceptable. No saga can orchestrate actions happening outside of the logical boundaries it belongs to, and this rule applies to any component in the system. The key takeaway is that we don't want to allow any orchestration to cross logical service boundaries.
