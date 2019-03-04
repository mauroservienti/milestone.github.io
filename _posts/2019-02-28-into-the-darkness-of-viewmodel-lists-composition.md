---
typora-copy-images-to: ..\img\posts\into-the-darkness-of-viewmodel-lists-composition
typora-root-url: ..
layout: post
header_image: /img/posts/into-the-darkness-of-viewmodel-lists-composition/header.jpg
title: "Into the darkness of ViewModels Lists Composition"
author: Mauro Servienti
synopsis: "ViewModels Lists composition has an interesting challenge: must be designed in such a way that it doesn't flood servers with tons of requests. Number of requests cannot exceed the number of services involved in the composition process, no matter how many items are composed. There is a light at the end of the tunnel (cit.)"
tags:
- SOA
- Services ViewModel Composition
---

We had [a first look at what problem ViewModel Composition is](https://milestone.topics.it/2019/02/06/what-is-services-viewmodel-composition-again.html) designed to solve, then we analyzed what it means to [compose a single item](https://milestone.topics.it/2019/02/20/viewmodel-composition-maze.html), using a Product as sample model. It's now time to start exploring what it means to compose a list of Product ViewModels.

## Dark times

The trap of composing lists of ViewModels is that we cannot apply the same technique used for single items. If we have a list of items, where each item in the list is composed by data coming from multiple services, we cannot compose each item. Composing each item one by one means that our list will turn into a scary `SELECT N+1` type of thing, but worse since it'll be over `HTTP`.

Composing a list is a matter of doing 3 steps:

- step 1: get the keys of the items that should be included in the list
- step 2: get all the data for all the items in the list
- step 3: compose

## Business ownership

Let's continue using the Product sample used in the previous article. We now need to display a list of Products. The first thing, looking at the above steps, is to retrieve the keys of the items we want to display/compose.

### Who should perform that?

We have identified 4 different services so far:

- *marketing* owns name and description
- *sales* owns price
- *warehouse* owns availability
- *shipping* owns shipping options

> Marketing should be really named *product catalog*, you know...naming is hard :-)

Going on with our *made up* sample we could say that business wise Marketing/Product Catalog is the one that makes decisions about the existence of a Product. Which means that from the business perspective *Marketing* owns the concept of a Product.

In this case *Marketing* is the perfect place to ask for the list of Products we want to display. Marketing will be the one handling the `/products` request:

![1551362496722](/img/posts/into-the-darkness-of-viewmodel-lists-composition/1551362496722.png){:class="img-responsive"}

The Marketing component, or `RequestHandler`, will return a list of products, something similar to:

```
[{
   key: 'products/1',
   name: 'Banana Protector',
   description: 'Benran Outdoor Travel Cute Banana Protector Storage Box (Pink, Green, Yellow, Pack of 3)'
},{
    key: 'products/2',
   name: 'Another prodcut',
   description: 'Another product description'
}]
```

At this point Marketing is ready to notify all other interested parties that some products have been loaded:

![1551362507668](/img/posts/into-the-darkness-of-viewmodel-lists-composition/1551362507668.png){:class="img-responsive"}

The Marketing `RequestHandler` publishes an in-memory event to notify that some products have been loaded. Sales and Shipping are interested in augmenting those products, thus they receive the `ProductsLoaded` event, that contains all the keys of the loaded products.

![1551362519284](/img/posts/into-the-darkness-of-viewmodel-lists-composition/1551362519284.png){:class="img-responsive"}

Once all components have received the event they go to their respective backends to retrieve all the information related to all the loaded products, in 1 single roundtrip. 

![1551362531125](/img/posts/into-the-darkness-of-viewmodel-lists-composition/1551362531125.png){:class="img-responsive"}

Once all the information are retrieved the last step, the composition, is not that different from the Single Item Composition scenario:

![1551362461054](/img/posts/into-the-darkness-of-viewmodel-lists-composition/1551362461054.png){:class="img-responsive"}

It's as simple as an in-memory `foreach` iterating over the loaded product, giving each interested party the opportunity to augment each product with their data.

## Conclusions

Composing lists of items sounds complex and scary, we don't want to fall into the `SELECT N+1 trap over HTTP`. Looking deeply into the problem however, first we can identify who is the service responsible to get the list of items to display keys. Once we have all the keys we can apply an approach similar to the one used for the Single Item Composition and retrieve data in batches to optimize server-side communication.

It's probably time to dive into some code. To be continued...