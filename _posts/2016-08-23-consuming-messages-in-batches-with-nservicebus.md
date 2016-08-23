---
layout: post
title: "Consuming messages in batches with NServiceBus."
author: Mauro Servienti
tags:
- NServiceBus
- batch
---

I [already talked a lot](https://www.google.it/search?q=nservicebus+site%3Amilestone.topics.it&oq=nservicebus+site%3Amilestone.topics.it&aqs=chrome..69i57.9261j0j4&sourceid=chrome&ie=UTF-8#q=nservicebus+site:milestone.topics.it&start=0) about [NServiceBus](http://particular.net/nservicebus) and as you might know I work for [Particular Software](http://particular.net/), we make NServiceBus.

I wrote a [very basic introduction in 2012](http://milestone.topics.it/2012/10/nservicebus-overview.html) using the phone call and express courier analogy.

Some time ago [Ugo](https://twitter.com/imperugo) asked me a question about the ability to consume messages in batches, his use case is pretty simple:

> Given an endpoint that receives a single message type is there a way to consume messages in batches instead of being forced to consume each message on its own?

Ugo's goal is to optimize message processing when all messages are of the same type and the business process is not (at this stage) interested in differentiating the process based on the message content.

### It's not supported.

Unfortunately it is not supported, the NServiceBus transport, that is the underlying structure that manages the input queue is designed to handle one message at a time building a transaction for each consumed message, or a transaction-like behavior for non-transactional transports, such as RabbitMQ and Azure ServiceBus.

### That doesn't mean it cannot be done.

The fact that it is not supported out of the box by NServiceBus doesn't really mean that it cannot be done. Imagine we have something producing a stream of messages, that is exactly what the NServiceBus transport does, what we could do is design something like the following:

```csharp
class BatchedMessageConsumer<TMessageType>
{
  ReplaySubject<TMessageType> stream = new ReplaySubject<TMessageType>();
  public BatchedMessageConsumer(TimeSpan consumeTimeout, int batchMaxSize)
  {
    stream.Buffer(consumeTimeout, batchMaxSize)
                .SubscribeOn(NewThreadScheduler.Default)
                .Subscribe(batch =>
                {
                    foreach(var message in batch)
                    {
                        //process the message or process the entire batch
                    }
                });
  }
  
  public void AppendToNextBatch( TMessageType message )
  {
    stream.OnNext(message);
  }
}
```

The above is a sample, and simple, batching engine based on .Net [Reactive Extensions](https://github.com/Reactive-Extensions). What is happening is that:

* First we configure the batch size and the maximum time to wait, they are both very important:
  * `batch size` determines how large the batch is and should be based on what we want to do with the batch itself, e.g. store it in a database;
  * `maximum time to wait` is required to avoid transaction rollbacks, imagine a scenario where we'd like to consume messages in batches of 500 messages but we are currently in an environment with a low throughput, if there are a few messages in the batch we want to be sure to consume them before the incoming message transaction times out;
* What Reactive Extensions guarantee is that the first threshold that is reached, timeout or buffer size, will cause the batch to be processed;

Last step is to register the above class as a singleton service in the [NServiceBus inversion of control container](http://docs.particular.net/nservicebus/containers/) so that we can depend on it in message handlers:

```csharp
class MyHandler : IHandleMessages<MyMessage>
{
  public BatchedMessageConsumer<MyMessage> BatchedConsumer{ get; set; }
  
  public void Handle( MyMessage message )
  {
    BatchedConsumer.AppendToNextBatch( message );
  }
}
```

### Conclusions

The above code sample can be used as a baseline to build a batched message processing engine, what is missing (being a sample) is the required error handling logic and, if needed, how to group different transactions in a single one when a batch is processed.
