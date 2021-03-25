---
layout: post
header_image: /img/posts/nservicebus-integrationtesting-baby-steps/header.jpg
title: "NServiceBus.IntegrationTesting baby steps"
author: Mauro Servienti
synopsis: "NServiceBus.IntegrationTesting started as an exploration activity and recently turned into a stable v1 release. V1 comes with some new features and one limitation that led to brainstorming options for the future."
tags:
- NServiceBus
- Integration testing
- SOA
---

What started as an experiment evolved a month ago into a stable release. [NServiceBus.IntegrationTesting](https://github.com/mauroservienti/NServiceBus.IntegrationTesting) v1 is available on [NuGet](https://www.nuget.org/packages/NServiceBus.IntegrationTesting/).

The integration testing framework saw the light mainly as an experiment; you can read more about it in ["Exploring NServiceBus integration testing options"](https://milestone.topics.it/2019/07/04/exploring-nservicebus-integration-testing-options.html). The idea was to explore the problem space first. The main questions were:

- What kind of integration testing are NServiceBuse users expecting to perform?
- Which parts of the system cannot be unit tested?

As mentioned in the above-linked article, the main driver is what I like to call choreography testing when it comes to integration testing. Choreography testing's primary goal is to validate that one or more business scenarios behave as expected. A business scenario is handled by many components in a distributed system, being autonomous or business components, hosted by as many again endpoints. The sample provided in the GitHub repository goes like follows:

- `MyService` sends `AMessage` to `MyOtherService`.
- `MyOtherService` replies with a `AReplyMessage`.
- `MyService` handles `AReplyMessage` and sends locally to itself a `StartASaga` message.
- `ASaga` is started in `MyService`.

Looking ab the above "business story," the test needs to be able to assert that `ASaga` started and that `MyService` handled `AReplyMessage`.

Choreography testing is an important part of the integration testing needs; however, users also need to test other aspects of their systems that a unit testing-based approach cannot solve.

## Testing the endpoint configuration

It's essential to ensure that each endpoint configuration works as expected; the proper way to validate the configuration is to exercise the production endpoint by instantiating and running it using the same setup used in production. NServiceBus.IntegrationTesting uses the production code to run tests and, therefore, automatically verifies the configuration's correctness.

## Testing message routing configuration

[Message routing](https://docs.particular.net/nservicebus/messaging/routing) is part of the endpoint configuration and is what makes a choreography successful; the only way to test the correctness of the message routing set up is to exercise the choreography so that endpoints will use the production routing configuration to exchange messages, and to subscribe to events. If the routing configuration is wrong or is missing pieces, the choreography tests will fail.

## Testing sagas message mappings

In theory, it's possible to assert on [saga message mappings](https://docs.particular.net/nservicebus/sagas/message-correlation) using an approval testing approach. By using this technique, it's possible to catch changes to mappings. Although it's impossible to validate that mappings are correct, you'll catch changes using an approval-based approach, but you'll not verify correctness. The only way to make sure saga mappings are correct is, once again, to exercise sagas by hosting them in endpoints, by sending messages and asserting on published messages, and, if needed, on saga data.

## More features in v1

### Assertions

The initial releases came with a few assertion options primarily focused on determining if an endpoint handled a message type or a message invoked a saga was and then asserting also on message or saga data properties. With v1, it's now possible to verify that a saga was completed and that endpoints sent or published a specific message. The same goes for requested timeouts; if a saga requests a timeout, the infrastructure captures it, and it'll be possible to assert that a specific saga type issued a timeout request.

### Rescheduling timeouts 

Integration testing and delayed messages don't play nicely together. A test has a limited amount of time to complete; if a saga schedules a timeout and the timeout handling is required for the test to complete, we might wait for a very long time. Imagine testing the renewal process of a monthly subscription; we cannot wait for a month during a test. In v1, we can reschedule timeouts to shorten them to fit into the test-allocated execution time. For example, if in a saga we do something like:

```csharp
public Task Handle(StartASaga message, IMessageHandlerContext context)
{
   var delay = DateTime.UtcNow.AddDays(10);
   return RequestTimeout<MyTimeout>(context, delay);
}
```

in the corresponding integration test, we can do:

```csharp
public async Task A_sample_test()
{
   var context = await Scenario.Define<IntegrationScenarioContext>(ctx =>
   {
       ctx.RegisterTimeoutRescheduleRule<ASaga.MyTimeout>((msg, delay) =>
       {
           return new DoNotDeliverBefore(DateTime.UtcNow.AddSeconds(5));
       });
   })
   .WithEndpoint<MyServiceEndpoint>(builder => builder.When(session => session.Send("MyService", new StartASaga() { AnIdentifier = Guid.NewGuid() })))
   .Done(ctx => ctx.MessageWasProcessedBySaga<ASaga.MyTimeout, ASaga>() || ctx.HasFailedMessages())
   .Run();

   // assertions here
}
```

The `RegisterTimeoutRescheduleRule` allows to inject a delegate that the infrastructure will invoke for each outgoing timeout of the given type; when invoked, the delegate can inspect the outgoing message, the configured delay, and return a new delay. In the above snippet, we're changing the delay from 10 days to 5 seconds. 

## Assembly scanning known issues

One of the limitations of the current design is the NServiceBus assembly scanning behavior. Endpoints that participate in a test are all hosted in the same process, the test runner process, and share the same application context. Each endpoint automatically scans the `bin` directory looking for assemblies and types to register in the inversion of control container, message handlers to register in the NServiceBus message handler registry, and many more NServiceNus extension points. Suppose all endpoints are hosted in the same process. In that case, they'll all end up sharing the same components leading to unwanted behaviors, such as, for example, all endpoints will register all message handlers, even if they belong to a different endpoint. The patch is to configure the assembly scanner behavior to limit the set of assemblies that each endpoint will scan:

```csharp
public class MyServiceConfiguration : EndpointConfiguration
{
    public MyServiceConfiguration()
        : base("MyService")
    {
        var scanner = this.AssemblyScanner();
        scanner.IncludeOnly("MyService.dll", "MyMessages.dll");

        //rest of the configuration
    }
}
```

With the above configuration, the MyService endpoint will only scan the selected assemblies. A similar setup could have been applied to the test instead of to the production code; however, I prefer to restrict the production code for consistency and to avoid tests behaving differently than production.

The presented `IncludeOnly` method is an extension method that looks like the following:

```csharp
public static AssemblyScannerConfiguration IncludeOnly(this AssemblyScannerConfiguration configuration, params string[] assembliesToInclude)
{
    var excluded = Directory.GetFiles(AppDomain.CurrentDomain.BaseDirectory, "*.dll")
        .Select(path => Path.GetFileName(path))
        .Where(existingAssembly => !assembliesToInclude.Contains(existingAssembly))
        .ToArray();

    configuration.ExcludeAssemblies(excluded);

    return configuration;
}
```

## What's next?

There is no easy way, and maybe there's no way to fix the mentioned assembly scanning issues. In the end, it's hard to call them issues; it's just the behavior of any assembly scanning approach. That makes me think that each endpoint participating in an integration test should be as isolated as possible like they'd be in a production environment. Recently, I found myself brainstorming about the future of the integration testing approach. NServiceBus.IntegrationTesting framework could ship the following:

- A set of libraries to execute tests and connect the dots between the tests and the chosen test runner (as of today, you're forced to use NUnit)
- A Docker container base image to host each endpoint under test in isolation and a set of tools to communicate with the libraries in the test agent process

With that in place, we could write something like:

```csharp
public async Task Pseudo_test_this_is_hypothetical()
{
   var context = new IntegrationTestContext();
   var scenario = new IntegrationScenario(context);
   
   //relative path to C# project
   scenario.AddEndpoint("../../MyEndpoint", onStarted: session => { ... });
   scenario.AddEndpoint("../../MyOtherEndpoint");
   
   scenario.Done(c => c.MessageWasProcessedByHandler(...) || c.HasFailedMessages );

   await scenario.Run();

   Assert.True(...);
}
```

When run, the above scenario packages the supplied C# projects into containers and starts them. Each container will communicate with the test host, e.g., via HTTP, keep the host informed about execution status, and report handled messages and executed sagas. The host will then evaluate the supplied done conditions and determine when the test execution is complete.

Say tuned; exciting times ahead!
