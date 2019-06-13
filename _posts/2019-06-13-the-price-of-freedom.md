---
typora-copy-images-to: ..\img\posts\the-price-of-freedom
typora-root-url: ..
layout: post
header_image: /img/posts/the-price-of-freedom/header.jpg
title: "The Price of Freedom"
author: Mauro Servienti
synopsis: "When deisgning UIs for a distributed system we're faced with many choices. It's hard to districate ourselves into the options jungle. We might be tempted to select what at a first look seems to be most flexible solution, as flexilbility pretend to imply freedom. It's tremendously easy to transition from freedom to anarchy."
tags:
- SOA
- Services ViewModel Composition
category: view-model-composition
---

# The Price of Freedom

In the long digression about [ViewModel Composition](/categories/view-model-composition) we really never touched the UI problem, we dealt with data, ViewModels, but never with how data should be displayed on a user interface.

To be honest it's not really our problem and there isn't a generic solution. It implies diving into UI presentation technology. Once ViewModels are composed we can handover data to a user interface infrastructure, such as an application running on a device, that is monolithic. Without diving into the nitty gritty details of UI frameworks we [have sliced, enough, our system into vertical slices](/view-model-composition/2019/04/09/slice-it.html).

Although, we probably need to spend a few words about user interfaces, the micro-frontends movement is flourishing.

We can divide the UI world into two macro categories, whose separation is not really clear as there are possibly much more than 50 shades of gray between the white "Branding" and the black "Magic".

## Branding

On the one hand there is really nothing wrong in having a monolithic user interface. We can call it the Branding-style approach, Branding acts like a service defining contracts that other services needs to implement and respect if they want their data displayed on a UI they don't own. Services own the data, not the way they are displayed.

The following snippet uses an ASP.Net MVC Core Razor page as a sample:

```html
<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">@Model.ProductDescription</h3>
    </div>
    <div class="panel-body">
        <div>Price: @Model.ProductPrice</div>
        <div>Shipping Options: @Model.ProductShippingOptions</div>
        <div>Inventory: @Model.ProductInventory</div>
    </div>
</div>
```

The snippet displays information of a `Product` (business concept), each piece of information comes from a different service, it's composed using the [single item composition technique](/view-model-composition/2019/02/20/viewmodel-composition-maze.html) and finally handed over to that page. This approach has pros and cons:

- it's easy to understand what is going on

- it's easy to apply consistent styling to such page

- it's easy to evolve the page in a consistent way

However, there is lack of ownership hindering evolution. Each service has a dependency, and vice-versa, on Branding when they need to change something that has an impact on the way data are displayed. Simplicity comes at a cost.

## Magic

Still using ASP.Net Core MVC we could redesign the above page using the following approach:

```html
<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">@await Component.InvokeAsync("ProductDetails")</h3>
    </div>
    <div class="panel-body">
        @await Component.InvokeAsync("ProductDetailsPrice")
        @await Component.InvokeAsync("ProductDetailsShippingOptions")
        @await Component.InvokeAsync("ProductDetailsInventory")
    </div>
</div>
```

The presented snippet leverages [ASP.Net Core View Components](https://docs.microsoft.com/en-us/aspnet/core/mvc/views/view-components). Each component will be owned by the service that owns the data the component displays. All the components will receive the same composed ViewModel, but now each service has also the responsibility to present data. As expected there are pros and cons:

* We have achieved full ownership. Each service owns the entire vertical slice.
* Full ownership means more freedom, and possibly speed, in evolving services

However full vertical ownership comes at a cost, complexity:

- it's harder to understand what is going on
- it's harder to maintain visual coherence
- deployment techniques need to be "invented" to make, for example, that each service can manage styling information but at deploy time everything is packed into the smallest number of artifacts.

## Conlusion

Freedom doesn't come for free, every choice that we make is a compromise. It's important to carefully evaluate the system we are designing and the its constraints, both internal and external, technical and non-technical. Each choice has a cost, the more freedom we want the more the more careful we want to be. It's tremendously easy to transition from freedom to anarchy.

---

Header image: Photo by [ian dooley](https://unsplash.com/@sadswim?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/search/photos/freedom?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)