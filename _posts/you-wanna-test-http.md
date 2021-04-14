---
layout: post
header_image: /img/posts/you-wanna-test-http/header.jpg
title: "You wanna test HTTP, right?"
author: Mauro Servienti
synopsis: ""
tags:
- 
---

One of the beauties of testing is that it generates confidence. It's genuinely the essential aspect. Code evolves, needs to be maintained and fixed. We want to be confident that a set of changes will not change the expected behavior; we need to be sure we're not reintroducing bugs or undesirable behaviors that we already fixed.

There is a need for safety, and testing creates that.

Testing practices alone are not enough to create the required safety. Manual testing, for example, is a form of testing that comes with little sense of security: manual testing is prone to human and distraction errors. To build the required level of trust, we need attributes such as repeatability, isolation, and automation. Tests need to be automated so that they can run automatically at well-known predefined stages. Tests need to be repeatable and idempotent to guarantee consistency of results; Finally, tests need to be isolated and self-contained to ensure that one test doesn't affect others.

Isolation comes with some headaches. Typically we start facing troubles when the tested components depend on external resources. For example, if we're testing a repository component, we need a data source to test that the repository does what it promises. The dependency on external resources generally surfaces as a problem the more we approach the boundaries of the system under test. A business component might depend on the repository mentioned above; in a test, we can mock the repository and pilot the business component tests. When testing the repository, it's hard or even impossible to mimic the required data source.

HTTP resources pose a similar issue. Let's imagine that you want to use [approval testing](https://approvaltests.com) techniques to validate that an HTTP endpoint returns the expected result. The test exercises the client of the HTTP resource, that is, the system under test. In this scenario, the HTTP resource is not different from the database required by the repository mentioned above. As for databases, we cannot mock HTTP resources. At the same time, hosting a webserver in a test is not straightforward.

## Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactory

With ASP.NET Core comes a testing package, `Microsoft.AspNetCore.Mvc.Testing`, that allows piloting a webserver hosted in a test:

```csharp
[Fact]
async Task SampleFact()
{
   var factory = new WebApplicationFactory<ApplicationToTest.Startup>();
   var client = factory.CreateClient();
   var response = await client.GetAsync("/sample/1");

   Assert.True(response.IsSuccessStatusCode);
}
```

The presented test seems trivial, but it's not. The `WebApplicationFactory<TEntryPoint>` uses the startup class from another project; the `ApplicationToTest.Startup` is the production startup code. Once we have a factory instance, we can create an HTTP client talking to that web application. The created client gets automatically configured with a default base address, e.g., `http//localhost:1234`, and we can use it to issue HTTP requests to the application.

That's just the tip of the iceberg. Things get much more interesting if we inherit from the `WebApplicationFactory<TEntryPoint>`. For example, when using .NET 5, we can do the following:

```csharp
class WebApplicationFactoryWithHost<TEntryPoint> :
	 WebApplicationFactory<TEntryPoint>
	 where TEntryPoint : class
{
   private readonly string[] args;
   public Action<IHostBuilder> HostBuilderCustomization { get; set; }
   public Action<IWebHostBuilder> WebHostBuilderCustomization { get; set; }
	 
   public WebApplicationFactoryWithHost(string[] args = null)
   {
      this.args = args ?? new string[0];
   }
 
   protected override IHostBuilder CreateHostBuilder()
   {
      var hostBuilder = Host.CreateDefaultBuilder(args);
      hostBuilder.ConfigureWebHostDefaults(webBuilder =>
      {
         WebHostBuilderCustomization?.Invoke(webBuilder);
      });

      HostBuilderCustomization?.Invoke(hostBuilder);
 
      return hostBuilder;
   }
}
```

The `WebApplicationFactoryWithHost` custom class allows complete control over the host and web host configurations (in .NET Core 3 and earlier, we can customize only the web host). Better control allows for much greater flexibility in tests.

## That's NOT all, folks

Let's imagine that we're developing a web component; for the sake of the discussion, let's imagine a simple ASP.NET Core Middleware:

```csharp
public class RequestCultureMiddleware
{
   private readonly RequestDelegate _next;

   public RequestCultureMiddleware(RequestDelegate next)
   {
      _next = next;
   }

   public async Task InvokeAsync(HttpContext context)
   {
      var cultureQuery = context.Request.Query["culture"];
      if (!string.IsNullOrWhiteSpace(cultureQuery))
      {
         var culture = new CultureInfo(cultureQuery);
         CultureInfo.CurrentCulture = culture;
         CultureInfo.CurrentUICulture = culture;
      }

      _next(context);
   }
}
```

> The complete sample is available on the [official Microsoft documentation.](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/middleware/write?view=aspnetcore-5.0)

To use the custom middleware, we'd generally write an extension method like the following:

```csharp
public static class RequestCultureMiddlewareExtensions
{
   public static IApplicationBuilder UseRequestCulture( this IApplicationBuilder builder)
   {
      return builder.UseMiddleware<RequestCultureMiddleware>();
   }
}
```

That allows to configure the web application in the following way:

```csharp
public void Configure(IApplicationBuilder app)
{
   app.UseRequestCulture();
   //more configuration here
}
```

If we wanted to test the middleware, we could use the `WebApplicationFactory<TEntryPoint>` mentioned above. Still, we should include a dummy web application project in the solution just to referencing the `Startup` class. That sounds overkill.

Carefully looking at the [official documentation](https://docs.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.mvc.testing.webapplicationfactory-1?view=aspnetcore-5.0), it sounds that's not needed at all:

> Creates an instance of WebApplicationFactory<TEntryPoint>. This factory can be used to create a TestServer instance using the MVC application defined by TEntryPoint and one or more HttpClient instances used to send HttpRequestMessage to the TestServer. The WebApplicationFactory<TEntryPoint> will find the entry point class of TEntryPoint assembly and initialize the application by calling IWebHostBuilder CreateWebHostBuilder(string [] args) on TEntryPoint.
>
> This constructor will infer the application content root path by searching for a WebApplicationFactoryContentRootAttribute on the assembly containing the functional tests with a key equal to the TEntryPoint assembly FullName. In case an attribute with the right key can't be found, WebApplicationFactory<TEntryPoint> will fall back to searching for a solution file (*.sln) and then appending TEntryPoint assembly name to the solution directory. The application root directory will be used to discover views and content files.
>
> The application assemblies will be loaded from the dependency context of the assembly containing TEntryPoint. This means that project dependencies of the assembly containing TEntryPoint will be loaded as application assemblies.

I'm quoting from the above-linked documentation page. It sounds like the purpose of the `TEntryPoint` type is to set up the dependency context and not necessarily to link to a startup class. It turns out that we can write the following:

```csharp
class WebApplicationFactoryWithHost<TEntryPoint> :
	 WebApplicationFactory<TEntryPoint>
	 where TEntryPoint : class
{
    Action<IServiceCollection> configureServices;
    Action<IApplicationBuilder> configure;
    string[] args;

    public Action<IHostBuilder> HostBuilderCustomization { get; set; }
    public Action<IWebHostBuilder> WebHostBuilderCustomization { get; set; }

    public WebApplicationFactoryWithHost(Action<IServiceCollection> configureServices, Action<IApplicationBuilder> configure, string[] args = null)
    {
        this.configureServices = configureServices;
        this.configure = configure;
        this.args = args ?? new string[0];
    }

    protected override IHostBuilder CreateHostBuilder()
    {
        var hostBuilder = Host.CreateDefaultBuilder(args);
        hostBuilder.ConfigureWebHostDefaults(webBuilder =>
        {
            webBuilder.ConfigureServices(configureServices);
            webBuilder.Configure(configure);

            WebHostBuilderCustomization?.Invoke(webBuilder);
        });

        HostBuilderCustomization?.Invoke(hostBuilder);

        return hostBuilder;
    }
}
```

I feel that what the above class is doing is pretty straightforward and doesn't need any comment. The presented `WebApplicationFactoryWithHost` is nothing more than a sample. There are many enhancements that we can apply. It just works for my use case.

Let's have a look at the usage:

```csharp
[Fact]
async Task SampleMiddlewareTest()
{
   var factory = new WebApplicationFactoryWithHost<Dummy>
   (
      configureServices: services =>
      {
         //configure services as needed
      }
      configure: app =>
      {
         app.UseRequestCulture();
         //rest of the required app configuration here
      }
   );

   var client = factory.CreateClient();
   var response = await client.GetAsync("/sample/1?culture=it-IT");

   Assert.True(response.IsSuccessStatusCode);
   //more assertions to validate the culture settings
}
```

Cool, isn't it? We're self-hosting the whole web application in the test. We control the services customization and the application set up when started. Finally, we can exercise it like if it was an actual web application.

> The `Dummy` class is nothing else that a marker/empty class defined in the test project. It can be whatever type in the test project; the runtime will use it to identify the assembly to create the dependency context to load dependencies.

## Conclusion 

As we've seen, there are cases in which we need to test components that require HTTP. We cannot quickly treat those components as external resources like we'd do with a data source in a test. The `WebApplicationFactory` class comes to the rescue allowing us to host a self-contained web application in a test.

---

Photo by <a href="https://unsplash.com/@scienceinhd?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Science in HD</a> on <a href="https://unsplash.com/s/photos/testing?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
