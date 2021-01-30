---
layout: post
header_image: /img/posts/ooops-can-I-try-again-please/header.jpg
title: "Ooops, can I try again, please?"
author: Mauro Servienti
synopsis: "When systems fail, we can retry the whole process and be successful. However, there are scenarios in which retrying a subset of the process might be a better choice. Not all failures are born equal."
tags:
- Distributed Systems
- Retries
- Errors
- Failures
---

Systems fail all the time: Bugs, unavailability of required resources, hardware failures, and many more reasons cause systems to fail. When the system uses messages and queues to exchange information and drive behaviors, one of the advantages is that we can retry messages. A message comes in, and the message handling process fails. Once the root cause of the problem is fixed, the message can be returned to the queue and tried again. If message processing logic changes some data, it can rollback the corresponding database transaction. So far, so good, in many scenarios, we can retry messages.

> More information about errors, failed messages, and retries are available in my ["Businesses don't fail, they make mistakes"](https://milestone.topics.it/2019/09/10/businesses-dont-fail-they-make-mistakes.html) and in David Boike's excellent ["I caught an exception. Now what?"](https://particular.net/blog/but-all-my-errors-are-severe) article on Particular's blog.

Is this it? Or is there something more that we can do?

There are use cases in which not going through the incoming message retry process is beneficial. For example, when dealing with third party systems we might not be in a position to retry messages because they are not idempotent. Another use case is when resources are scarce or expensive; a database operation can be time consuming and lead to deadlocks. It's true that transactions can be rollback and then retried, but it's also true that if retrying has a cost and can lead to deadlocks it might be better to try to avoid retries at any cost. This is one of the reasons why [pessimistic locking was introduced in NServiceBus Sagas](https://particular.net/blog/optimizations-to-scatter-gather-sagas), in high contention scenarios retrying is way worse than waiting.

Moreover, there are use cases where there is no incoming message to retry, but there is only an outgoing message. For example, a system that allows users to reserve hotel rooms throught a web application. The web application once the user submits the reservation request will send one or more messages to process it. However, the interaction with the user happens over HTTP and not using messages. Let's start with the latter.

## No incoming message

All systems interact with the external world, and I have yet to find a scenario in which a system with no outside input makes sense. Information and requests come into the system in many different ways. We cannot expect the caller/sender of these requests to use the same retry approach previously described.

> It's also one of the mantras of distributed systems design: do not offload your problems to the caller.

Imagine a simple scenario in which the caller uses HTTP to send a request to the system; the system offloads the incoming request to a queue to be processed by a background service. If the offload operation, or any other step happening in between, fails, it would be nice to try to avoid merely replying with an HTTP500; it's vulgar.
Let's imagine the problem being a transient failure in the queuing system or in the network, e.g., the sender endpoint cannot contact the message broker. If it's a transient failure, it would be nice to retry a few times before resorting to the HTTP500. In pseudo-code, it could look like:

```
public Task<HttpResponse> ProcessOrder(int orderId)
{
    var retryAttempts = 0;
    while(retryAttempts < 5)
    {
        try
        {
            sendMessage(new ProcessOrder(){ OrderId = orderId });
            return Ack();
        }
        catch
        {
            retryAttempts++;
        }
    }

    return Fail();
}
```

> Sending the message is not the only thing that can fail; as discussed in my last article ["Ehi! What's up? Feedback to users' requests in distributed systems"](https://milestone.topics.it/2021/01/12/feedback-to-users-requests-in-distributed-systems.html), in a complex system, there are many moving parts. In case we need to track the user request to provide feedback, the HTTP request handling code will be more complex, and more things can fail and are worth retrying.

The above pseudo-code can become quite complicated; think about the need to design an exponential back-off policy. At each retry cycle, we wait a little more to increase the chances that the transient failure resolves itself. Tools like [Polly](https://github.com/App-vNext/Polly) solve this exact problem elegantly.

We don't want to repeat the above code everywhere we send a message, though. When using NServiceBus to create a message-based system, thanks to its extensibility model based on [pipeline behaviors](https://docs.particular.net/nservicebus/pipeline/manipulate-with-behaviors), we can extend the pipeline to plug Polly in to handle outgoing message dispatch failures.

> I built an extension to handle outgoing message dispatch failures. More information and API usage details in the [NServiceBus.Extensions.DispatchRetries](https://github.com/mauroservienti/NServiceBus.Extensions.DispatchRetries) GitHub repository.

## What about failures in the context of an incoming message?

It's an exciting scenario to discuss. The immediate reaction would be: Do nothing, the fail and retry pattern (built-in to NServiceBus for example) will fix any temporary dispatch failure. So far, so good.

### What about side effects, though?

Let's imagine a scenario in which the message handling process has side effects, e.g., a payment processing attempt. The system sends a message to the payment processor, the payment processor charges the credit card and replies with an ack/nack type of message.
The response fails to be dispatched. The fail and retry logic kicks in and retries the incoming message, the payment is processed again, and the user's credit card is charged twice or more. We might be in a situation where the third party we're talking to is not idempotent, in which case retrying is not an option: The first and only attempt failed. The payment processor moves the message to the poison messages infrastructure and moves on.

Systems usually offload these situations to human beings.

Polly comes to the rescue once again. We can use all the retry policies provided by Polly to increase the chances the payment processing succeeds. Using such an approach, we can also significantly reduce the number of times the system resorts to human intervention to handle a failure. With the aforementioned NServiceBus extension, we can plug the same Polly policies into the NServiceBus outgoing messages processing pipeline. And thus handle dispatch failures even in the case of handling an incoming message.

## Conclusion

Based on topics discussed in this article and the ones linked above, it's clear that errors and failures, especially in the context of distributed systems, have many nuances. As with all the complex problems, we cannot discard them with a general and simplistic solution that works in all cases. Each type of failure and error needs to be analyzed in detail and a dedicated solution defined.
