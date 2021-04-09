---
layout: post
header_image: /img/posts/on-viewmodel-composition-and-ui-composition/header.jpg
title: "On ViewModel Composition and UI Composition"
author: Mauro Servienti
synopsis: "We often confuse UI and ViewModel Composition. They are not the same thing, and they solve different problems. We can use them in isolation, but in most cases, they give their best when used in conjunction."
tags:
 - SOA
 - Services ViewModel Composition
 - UI Composition
 - Micro frontends
category: view-model-composition
---
 
They're not the same thing. They're not orthogonal. They can be used in conjunction or isolation, depending on the scenario.

I briefly touched on UI and ViewModel Composition in ["The Price of Freedom"](https://milestone.topics.it/view-model-composition/2019/06/13/the-price-of-freedom.html). This post details the responsibilities of two architectural approaches.

## What are they?

UI Composition, often also referred to as micro frontends, is the practice (or pattern maybe) of splitting the UI into multiple autonomous components that evolve independently. A framework is then responsible for bringing all the parts together to display a meaningful UI to users. The composition can happen at runtime or build-time, depending on the technology of choice or the toolchain. For example, the following is a rough and trivial UI Composition option:

```html
<html>
   <head>
      <title>Composed dashboard</title>
   </head>
   <body>
      <table>
         <tr>
            <td>
               <iframe src="http://gauges.sample/g1" name="Sample gauge 1">
               </iframe>
            </td>
         </tr>
         <tr>
            <td>
               <iframe src="http://gauges.sample/g2" name="Sample gauge 2">
               </iframe>
            </td>
         </tr>
      </table>
   </body>
</html>
```

The above sample uses HTML IFrame elements to compose UI fragments from different sources. The described page doesn't know and doesn't control the content rendered inside the IFrames. A little bit more sophisticated sample is the following that uses ASP.NET Core ViewComponents:

```html
@{
   ViewBag.Title = "Available Products";
}
	 
   <div class="jumbotron">
      <h2>Available Products</h2>
</div>
	 
@await Component.InvokeAsync("Catalog.ViewComponents.AvailableProducts", Model.AvailableProducts)
```

The "available products" page shows all the products available in a hypothetical online shop. The page doesn't own the content structure but delegates it to external components. In the above sample, the AvailableProducts component from Catalog is responsible for rendering products. It does so in the following way:

```html
<h2>Available products</h2>
<ul>
  @foreach (dynamic availableProduct in Model)
  {
    <li>
    <a asp-controller="Products"
         asp-action="Details"
         asp-route-id="@availableProduct.Id">@availableProduct.ProductName</a>,
         @await Component.InvokeAsync("Sales.ViewComponents.AvailableProductPrice", availableProduct)
    </li>
  }
</ul>
```

Similarly, the component doesn't know how to render prices; it delegates the responsibility to a component from Sales.

More sophisticated samples involve cross-component communication. For example, a menu component, when clicked, can cause another one on the page, e.g., a gauge to show a different set of data.

We can push even further. Instead of having a known markup skeleton, we could be using a mechanism to discover components at runtime and inject them into the user interface. For example, it's what the data template mechanism does in WPF (Windows Presentation Foundation).

I'm barely scratching the surface here; this post's goal is to discuss the relationship between UI and ViewModel Composition and not detail the technologies involved. Suppose you want to dive into UI Composition and micro frontends; in that case, a good starting point is the [OpenComponents framework](https://opencomponents.github.io), my friend [Mattia](https://twitter.com/mattiaerre) that is one of the contributors, and the folks at OpenTable.

## Fun, fun, fun. So, what's the problem?

The presented solution works very well, regardless of the technology we select to implement it. If the more than legit goal is to componentize the user interface, UI Composition is a good solution. However, not all that glitters is gold. Let's take into account the following pseudo user interface markup:

```xml
<section>
   <product-name-and-description />
   <product-price />
<section>
```

Each one of the `<product-* />` elements is an autonomous component.

### What's the data source?

Let's imagine the presented user interface lives on a web page; given that it represents a product, a URL probably identifies it, e.g. `/products/123`. At runtime, the browser loads the page. The UI Composition framework of choice loads the data using URL data as part of the resource identifier. Each component can extract from the loaded product the portion they need to display data.

If the system is a distributed system, it's legit to expect that product name and description come from the Catalog service and price comes from the Sales service. At this point, the UI Composition framework cannot make any assumption and cannot load data on behalf of the components as it doesn't know where to load the data. Components, being autonomous, can load data by themselves.

The consequence is that instead of one HTTP call to load a product, we need two of them, each one issued by a component, going to different services. Fair enough, it's the cost of autonomy, and it comes with significant advantages.

### Size vs. Quantity 

At this point, we might be faced, depending on the scenario, with a first issue. If the client runs on a device with low-quality connectivity, e.g., a mobile device on the go, multiple outgoing HTTP calls to compose the user interface of a single page might be too much. It means that the user interface needs to handle failures in retrieving a subset of the data, needs to be able to retry, and set up retry policies. It sounds like a violation of responsibilities; the user interface is doing too much.

### Item and Items

The multiple outgoing HTTP calls from a client running with a low-quality connection might be a scenario you're not facing. A more common one, when it comes to UI Composition, is the following:

```xml
<section>
   <products-list>
      <item>
         <product-name-and-description />
         <product-price />
      </item>
      <item>
         <product-name-and-description />
         <product-price />
      </item>
   </products-list>
<section>
```

You can probably quickly spot the issue. If each component is responsible for retrieving data for itself, the above snippet serves a "retrieve data N+1" scenario on a silver plate. For the sake of the discussion, let's imagine that each component uses HTTP to get data. In the above snippet, the user interface lists two products, each one composed of two components. When rendered, the UI will issue 4 HTTP requests, one for each component. Each component will hit its backend storage to retrieve data one by one. It's not that different from selecting data from a database without using joins or, worse, by issuing a select statement for each row that we need to load; this is when ViewModel Composition comes into play.

## ViewModel Composition to the rescue

ViewModel Composition is responsible for retrieving and composing data from different sources later presented to a consumer as a whole. The consumer at this point can be anything; the ViewModel Composition infrastructure doesn't care who the consumer is. Suppose the consumer is a user interface that uses UI Composition. In that case, ViewModel Composition lifts the above-described problems and is responsible for making sure that each request hits the backend infrastructure the fewest number of times. In the case of a distributed system, it means that, regardless of the number of items displayed on the UI, the number of backend requests should be not more than the number of services involved in the composition process.

Using the product list sample presented above and expanding a bit to make it more real-world, let's imagine designing a home page where the need is to highlight the most popular products. Marketing is the service responsible for tracking products' popularity, and the only thing that stores are the product ID and a rank value. Catalog stores the product name and description, indexed by product ID. Finally, the Sales service stores the product price. All the data consumers require must be composed using not more than three requests, one for each service.

ViewModel Composition techniques allow services to participate in the composition process to optimize the number of requests going to the backend. ViewModel Composition also comes with the advantage of masquerading the backend topology from the consumers. In most cases, ViewModel Composition uses a reverse proxy-like approach, being it a proper reverse proxy or a logical one, making so that consumers deal with a single source, the composition infrastructure, that returns a single cohesive and coherent ViewModel. From the consumer perspective, the composition infrastructure is entirely transparent; consumers won't realize that their data comes from multiple sources.

To dive into ViewModel Composition's details [there are 16 articles, including this one, available on this blog, on the topic](https://milestone.topics.it/categories/view-model-composition), ranging from introduction content to the nitty-gritty details of writing data using decomposition techniques.

## Are you saying the same logic applies to writes, Mauro?

You bet! In distributed systems, it's pretty common to have a form that needs to post data to multiple services. I specifically wrote on the topic in ["The fine art of dismantling"](https://milestone.topics.it/view-model-composition/2019/04/18/the-fine-art-of-dismantling.html) and in ["Safety first."](https://milestone.topics.it/2019/05/02/safety-first.html)

## Conclusion

It's easy to confuse UI and ViewModel composition and treat them as if they were a single thing. They are not. They address different problems. Once we understand what they solve, everything becomes much more straightforward, and the whole system will benefit from a leaner architecture where responsibilities are correctly assigned.

---

Photo by <a href="https://unsplash.com/@lazycreekimages?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Michael Dziedzic</a> on <a href="https://unsplash.com/s/photos/discuss?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
