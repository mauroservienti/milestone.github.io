---
layout: post
title: "The case of broken SignalR Authentication."
author: Mauro Servienti
tags:
- SignalR
- auth
---

I'm playing with a sample project that utilizes ASP.Net MVC, WebAPI and SignalR. My need is to add a very basic authentication mechanism to show how to handle identity propagation to endpoints when using NServiceBus and messages.

Something similar to the [WS-Federation on top of NServiceBus](http://milestone.topics.it/2012/06/ws-federation-on-top-of-nservicebus.html) scenario but using a much simpler authentication mechanism, in the end it's a sample that aims to show how to propagate authentication information not how to create and use authentication.

The sample is based on OWIN so I started by adding the following configuration to my `Startup` class:

![OWIN basic Startup configuration](/img/the-case-of-broken-signalr-authentication/startup-config.png =450x)

With my surprise I immediately run into the following issue:

![Missing identity](/img/the-case-of-broken-signalr-authentication/user-is-missing.png =450x)

What was happening is that despite the fact that is claimed to be supported the authentication engine was not regenerating the incoming `ClaimsIdentity` when dealing with `SignalR` requests. What was really strange, as you may notice from the screenshot, is that the APS.Net authentication cookie is available in the incoming request. So something else was preventing the `ClaimsIdentity` to be created.

### Surprise.

With great surprise, after reading hundreds of SO questions and blog posts talking about `SignalR` authentication support, most of them suggesting that the only solution is to move a Bearer Token based authentication, I discovered, by accident, that the solution was as easy as:

![Correct statrtup configuration](/img/the-case-of-broken-signalr-authentication/correct-startup-config.png =450x)

Simply, at OWIN configuration time, be sure to configure `SignalR` after the authentication configuration. Once done the `SignalR` incoming request principal is populated as expected:

![Valid identity](/img/the-case-of-broken-signalr-authentication/valid-claims-identity.png =450x)

Not funny.

