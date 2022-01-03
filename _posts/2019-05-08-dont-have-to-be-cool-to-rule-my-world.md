---
typora-copy-images-to: ..\img\posts\you-dont-have-to-be-cool-to-rule-my-world
typora-root-url: ..
layout: post
header_image: /img/posts/you-dont-have-to-be-cool-to-rule-my-world/header.jpg
title: "You don't have to be cool to rule my world, KISS."
enable_mermaid: true
author: Mauro Servienti
synopsis: "HTTP is the Microservices way, so it must be used as a communication transport, they say. Is HTTP adding any benefit to our systems? Can it be considered harmful in some scenarios? Are there better approaches? Shedding some light on the system logical architecture might be helpful."
tags:
- soa
- architecture
- logical-vs-physical
---

*Today’s post will be more about KISS and SOA in general rather than ViewModel Composition, so it won’t be part of the [ViewModel Composition category](https://milestone.topics.it/categories/view-model-composition). Even if the inception is something discussed in the ViewModel Composition series.*

Nowadays HTTP is everywhere. HTTP is the Microservices way, so it must be used as a communication transport, they say. It even seems that if you're not "doing" HTTP you're not cool, you're legacy, you're living in the past!

I somewhat fell into this trap, take a look at this snippet originally posted in [ViewModel Composition: show me the code!](/view-model-composition/2019/03/06/viewmodel-composition-show-me-the-code.html):

```csharp
class MarketingProductDetailsGetHandler : IHandleRequests
{
   public bool Matches(RouteData routeData, string httpVerb, HttpRequest request)
   {
      /* omitted for clarity */
   }
   
   public async Task Handle(dynamic vm, RouteData routeData, HttpRequest request)
   {
      var id = (string)routeData.Values["id"];

      var url = $"http://marketing.backend.local/api/product-details/product/{id}";
      var response = await new HttpClient().GetAsync(url);

      dynamic details = await response.Content.AsExpando();

      vm.ProductName = details.Name;
      vm.ProductDescription = details.Description;
   }
}
```

## Can you see it?

That request handler is hosted by the [Composition Gateway](/view-model-composition/2019/04/03/turn-on-the-motors.html), which acts like an HTTP reverse proxy. The handler is triggered by an HTTP call, and this is fine because the Gateway is there to serve HTTP requests. But the question should be:

> Is there any good reason to use HTTP to talk to the *Marketing* back-end?

Which are the benefits that HTTP brings to the table in this scenario? Remember that:

* Marketing is a service in the system

* Marketing exposes data to the outside through the Composition Gateway

* There is no such thing as [cross-service communication/composition](/view-model-composition/2019/03/13/there-is-no-such-thing-as-cross-services-composition.html)

HTTP is nice, indeed, but still has a few issues that we need to be aware of. The protocol tends to exacerbate some of the [fallacies of distributed computing](https://particular.net/s/free-ebook-dr-harvey-and-the-8-fallacies-of-distributed-computing). HTTP as a transport is highly interoperable, at the expense of transport costs. Serialization and deserialization impact on bandwidth and thus latency. And we need to be very careful about not introducing any unrequired additional cost.

The designed interaction can be represented using the following diagram:

<div class="mermaid">
graph LR
   A[fa:fa-globe Client] -->|HTTP Request| B[fa:fa-server Composition Gateway]
   B -->|Invoke| C[MarketingProductDetailsGetHandler]
   C -->|HTTP Request| D[fa:fa-server Marketing Backend]
   D -->|DB Connection| E[fa:fa-database Marketing DB]
</div>

Can we make things simpler?

> Warning: Unpopular opinion ahead!

## KISS

```csharp
class MarketingProductDetailsGetHandler : IHandleRequests
{
   public bool Matches(RouteData routeData, string httpVerb, HttpRequest request)
   {
      /* omitted for clarity */
   }
   
   public async Task Handle(dynamic vm, RouteData routeData, HttpRequest request)
   {
      var id = (string)routeData.Values["id"];
      using (var connection = new SqlConnection("marketing-edge-db-connection-string"))
      {
         var commandText = "select Name, Description from Catalog where Id=@id";
         using (var command = new SqlCommand(commandText, connection))
         {
            command.Parameters.Add("@id", SqlDbType.VarChar);
            command.Parameters["@id"].Value = id;

            connection.Open();

            var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
               //retrieve data and fill the vm
               vm.ProductName = ...;
               vm.ProductDescription = ...;
            }

            connection.Close();
         }
      }
   }
}
```

Let's go straight to the *Marketing* database. It'll be simpler, as we just dropped one hop and some  serialization/deserialization:

<div class="mermaid">
graph LR
   A[fa:fa-globe Client] -->|HTTP Request| B[fa:fa-server Composition Gateway]
   B -->|Invoke| C[MarketingProductDetailsGetHandler]
   C -->|DB Connection| D[fa:fa-database Marketing DB]
</div>

Usually the main argument against this approach is: **Coupling**!

But in what way is HTTP making it less coupled?

## Whatchoo talkin' 'bout, Mauro? (cit.)

Architecturally speaking, `MarketingProductDetailsGetHandler` is owned by the *Marketing* service, in which case it has all the rights to directly talk to a *Marketing*-owned database. The handler at deploy time is deployed at the Composition Gateway with all its settings, including the connection string to the database.

> Ops people might then decide that since the Composition Gateway lives in the DMZ, it cannot directly access an internal database and ask the *Marketing* team to setup an edge database for this specific scenario. All Operations concerns.

The fact that the `MarketingProductDetailsGetHandler` talks to a database rather then to an HTTP API doesn't introduce any more coupling. The handler belongs to the same service that owns the data, in which case they are cohesive. It's only a matter of deployment, when the handler is deployed it'll be hosted by the Composition Gateway, which is owned by IT/Ops. The Gateway has absolutely no knowledge about the way the handler will access its data, regardless of the fact it's using HTTP, a direct DB connection, or any other solution.

## Conclusion

Understanding the logical architecture of the system we're designing is a must to better understand the interaction between components, and at the same time get better insights about what they should be allowed to do and what not. It's also important to start distinguishing between the logical architecture and the physical deployment layout.

---

Header image: Photo by [Josh Rakower](https://unsplash.com/photos/zBsXaPEBSeI?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/cool?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
