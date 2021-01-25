---
layout: post
header_image: /img/posts/transactions-none-thanks/header.jpg
title: "Transaction? None, thanks"
author: Mauro Servienti
synopsis: "Queues are designed for reliability. I personally stress a lot about designing message processing to be as transactional as possible. Is there a use case for unreliable message processing?"
tags:
- Distributed Systems
- Transactions
- Long running
- Sagas
---

A few years ago, I wrote about long-running jobs in ["The case of NServiceBus long running jobs: OCR Processing."](https://milestone.topics.it/2016/12/20/the-case-of-nservicebus-long-running-handlers-ocr-processing.html) Please, go and read it.

Long-running jobs have not to be confused with long-running business transactions; they are both long-running but different. 

> Confusing, isn't it? Our industry is extremely good at terms overloading.

Let's start with the difference between jobs and business transactions. A job, in this context, is a step in a business transaction. For example, the business transaction is the payment process, and one of the jobs is to authorize the user's credit card and another one to charge it. As demonstrated in the linked article, there are cases in which, when using message-based architectures, jobs can be problematic: this is when the job lasts longer than the allowed transaction timeout. Transaction to not be confused with business transactions, overloaded terms again.
As demonstrated in the mentioned article, NServiceBus sagas, and messages in general, are not a good fit for extended processing time scenarios. If the processing time exceeds the transaction timeout, message processing fails, and the NServiceBus retry logic will try it again; it'll fail again, and again, and again. And eventually will end up in the error queue where there's not much we can do about it.

The solution previously presented is to decouple the long-lasting job from the business transaction, offloading it to a different process and using an additional channel to communicate. The [sample](https://github.com/mauroservienti/NServiceBus.POCs.OCRProcessing), linked in the previous article, shows how to run the job in a separate executable and how to use WCF to handle the communication channel.

## Can we resort to messages and avoid WCF?

We can. The above-linked article and sample use an NServiceBus Saga to manage the business transaction. The Saga keeps track of the OCR job process by polling, at regular intervals, the OCR process host using a WCF HTTP Channel. We can reverse the responsibilities and make it so that the OCR process's responsibility is to tell the Saga about any relevant status change. The OCR process can use messages over a queue to report status changes; there are no transaction timeouts problems to handle. Once all this is in place, the last bit we need to get rid of WCF is initiating the OCR processing.

We can use messages there too, and at the same time avoid the transaction timeout trap by setting the `TransportTransactionMode` of the receiving endpoint to `None`. When the transport transaction mode is `None`, what happens is that the endpoint picks up the message from the input queue and immediately acknowledges the message as consumed. It's effectively an [unreliable](https://docs.particular.net/transports/transactions#transactions-unreliable-transactions-disabled) mode. However, it's the same reliability level provided by WCF. We still need a separate endpoint because the transaction mode is not per message; it's an endpoint level configuration that affects how the endpoint processes every consumed message.

## To recap

We still need two endpoints because they have different and incompatible transaction configurations:

- the long-running job coordinator 
- the long-running job executor

The coordinator uses the transaction mode that best suits our environment needs, and the executor uses `None`.
The coordinator still uses an NServiceBus Saga to track the execution status; Sagas is a perfect solution for managing long-running processes. At the same time, the coordinator can continue to use Saga Timeouts. This time the check is not a ping request using WCF, but it'll merely check against flags in the Saga data waking up itself regularly.

There are very few use cases in which a `TransportTransactionMode` value of `None` makes sense. The presented scenario avoids using a different technology to create a communication channel between coordinators and executors. There might be many more. Have you ever faced one, or do you want to discuss your scenario? Ping me in the comments, and we can chat about it.
