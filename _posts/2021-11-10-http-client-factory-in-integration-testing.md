---
layout: post
header_image: /img/posts/http-client-factory-in-integration-testing/header.jpg
title: "HTTP client and HTTP client factory in integration testing"
enable_mermaid: true
author: Mauro Servienti
synopsis: "Integration testing can be challenging. If we're also dealing with HTTP, it can be a nightmare. HTTP client factory in combination with the Microsoft.AspNetCore.Mvc.Testing package can come to the rescue and save our day."
tags:
- integration-testing
---

A few months ago in ["You wanna test HTTP, right?"](https://milestone.topics.it/2021/04/28/you-wanna-test-http.html), I presented how to self host a web application in a test using a self-contained approach that doesn't need external resources, like a running webserver. I didn't invent anything. I limited myself to showing how to use the `WebApplicationFactory<T>` shipped in the `Microsoft.AspNetCore.Mvc.Testing` package.

## Are we done?

I'm using the above-presented approach to design [ServiceComposer](https://github.com/ServiceComposer/ServiceComposer.AspNetCore) integration tests. For more details on ServiceComposer and what it does, refer to the articles in the [ViewModel Composition category](https://milestone.topics.it/categories/view-model-composition).

ServiceComposer integration tests are pretty complex; let me try to simplify the scenario as much as possible. Consider the following class:

```csharp
class AClassThatDoesSomething
{
   public async Task DoSomething()
   {	 
      var url = "http://domain.tld/do/something";
      var httpClient = new HttpClient();
      var response = await httpClient.GetAsync(url);
      //do something meaningful with the response
   }
}
```

How could we test something like that? One option is to provide the test with a proper web server dependency. Not easy, and hard to maintain as the complexity of the business logic increases. Another option could be to make the HTTP client a dependency injected via DI. At a first look, that's problematic too; we cannot mock HttpClient, there are too many options. Another apparent troubling aspect of injecting HttpClient is that the client instance is usually customized with default headers, a base address, and many other settings by each class using it. It would be cumbersome to move the required configuration into the DI/IoC infrastructure.

## Enter HTTP client factory

HTTP client factory allows overcoming all the mentioned issues by injecting `HttpClient` instances as a dependency. It all starts by adding the required services:

```csharp
public void ConfigureServices(IServiceCollection services)
{
   services.AddHttpClient();
   //everything else the application needs
}
```

Once the configuration is set, we can add `HttpClient` registrations by using the following approach:

```csharp
var registrationName = typeof(AClassThatDoesSomething).FullName;
services.AddHttpClient<AClassThatDoesSomething>(
   name: registrationName,
   configureClient: client =>
   {
      client.BaseAddress = new Uri("http://domain.tld/");
      client.DefaultRequestHeaders.Accept = "something else";
   }
);
```

With that in place, the class previously presented becomes:

```csharp
class AClassThatDoesSomething
{
   HttpClient httpClient;
   public AClassThatDoesSomething(HttpClient httpClient)
   {
      this.httpClient = httpClient;
   }

   public async Task DoSomething()
   {	 
      var url = "/do/something";
      var response = await httpClient.GetAsync(url);
      //do something meaningful with the response
   }
}
```

## How does that simplify testing?

Let's imagine our application being a web application, and for the sake of the discussion, let's also imagine that `AClassThatDoesSomething` is injected into one of the controllers. If that's the case, we have a web request invoking a controller action that will use the injected dependency to do something that uses HTTP under the hood.

The described interaction looks like the following diagram:

<div class="mermaid">
graph LR
   A[[Client]]-- HTTP -->B[Controller / Action]
   subgraph web server
      B-->C[AClassThatDoesSomething]
   end
   C--HTTP-->D[[Another web server]]
</div>

In such a scenario, integration testing can quickly turn into a nightmare. HTTP client factory combined with `WebApplicationFactory<T>` can significantly simplify the tests.

```csharp
[Fact]
public async Task Test()
{
   // Arrange
   var appToTest = new WebApplicationFactoryWithWebHost<TheApp.Startup>
   {
      BuilderCustomization = builder =>
      {
         HttpClient ClientProvider(string name) =>
         {
            var remoteApi = new WebApplicationFactoryWithWebHost<RemoteApi.Startup>();
            return remoteApi.CreateClient();
         };
     
         builder.ConfigureServices(services =>
         {
            services.Replace(new ServiceDescriptor(typeof(IHttpClientFactory), new DelegateHttpClientFactory(ClientProvider)));
         });
      }
   };

   var appClient = appToTest.CreateClient();
     
   // Act
   var response = await appClient.GetAsync("/some/url");
     
   // Assert
   Assert.True(response.IsSuccessStatusCode);    
   // more asserts as needed
}
```

It sounds complex, but it's not. We are using the same approach presented in ["You wanna test HTTP, right?"](https://milestone.topics.it/2021/04/28/you-wanna-test-http.html) to self host the application under test entirely in a test. Since some application components have a dependency on the `HttpClient` class, we are replacing the default `IHttpClientFactory` with a custom one designed for the test:

```csharp
 public class DelegateHttpClientFactory : IHttpClientFactory
{
   private readonly Func<string, HttpClient> _httpClientProvider;
	 
   public DelegateHttpClientFactory(Func<string, HttpClient> httpClientProvider)
   {
      _httpClientProvider = httpClientProvider;
   }
	 
   public HttpClient CreateClient(string name)
   {
       return _httpClientProvider(name);
   }
}
```

The `DelegateHttpClientFactory` allows the test to take full control over the `HttpClient` instance creation process. We're finally configuring the test to create another test self-hosted web application, and we return the created client when the HTTP client factory requests it. That means that `AClassThatDoesSomething`, when instantiated in the test, gets as a dependency the `HttpClient` instance created by the test, which is exactly what we want to guarantee that the test is self-contained.

## Conclusion

Invoking an HTTP endpoint in the context of an HTTP invocation might not be a great thing to do, and it's probably an anti-pattern. There are cases, though, in which that's the exact scenario we need to test. HTTP client factory can be a great solution allowing complete control over the `HttpClient` instance creation process.

If you are curious about a scenario in which something like what's shown above makes sense, have a look at the [tests to validate ViewModel Composition scenarios results](https://github.com/mauroservienti/designing-a-ui-for-microservices-demos/blob/master/ASP.Net%20Core%20API%20Gateway%20-%2001/Composition.Tests/When_calling_composition_gateway.cs). The tests are part of the [demos](https://github.com/mauroservienti/designing-a-ui-for-microservices-demos/) of my ["Designing a UI for Microservices"](https://milestone.topics.it/talks/designing-ui-for-microservices.html) talk.

---

Photo by <a href="https://unsplash.com/@barnimages?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Barn Images</a> on <a href="https://unsplash.com/s/photos/http?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
