---
typora-root-url: ..
typora-copy-images-to: ../img/posts

layout: post
title: "The case of NServiceBus long running handlers: OCR Processing."
author: Mauro Servienti
synopsis: "Designing systems using a message based architecture is awesome. Messages are a nice way to design human interactions and to model how difference components in a domain interact with each other. Unfortunately technology, sometimes, causes more headaches than needed. And when it comes to messaging, long running processes are a interesting headache to deal with."
tags:
- NServiceBus
- long running handlers
- sagas
---

Designing systems using a message based architecture is awesome. Messages are a nice way to design human interactions and to model how difference components in a domain interact with each other.
Unfortunately technology, sometimes, causes more headaches than needed. And when it comes to messaging, long running processes are a interesting headache to deal with.

### OCR Processing

Users need to process images and extract text using an optical character recognition system (OCR). This is done via a web interface that allows users to upload images for processing.

Images processing takes time and is done in background, when processing is completed users are notified that their background jobs are ready to be downloaded.

This process can be outlined as follows:

![1482055831647](/img\posts\1482055831647.png)

OCR processing can take a long time and we don't want to hold the incoming user request till is completed. An interesting option is then to offload the OCR work to a back-end system:

1. User request is received by the web application
2. Web application sends a message on a queue to a back-end processing system
3. Back-end processing system processes the image
4. When processing is done and event (again a message) is sent thought the queuing system
5. Web app reacts and notifies the user

### Have we solved the issue?

Not really. Back-end processing [3] cannot happen in the context of the incoming message, queuing systems have the concept of transactional processing that affects the time we have to process the incoming message.

> There are transactional queuing systems that have to respect transaction timeouts and non transactional queuing systems based on peek and lock (or similar) concepts meaning that a messages, once picked by a processor is locked for a certain amount of time and then released to the queue if processing doesn't happen in that timeframe.

In such a scenario increasing the transaction, or lock, timeout is not a solution, it is just a way to postpone the problem at a later time.

### The state machine and the processor

If we take a closer look at the business problem we are trying to solve we notice that we are mixing two different business concerns:

* the need of keeping track of the state of processing jobs using a state machine:
  * Job started
  * Job in progress
  * Job failed for a known reason
  * Job failed for an unknown reason
  * Job completed successfully
* the OCR processing work

[NServiceBus Sagas](https://docs.particular.net/nservicebus/sagas/) are a perfect fit for the state machine, however as we've outlined messages are not a good solution when it comes to long processing time, due to the transactional behavior of queuing systems.

![1482059636774](/img\posts\1482059636774.png)

Backend is now split to handle the two concerns. It's obvious that the communication technology across the `OCR state machine` and the `OCR worker process` cannot be queuing based.

### Conclusions

Using the above scenario I put together a proof of concept that shows how it can be implemented, it's available on my GitHub account in the [NServiceBus.POCs.OCRProcessing](https://github.com/mauroservienti/NServiceBus.POCs.OCRProcessing) repository.

There is also an [official sample](https://docs.particular.net/samples/azure/azure-service-bus-long-running/) showing how to design the same processing logic using Azure ServiceBus in our documentation.