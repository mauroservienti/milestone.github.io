---
layout: post
title: "NServiceBus batch processing with Sagas."
author: Mauro Servienti
synopsis: "We have already seen how to consume, or simulate that, messages in batches. We might have a different use case, from the one outlined in the previous post, money transactions processing."
tags:
- NServiceBus
- batch processing
- sagas
---

We have already seen how to [consume, or simulate that, messages in batches](http://milestone.topics.it/2016/08/23/consuming-messages-in-batches-with-nservicebus.html). We might have a different use case from the one outlined in the previous post:

> The system processes money transactions, due to government regulations, on a daily basis, all the processed transactions needs to be delivered to an external authority.

In the above sample use case `On a daily basis` is the batch definition. Or, in lack of a better term, the "business batch" definition I should say.

### Can we model that with NServiceBus Sagas?

Why not? If we think about it what we just described is a long running business process cumulating money transactions details, that lasts a day, and that ends when transactions are delivered to the external authority. Something like:

```csharp
class TransactionMonitorSaga : Saga<TransactionMonitorSaga.SagaState>,
  IHandleMessages<IMoneyTransactionProcessed>,
  IHandleMessages<DeliverProcessedTransactions>
{
  public class SagaState : ContainsSagaData
  {
    public List<String> TransactionIds { get; set; }
  }
  
  public void Handle( IMoneyTransactionProcessed message )
  {
    //cumulate
    this.Data.TransactionIds.Add( message.TransactionId );
  }
  
  public void Handle( DeliverProcessedTransactions message )
  {
    //deliver to third party
    //mark as complete
  }
}
```

The above is a "pseudo-near-to-complete" [NServiceBus Saga](http://docs.particular.net/nservicebus/sagas/) sample.

### Is that enough?

Absolutely no. The above sample is missing a key aspect, it misses the message that starts the Saga. We have an interesting issue now, how can we know when a new Saga needs to be started? Do we need to schedule somewhere a daily job that on a daily basis kicks off a new saga? What if that daily job fails and we miss one?

All good questions, that don't need an answer, because the solution is much simpler than expected:

```csharp
class TransactionMonitorSaga : Saga<TransactionMonitorSaga.SagaState>,
  IAmStartedByMessages<IMoneyTransactionProcessed>,
  IHandleMessages<DeliverProcessedTransactions>
{
  public class SagaState : ContainsSagaData
  {
    [Unique]
    public String BatchId { get; set; }
    public List<String> TransactionIds { get; set; }
  }
  
  protected override void ConfigureHowToFindSaga(SagaPropertyMapper<TransactionMonitorSaga.SagaState> mapper)
  {
  	mapper.ConfigureMapping<IMoneyTransactionProcessed>(message => message.BatchDate)
                .ToSaga(sagaData => sagaData.BatchId);
  }
  
  public void Handle( IMoneyTransactionProcessed message )
  {
    //ensure correlation
    this.Data.BatchId = message.BatchDate;
    //cumulate
    this.Data.TransactionIds.Add( message.TransactionId );
  }
  
  public void Handle( DeliverProcessedTransactions message )
  {
    //deliver to third party
    //mark as complete
  }
}
```

There is a lot going on, let's go through the changes step by step:

* We said that we need to find a way to [start a new Saga instance](http://docs.particular.net/nservicebus/sagas/#starting-a-saga), the simplest thing is to use the already defined `IMoneyTransactionProcessed` message and mark it as `IAmStartedByMessages<TMessage>` that indicates to NServiceBus that the incoming message type can start a new Saga.

At this stage what happens is that for each incoming `IMoneyTransactionProcessed` a new Saga will be started, and it is not really what we want:

* Via the `ConfigureHowToFindSaga` method we explain to NServiceBus how to [find and correlate](http://docs.particular.net/nservicebus/sagas/#correlating-messages-to-a-saga) existing Sagas to incoming messages

What happens now is interesting, what NServiceBus does for each incoming message is that if the message is defined as `IAmStartedByMessages<TMessage>` and a Saga correlation cannot be established a new Saga will be created, otherwise an existing one will be loaded.

* The last step is as simple as defining a correlation id that can be stable on a daily basis, is there anything better that the money transaction date? e.g. a string like `"20160907"` will identify all the transactions processed on September the 7th.

The Saga [infrastructure concurrency management](http://docs.particular.net/nservicebus/sagas/concurrency) finally guarantees that 2 Sagas with the same unique correlation id cannot be created.

### Is that all folks?

No, we still miss one last step: transactions delivery to the authority. Again we don't want to setup something external to trigger the delivery process. One easy way to do is via [Saga Timeouts](http://docs.particular.net/nservicebus/sagas/timeouts).

```csharp
class TransactionMonitorSaga : Saga<TransactionMonitorSaga.SagaState>,
  IAmStartedByMessages<IMoneyTransactionProcessed>,
  IHandleTimeouts<DeliverProcessedTransactions>
{
  public class SagaState : ContainsSagaData
  {
    [Unique]
    public String BatchId { get; set; }
    public List<String> TransactionIds { get; set; }
  }
  
  protected override void ConfigureHowToFindSaga(SagaPropertyMapper<TransactionMonitorSaga.SagaState> mapper)
  {
  	mapper.ConfigureMapping<IMoneyTransactionProcessed>(message => message.BatchDate)
                .ToSaga(sagaData => sagaData.BatchId);
  }
  
  public void Handle( IMoneyTransactionProcessed message )
  {
    //ensure correlation
    if( String.IsNullOrWhiteSpace(this.Data.BatchId))
    {
      this.Data.BatchId = message.BatchDate;
      this.RequestTimeout<DeliverProcessedTransactions>( /* define when, e.g. tomorrow */ );
    }
    //cumulate
    this.Data.TransactionIds.Add( message.TransactionId );
  }
  
  public void Timeout( DeliverProcessedTransactions message )
  {
    //deliver to third party
    //mark as complete
  }
}
```

We simply changed the `DeliverProcessedTransactions` to be a Timeout message, that will trigger the Saga instance later, where "later" is defined by us.

### Conclusions

We've seen how simple is to leverage NServiceBus Sagas to implement some business batch processing logic. In the sample we had the opportunity to use a simple property on the incoming message as the correlation mechanism, if in your scenario that's not possible you can always [inject your own complex Saga finding logic](http://docs.particular.net/nservicebus/sagas/saga-finding) to satisfy whatever correlation need you might have.

That's all folks! By the way, take a look at [what's new for Sagas in NServiceBus V6](http://particular.net/blog/nservicebus-sagas-simplified).
