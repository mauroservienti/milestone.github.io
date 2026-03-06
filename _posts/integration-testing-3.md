---
layout: post
title: "NServiceBus.IntegrationTesting 3 — A new container-based architecture"
author: Mauro Servienti
synopsis: "AI is the great enabler. I've been doing so many things I always wanted to do but never found the time. This time, it's a new version of the NServiceBus.IntegrationTesting framework removing all the limitations of the previous versions by introducing a container-based hosting architecture, providing full endpoint-under-test isolation."
enable_mermaid: true
header_image: /img/posts/integration-testing-3/header.jpg
tags:
- integration-testing
- testing
- ai
---

Without my trusted [Claude Code](https://claude.com/product/claude-code), this would have never seen the light. Not because I couldn't do it myself, but because I lack the time to focus enough on my side projects to get them anywhere.

I released version [3.0.0-beta](https://github.com/mauroservienti/NServiceBus.IntegrationTesting/releases/) of the [NServiceBus.IntegrationTesting](https://github.com/mauroservienti/NServiceBus.IntegrationTesting) framework, and I finally crafted what I wanted from day one.

Integration tests for NServiceBus endpoints let you verify real message flows against a real broker and real persistence. It exercises the full stack of the production endpoints with little to no compromises.

> For an introduction about what I was trying to achieve when I started, you can read [Exploring NServiceBus Integration testing options](https://milestone.topics.it/2019/07/04/exploring-nservicebus-integration-testing-options.html) and [NServiceBus.IntegrationTesting baby steps](https://milestone.topics.it/2021/04/07/nservicebus-integrationtesting-baby-steps.html)

## Container-based means endpoints isolation

With a ton of help from Claude, we rewrote the integration testing framework to leverage containers for endpoint isolation. The biggest drawback of the previous architecture, which started as and remained an interesting experiment, was that all endpoints ran in the same test host process, forcing them to depend on the same .NET version and share the versions of all their dependencies. That meant using the same NServiceBus version, for example.

The new architecture looks like the following diagram:

<div class="mermaid">
graph TD
 TestHost["Test process<br/>TestHostServer (gRPC, dynamic port)"]

 SampleEndpoint["SampleEndpoint<br/>NSB 10 / .NET 10<br/>container"]
 AnotherEndpoint["AnotherEndpoint<br/>NSB 9 / .NET 8<br/>container"]

 RabbitMQ["RabbitMQ container (message broker)"]
 PostgreSQL["PostgreSQL container (Sagas storage)"]

 TestHost <-->|bidirectional streaming| SampleEndpoint
 TestHost <-->|bidirectional streaming| AnotherEndpoint

 SampleEndpoint <--> RabbitMQ
 SampleEndpoint <--> PostgreSQL
 AnotherEndpoint <--> RabbitMQ
</div>

> The [getting started documentation](https://github.com/mauroservienti/NServiceBus.IntegrationTesting/blob/master/docs/getting-started.md) covers all the details.

In a nutshell (well, maybe in a coconut shell ;-P), the test process:
  - Hosts a gRPC server
  - Builds and starts the required containers
  - Kicks off the scenario to test
  - Observes and captures what happens
  - Runs the Assert statements against the captured activity
- Each container:
  - Runs one of the production endpoints
  - Executes one or more scenarios
  - Hosts a gRPC agent to capture and share with the test process what happens

Here is what the test side looks like end to end:

```csharp
[TestFixture]
[NonParallelizable]
public class WhenSomeCommandIsSent
{
    static TestEnvironment _env = null!;
    static EndpointHandle _yourEndpoint = null!;

 [OneTimeSetUp]
    public static async Task SetUp()
 {
 _env = await new TestEnvironmentBuilder()
 .WithDockerfileDirectory(TestEnvironmentBuilder.FindRootByDirectory(".git", "src"))
 .UseRabbitMQ()
 .UsePostgreSql()
 .AddEndpoint("YourEndpoint", "YourEndpoint.Testing/Dockerfile")
 .StartAsync();

 _yourEndpoint = _env.GetEndpoint("YourEndpoint");
 }

 [OneTimeTearDown]
    public static Task TearDown() => _env.DisposeAsync().AsTask();

 [Test]
    public async Task Handler_should_be_invoked()
 {
        var correlationId = await _yourEndpoint.ExecuteScenarioAsync(
            "SomeCommand Scenario",
            new Dictionary<string, string> { { "ID", Guid.NewGuid().ToString() } });

 // this is the overall test timeout
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));

        var results = await _env.Observe(correlationId, cts.Token)
 .HandlerInvoked("SomeMessageHandler")
 .WhenAllAsync();

 Assert.That(
 results.HandlerInvoked("SomeMessageHandler").EndpointName,
 Is.EqualTo("YourEndpoint"));
 }
}
```

A lot is going on; let's dissect it. The first step in the one-time setup phase is to create the resources required by the test. The `TestEnvironmentBuilder` is a thin wrapper around `TestContainers` that makes it easier to set up what the test needs. In this example, we're setting up a container for RabbitMQ, another for PostgreSQL, and a third for the endpoint under test.

The endpoint under test is the tricky part. We want to test the production endpoint, but we also need to inject test-related infrastructure. It's a chicken-and-egg problem; we need the test infrastructure in the endpoint, but we don't want to modify the production endpoint to reference the test stuff. That is when the "Testing" endpoint comes into play.

The Testing endpoint references the production one and the test infrastructure dependencies. It layers the production endpoint code into the container and replaces the entry point with its own. In the new entry point, it calls the production endpoint's configuration factory directly, adds the test-required behaviors and gRPC agent on top, and starts the endpoint.

The first thing the test does is to execute a scenario. A scenario kicks off the message flow. In the above example, the scenario looks like the following class:

```csharp
public class SomeMessageScenario : Scenario
{
    public override string Name => "SomeCommand Scenario";

    public override async Task Execute(
        IMessageSession session,
        Dictionary<string, string> args,
        CancellationToken cancellationToken = default)
 {
        var id = Guid.Parse(args["ID"]);
        await session.Send(new SomeMessage { Id = id });
 }
}
```

Scenarios live in testing endpoints, and tests kick them off by name. The `ExecuteScenarioAsync` call uses gRPC from the test process to the agent running on the endpoint.

In the actual test, we first tell the endpoint under test to execute a scenario, then start observing its behavior. The framework buffers events, so observations registered immediately after the trigger won't miss anything.

Each endpoint under test runs a test agent that installs NServiceBus pipeline behaviors to capture what's happening and report back to the test host via gRPC.

In the above example, the following code waits for a message handler to be invoked:

```csharp
var results = await _env.Observe(correlationId, cts.Token)
 .HandlerInvoked("SomeMessageHandler")
 .WhenAllAsync();
```

> You can observe multiple things at once—for example, a message dispatch or a saga completion.

You can think about observed behaviors as a done condition for the test. The test will wait for all the declared conditions, the `CancellationToken` timeout, or a failed message.

Once the test completes, you can proceed with assertions, as usual.

### What's the correlationId?

Tests can run in parallel. In this case, endpoints might be processing messages from multiple tests. The correlationId, generated when the scenario is kicked off, is automatically stamped on all messages and allows the framework to observe only messages belonging to a specific test.

The above test example uses the `NonParallelizable` attribute, though. We want that because, as written, running tests in parallel would cause them to compete for creating the infrastructure.

## Conclusion

What I described barely scratches the surface of what you can do. The repository [README](https://github.com/mauroservienti/NServiceBus.IntegrationTesting/blob/master/README.md) and the [documentation](https://github.com/mauroservienti/NServiceBus.IntegrationTesting/tree/master/docs) cover everything needed to write complex end-to-end integration tests.

Integration testing makes sense only if we're testing production code and configurations in the least invasive possible manner—the NServiceBus.IntegrationTesting framework enables that. In particular, it enables testing things that no unit or acceptance testing strategy can test. For example:

- Business choreographies and complex message flows
- Message routing configurations
- Serialization
- Outbox and Transactional Session configuration
- Failure scenarios

And many more.

One minor caveat, for now: I'm road-testing the framework in some complex scenarios to release a stable version soon.

---

Photo by <a href="https://unsplash.com/@hannah_tu?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Hannah Tu</a> on <a href="https://unsplash.com/photos/a-close-up-of-a-wooden-wall-with-peeling-paint-6kecX85NSLI?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
