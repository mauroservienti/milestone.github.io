---
typora-copy-images-to: ..\img\posts\exploring-nservicebus-integration-testing-options
typora-root-url: ..
layout: post
header_image: /img/posts/exploring-nservicebus-integration-testing-options/header.jpg
title: "Exploring NServiceBus Integration Testing options"
author: Mauro Servienti
synopsis: "Like when rehearsing for a show you feel the need to test the entire choreography, sometimes there is the need to test the full business scenario. When using messaging it's not easy and NServiceBus unit testing capabilities don't help much. Follow me in a journey that explores integration testing options with NServiceBus."
tags:
- NServiceBus
- Testing
- Integration Testing
---

NServiceBus comes with a [powerful unit testing framework](https://docs.particular.net/nservicebus/testing/). The unit testing framework is designed to allow users to test components in isolation. Let's take, for example, the following message handler:

```csharp
public class MyReplyingHandler : IHandleMessages<MyRequest>
{
    public Task Handle(MyRequest message, IMessageHandlerContext context)
    {
        return context.Reply(new MyResponse());
    }
}
```

What we might want to test is that the reply occurred, this can be achieved with the following unit test:

```csharp
[Test]
public async Task ShouldReplyWithResponseMessage()
{
    var handler = new MyReplyingHandler();
    var context = new TestableMessageHandlerContext();

    await handler.Handle(new MyRequest(), context);

    Assert.AreEqual(1, context.RepliedMessages.Length);
    Assert.IsInstanceOf<MyResponse>(context.RepliedMessages[0].Message);
}
```

The presented unit test uses `NUnit` as testing infrastructure, but that choice is up to you.

## Is this enough?

Not necessarily. We could say that if users are testing in isolation their components (handlers, sagas, behaviors, etc...), and that if we test all the NServiceBus components the system is guaranteed to work as expected. That's true in theory but not in practice. There could be scenarios, for example, in which the endpoint routing is misconfigured causing messages to not reach the expected destination. This type of error, and many others like wrongly configured subscriptions when using message based pub/sub transports like MSMQ, cannot really be validated in a unit testing scenario.

In general we could say that business scenarios cannot be tested. When testing a business scenario the goal is to validate that the expected messages choreography happens and that all the components (mainly handlers and sagas) are invoked as expected. In this case we don't care much about data, and in general input/output values, those are handled by unit tests. We care much more that what's described in the business scenario happens.

## NServiceBus Acceptance Testing

NServiceBus has an [Acceptance Testing framework](https://www.nuget.org/packages/NServiceBus.AcceptanceTesting/). It's unsupported, and undocumented. And it's intentional. The NServiceBus Acceptance Testing framework is designed for internal usage to test NServiceBus components, not end users code. We use it extensively to guarantee that all our components plays nicely when used together in an endpoint.

[Roy Cornelissen](https://roycornelissen.wordpress.com/), an [NServiceBus Champ](https://particular.net/champions), wrote an article on how to use the Acceptance Testing framework to achieve something like what a business scenario test could look like. It available on his blog at https://roycornelissen.wordpress.com/2014/10/25/automating-end-to-end-nservicebus-tests-with-nservicebus-acceptancetesting/

Roy's approach is good and uses the Acceptance Testing framework exactly as intended. However it has two main drawbacks:

- it's very complex
- it requires a lot of code duplication

In the end it's hard to say that the tests are testing any production code.

Both complexity and code duplication are imposed by the Acceptance Testing framework, that as said is not really designed for such kind of testing.

## NServiceBus Integration testing

Not being able to test business scenario, exercising the real production code, can be a limitation in a lot of cases so I decided to try to understand what could be the requirements and I spiked a [solution](https://github.com/mauroservienti/NServiceBus.IntegrationTesting). A solution that right now has a ton of limitations and is far from being anything ready to be used.

Let's say that there is a system that is composed by two endpoints: [MyService](https://github.com/mauroservienti/NServiceBus.IntegrationTesting/tree/master/src/MyService), [MyOtherService](https://github.com/mauroservienti/NServiceBus.IntegrationTesting/tree/master/src/MyOtherService). These are just regular NServiceBus endpoints. The business flow is something like:

- `MyService` sends `AMessage` to `MyOtherService`
- `MyOtherService` replies with a `AReplyMessage`
- `MyService` handles `AReplyMessage` and sends locally to itself a `StartASaga` message
- `ASaga` is started in `MyService`

What I want to validate is that the outlined flow happens. I wrote the following [test](https://github.com/mauroservienti/NServiceBus.IntegrationTesting/blob/master/src/MySystem.AcceptanceTests/When_doing_something.cs):

```csharp
[Test]
public async Task something_should_happen()
{
    var expectedSomeId = Guid.NewGuid();
    var context = await Scenario.Define<Context>()
        .WithEndpoint<MyServiceEndpoint>(g => g.When(b => b.Send(new AMessage()
        {
            ThisWillBeTheSagaId = expectedSomeId
        })))
        .WithEndpoint<MyOtherServiceEndpoint>()
        .Done(c =>
        {
            return
            (
                c.HandlerWasInvoked<AMessageHandler>()
                && c.HandlerWasInvoked<AReplyMessageHandler>()
                && c.SagaWasInvoked<ASaga>()
            )
            || c.HasFailedMessages();
        })
        .Run();

    var invokedSaga = context.InvokedSagas.Single(s => s.SagaType == typeof(ASaga));

    Assert.True(invokedSaga.IsNew);
    Assert.True(((ASagaData)invokedSaga.SagaData).SomeId == expectedSomeId);
    Assert.False(context.HasFailedMessages());
    Assert.False(context.HasHandlingErrors());
}
```

There is lot going on, I'd like to highlight just two things for now:

- The test is spinning up 2 endpoints, `MyServiceEndpoint` and `MyOtherServiceEndpoint`. Those are real NServiceBus endpoints.
- The test is defining a `Done` condition used internally by the testing infrastructure to determine that the test is done and asserts can be executed. It is needed because there are real messages flowing around on real queues, so everything is asynchronous. What's interesting is what's in the done condition, the test is done when:
  - `AMessageHandler` is invoked (satisfying `MyService` sends `AMessage` to `MyOtherService`)
  - `AReplyMessageHandler` is invoked (satisfying `MyService` handles `AReplyMessage`)
  - `ASaga` is invoked (satisfying `ASaga` is started in `MyService`)
  - Or something goes badly and there are errors

### Endpoints

What are those endpoints? They are defined in the same test class as follows:

```csharp
class MyServiceEndpoint : EndpointConfigurationBuilder
{
   public MyServiceEndpoint()
   {
      EndpointSetup<ServiceTemplate<MyServiceConfiguration>>();
   }
}
```

I'm gaming the system a little bit here. Under the hood I'm still using the NServiceBus Acceptance Testing framework for now as it has all the infrastructure required to run endpoints, but I need to be able to run endpoints whose configuration is defined elsewhere. It has to be the user endpoint configuration. `MyServiceConfiguration` is defined in the `MyService` endpoint project and is the configuration that will end up being used in production. It looks like this:

```csharp
public class MyServiceConfiguration : EndpointConfiguration
{
    public MyServiceConfiguration()
        : base("MyService")
    {
        this.UseSerialization<NewtonsoftSerializer>();
        this.UsePersistence<LearningPersistence>();
        var transportConfig = this.UseTransport<LearningTransport>();

        transportConfig.Routing()
            .RouteToEndpoint(typeof(AMessage), "MyOtherService");

        this.SendFailedMessagesTo("error");

        //omitted for clarity
    }
}
```

Here is the trick: in the endpoint code instead of using the `EndpointConfiguration` class directly I'm creating a class the inherits from it setting configuration values in the constructor. This way I can then reference that class in the test to identify a configuration that should be used to spin up an endpoint. The `ServiceTemplate` thing in the test code is again a tricky way to glue my spike with the existing Acceptance testing infrastructure.

The "only" thing the testing infrastructure is doing when endpoints are started in the test is to inject a pipeline behavior to capture information about what the endpoint is doing and allow, for example, the done condition or the asserts to be evaluated.

## Conclusion (for now)

This is the very first step in exploring options to run integration tests using NServiceBus. Using the Acceptance Testing framework as a building block allowed me to spike something in a couple of hours. It's also showing its limitations. Limitations that are preventing a few things to work and that are imposing a few restrictions. I had a chat with my colleague [Tim Bussmann](https://github.com/timbussmann) and we brainstormed options to evolve this spike. Stay tuned.

The full source code is available on GitHub: https://github.com/mauroservienti/NServiceBus.IntegrationTesting/

---

Header image: Photo by [Nicolas Thomas](https://unsplash.com/@nicolasthomas?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/experiment?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
