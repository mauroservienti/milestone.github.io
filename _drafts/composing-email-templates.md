---
layout: post
title: "Mail merge, composition style: who owns the email template?"
author: Mauro Servienti
synopsis: "Marketing wants to send an order confirmation email. It owns the template, but none of the data that fills it: items and totals belong to Sales, the shipping address and the delivery estimate to Shipping. Like Word's mail merge, the trick is to separate the document from the data source. Let's see how ViewModel Composition provides the data and how hosting Razor turns it into an email."
header_image: /img/posts/composing-email-templates/header.jpg
tags:
- soa
- viewmodel-composition
series: view-model-composition
---

A few years ago, in ["You want to compose emails, right?"](https://milestone.topics.it/2021/07/02/you-want-to-compose-emails-right.html), I argued that an email is a frontend like any web page. The only difference is the transport: HTTP for the page, SMTP for the email. If it's a frontend, we can use [ViewModel Composition](https://milestone.topics.it/categories/view-model-composition) to gather the data it needs.

After that article, a reader asked a follow-up question: they were using SendGrid templates and wanted to know how the component that fills and sends the email is hosted. It's a fair question, and the 2021 article didn't answer it.

Let's answer it with an example: the order confirmation email. Customers place an order, and they receive an email with the list of products they bought, the order total, the shipping address, and the estimated delivery date.

## Remember mail merge?

Microsoft Word has had a feature called [mail merge](https://en.wikipedia.org/wiki/Mail_merge) for decades. Someone designs a letter with placeholders, such as `«FirstName»` and `«Address»`, and Word fills them with rows from a data source, for example, a spreadsheet. The person designing the letter doesn't own the spreadsheet, and the spreadsheet doesn't know anything about the letter.

That's precisely the split we need. Who owns what in the order confirmation email?

- **Marketing** owns the template: the wording, the layout, the branding, and the decision of when an email is worth sending. It also owns product names, as I discussed in ["Back to Basics: who owns the data?"](TODO-data-ownership-url).
- **Sales** owns the order: the items, their quantities and prices, and the total.
- **Shipping** owns the shipping address and the estimated delivery date.
- **Customers** owns the customer's name and email address.

Marketing owns the document, but almost none of the data. If marketing reached into other services' databases to fill the template, every change to those databases would break the email. If, instead, Sales and Shipping started building emails, wording changes would require releasing services that have nothing to do with marketing.

What marketing needs is a data source that someone else fills. That's what a composed API is.

## Composing the model

The composition gateway exposes a route dedicated to the email: `/emails/order-confirmation/{orderId}`. Why not reuse the order details page route? Because the email isn't the page. It needs different data, for example, the delivery estimate, and it's requested by a back-end component rather than by the customer, which affects authorization. A dedicated route allows each service to decide what to contribute to the email without affecting the page.

Each service contributes its slice with a composition handler. Sales loads the order items and raises an event, so that other services can enrich them:

```csharp
record OrderItemsLoaded(IDictionary<int, dynamic> ItemsByProductId);

[CompositionHandler]
class SalesOrderConfirmationHandler(SalesDb db, IHttpContextAccessor httpContextAccessor)
{
    [HttpGet("/emails/order-confirmation/{orderId}")]
    public async Task Handle(int orderId)
    {
        var request = httpContextAccessor.HttpContext.Request;
        var context = request.GetCompositionContext();
        var vm = request.GetComposedResponseModel();

        var order = await db.GetOrder(orderId);
        var itemsByProductId = new Dictionary<int, dynamic>();
        foreach (var line in order.Lines)
        {
            dynamic item = new ExpandoObject();
            item.ProductId = line.ProductId;
            item.Quantity = line.Quantity;
            item.Price = line.Price;
            itemsByProductId[line.ProductId] = item;
        }

        await context.RaiseEvent(new OrderItemsLoaded(itemsByProductId));

        vm.Items = itemsByProductId.Values.ToArray();
        vm.Total = order.Total;
    }
}
```

Marketing subscribes to the event and adds product names:

```csharp
class MarketingOrderItemsHandler(MarketingDb db) : ICompositionEventsHandler<OrderItemsLoaded>
{
    public async Task Handle(OrderItemsLoaded @event, HttpRequest request)
    {
        var names = await db.GetProductNames(@event.ItemsByProductId.Keys);
        foreach (var (productId, item) in @event.ItemsByProductId)
        {
            item.ProductName = names[productId];
        }
    }
}
```

> If the event-based approach to lists looks unfamiliar, I covered it in ["Into the darkness of ViewModel Lists Composition"](https://milestone.topics.it/2019/02/28/into-the-darkness-of-viewmodel-lists-composition.html).

Shipping and Customers add their properties in the same way, with handlers bound to the same route. The composed result is a JSON document like the following:

```json
{
  "items": [
    { "productId": 42, "quantity": 2, "price": 19.90, "productName": "Coffee mug" },
    { "productId": 7, "quantity": 1, "price": 120, "productName": "Espresso machine" }
  ],
  "total": 159.80,
  "customerName": "Mauro",
  "email": "mauro@example.com",
  "shippingAddress": "Via Roma 1, Milano",
  "estimatedDelivery": "2026-11-03"
}
```

That's the spreadsheet in our mail merge.

## Hosting Razor

Now we need the Word part: something that takes a template and fills it with the composed data. Email providers like SendGrid offer template engines, and in many cases they're good enough. However, if we want to own templates, version them, and render them in our own process, we can host a template engine ourselves.

Razor is a natural choice in .NET: developers know it, and it's expressive enough to handle lists, conditions, and formatting. Razor isn't tied to ASP.NET MVC. Libraries like [RazorLight](https://github.com/toddams/RazorLight) compile and render Razor templates from strings at runtime, which is precisely what we need when users design templates and store them somewhere, rather than developers shipping them with the code.

Marketing reacts to the `OrderPlaced` event published by Sales. The message handler loads the template, asks the composition gateway for the model, renders the email, and sends it:

```csharp
class OrderPlacedHandler(
    IEmailTemplates templates,
    IHttpClientFactory httpClientFactory,
    IRazorLightEngine razor,
    IEmailSender emailSender) : IHandleMessages<OrderPlaced>
{
    public async Task Handle(OrderPlaced message, IMessageHandlerContext context)
    {
        var template = await templates.Get("order-confirmation");

        var client = httpClientFactory.CreateClient("composition-gateway");
        var json = await client.GetStringAsync(
            $"/emails/order-confirmation/{message.OrderId}",
            context.CancellationToken);
        dynamic model = JsonConvert.DeserializeObject<ExpandoObject>(json, new ExpandoObjectConverter());

        string body = await razor.CompileRenderStringAsync(
            $"{template.Name}-v{template.Version}",
            template.Content,
            model);

        await emailSender.Send((string)model.email, template.Subject, body);
    }
}
```

`IEmailTemplates` and `IEmailSender` stand for wherever marketing stores templates and whatever it uses to send emails, an SMTP server or a provider API.

The template is what marketing users design:

```cshtml
@using System
<p>Hi @Model.customerName, thanks for your order!</p>
<table>
@foreach (var item in Model.items)
{
    <tr>
        <td>@item.quantity x @item.productName</td>
        <td>@item.price.ToString("C")</td>
    </tr>
}
</table>
<p>Total: @Model.total.ToString("C")</p>
<p>
    We'll ship it to @Model.shippingAddress.
    It should arrive by @DateOnly.Parse(Model.estimatedDelivery).ToString("D").
</p>
```

A few things I learned while putting the sample together:

- **JSON has no types.** The composed model travels as JSON, and the estimated delivery date arrives as a string. That's why the template parses it before formatting it. Template authors need to know the shape of the model, including the types of its values, which means the composed route is a contract, and it deserves documentation, like any other API.
- **`System.Text.Json` doesn't deserialize to `ExpandoObject`.** It produces `JsonElement` instances, which aren't friendly to navigate from a template. Newtonsoft.Json, with its `ExpandoObjectConverter`, produces a dynamic object that Razor can navigate with the familiar dot syntax.
- **RazorLight templates don't import `System` by default.** Hence the `@using System` at the top of the template.
- **Compiled templates are cached by key.** When users change a template, the key must change too. Otherwise, RazorLight keeps rendering the old compiled version. That's why the key includes the template version.

> In 2021, I mentioned that calling the composition gateway over HTTP from a message handler smells of temporal coupling. It does, but it's contained: if the gateway or one of the services is unavailable, the handler fails and the incoming message is retried later. Retries come with a different problem, though: sending an email isn't idempotent. If the handler fails after sending, the customer receives the email twice, or seven times, as I described in ["Seven emails later"](https://milestone.topics.it/2026/10/24/seven-emails-duplicate-messages.html).

## Templates are code

There's a catch I don't want to hide. A Razor template isn't a document with placeholders: it's compiled into C# and executed. Anyone who can edit a template can run code inside the marketing process, with the same permissions the process has. A template can read files, call external services, or loop forever.

If the people designing templates are developers or trusted users, and templates go through some form of review before going live, that's acceptable. If templates are designed by people outside the development team, or worse, by customers, Razor is the wrong tool. Template languages such as Liquid, through libraries like [Fluid](https://github.com/sebastienros/fluid), or [Scriban](https://github.com/scriban/scriban), are designed to be sandboxed: templates can only access the model they're given.

The good news is that the choice doesn't affect the architecture. The composed model, the dedicated route, and the message handler stay the same. Only the rendering step changes.

## Conclusion

An email is a frontend, and like any frontend, it needs data owned by many services. Mail merge is a useful mental model: marketing owns the document, ViewModel Composition provides the data source, and a template engine hosted by marketing merges the two. Razor is a natural fit for .NET teams, as long as we remember that a Razor template is code and treat it accordingly.

---

TODO: header image and credits
