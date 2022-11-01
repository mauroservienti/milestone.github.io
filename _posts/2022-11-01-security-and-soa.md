---
layout: post
title: "What is the deal with security and distributed systems?"
author: Mauro Servienti
synopsis: "Security is a crucial topic for any architect. We cannot implement it as a second thought. We must consider its implications from day one. Distributed systems are no different. However, it might be a little more involved."
enable_mermaid: true
header_image: /img/posts/security-and-soa/header.jpg
tags:
- soa
- distributed-systems
- security
---

If a system is composed of [autonomous components](https://milestone.topics.it/2022/09/05/autonomy.html), how can we guarantee the consistency imposed by security requirements?

For example, one common requirement might be formulated as follows: whenever an account is disabled or terminated, system access must be immediately blocked.

That usually raises the question, "if components are autonomous, how can the Security service impose behaviors without generating coupling?"

My answer usually starts with "Security is not a service."

## Wait, what?

Security, as a term, is too generic in this context. At least, we want to distinguish between authentication, authorization, and users & rights management. Here is a quick recap of what they are:

- Authentication verifies that the account trying to access the system is who they claim to be. For example, credentials verification is a form of authentication. Another one is biometric checks.
- Authorization verifies that users can do what they are trying to do. For example, can the current user visualize a specific resource?
- Users & Rights management is the set of processes related to managing user accounts and what they can do in the system — for example, roles assignment.

Users & rights management is a good candidate for being a service. It's a set of processes well isolated from other services. It comes with its policies, and it's unlikely there is a need to couple it with other components in the system.

Authentication is two-fold. On the one hand, it is one of the Users & Rights management components. Unauthenticated users accessing the system will be redirected to the authentication component to validate their credentials. The component will query the Users & Rights management storage to check credentials or use the configured technology to authenticate them. Upon successful validation, users receive an authentication token they can spend when accessing other services.

Accessing services is the second fold. Each service needs to validate the issued security token. That might sound like a source of coupling: an autonomous service all of a sudden needs to communicate somehow with another service to be able to proceed.

## It's a false alarm

Users & Rights management can deploy a token validation component to all services that need to validate security tokens. For example, the token validation component can be an [ASP.Net Core Middleware](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/middleware/?view=aspnetcore-6.0). Whenever a service receives a request, the security token validation middleware extracts the token from the request and makes sure it's valid. The hosting service will be unaware of the additional component, and there will be no coupling.

If the token validation component needs to talk back to the Users & Rights management service to gather more information, it might create some temporal coupling. Usually, that's different. Security tokens are self-contained. However, one of the requirements might be that whenever a user account gets suspended or deleted, the system must prevent users from doing any further action. In such a scenario, the token validation component might need to go back to Users & Rights management to evaluate users' status.

It is neither an architectural nor a technical concern. It's a business one.

Let me present a more nuanced example before diving into why it's a business concern. Roles, or Groups, get assigned to users to simplify permissions management. It's easier to say that all users of the Publishers role can publish and edit rather than setting the Publish and Edit permissions to each user.

If the system uses Roles, we need to validate them whenever users attempt any operation: A user tries to do something, the system validates that they belong to a specific Role allowing that request.

Similarly to tokens, roles might be self-contained in the token itself. For example, [.NET principals](https://learn.microsoft.com/en-us/dotnet/standard/security/principal-and-identity-objects), to be more precise, the Claim Principal, encapsulates roles in the form of claims. If the token is valid, another component can be responsible for extracting claims and presenting them to services for further usage.

That poses some concerns. It creates some form of coupling between the business service that requires authorization and the security component that extracts claims from the token. There is little we can do about it: claims extraction is orthogonal to business services. It's a layer on top of every service. It's similar to logging. Due to security requirements, it presents itself as a mandatory infrastructure we must cope with.

More coupling might surface if claims must be consistent. If we limit ourselves to extracting claims from the token, it might happen that someone else assigned a different set of roles to the user by the time a service checks them. If the business demands consistency, our only option becomes introducing some temporal coupling. The requirement forces us to refresh claims, thus assigned Roles or Groups, at every user request to guarantee that the system always uses the most up-to-date information.

## Is that an issue?

You bet it is. We now have a single point of failure. But again, it's primarily a business-caused issue. The business requirements force us in that direction. There is only so much we can do about it other than focusing on scaling out the active components and doing our best to provide high availability. In the end, it's what the business wants. A requirement such as the above states that the business favors a non-functioning system over a potentially insecure one.

## It's not all, folks: tokens expire!

So far, it went without saying that authentication and authorization happen at the system's outer boundaries. For example, web application front-ends validate authentication tokens and verify Roles. That implies a message sent on a queue by a front-end to a back-end service flies into the system unauthenticated.

That is primarily because security tokens expire (for good reasons). For example, the Kerberos token lifetime is five minutes (IIRC). Active directory users need a new, freshly generated token every five minutes.

Token expiration works for and against us at the same time. A token lifetime is a few minutes or more, which makes it behave like a cache. It helps in reducing the single point of failure issue highlighted above. If requirements allow, we can rely on the token "cache" to avoid going back to authentication and authorization components every time.

Expiration also works against us. Take a look at the following scenario:

<div class="mermaid">
graph TB
    C[Client] -->|HTTP + auth-token| FE[Front-end]
    FE -->|message + auth-token| Q[Queue]
    Q -->|message + auth-token| BE[Back-end]
    BE -->|HTTP + auth-token| TP[Third-party API]
</div>

The above diagram shows a front-end application accepting authenticated requests and sending a message via a queue to a back-end component. The back-end component needs to invoke a remote third-party HTTP endpoint, and the requirement is that the back-end component presents itself as the original user that issued the HTTP request to the front end.

The security token can expire while in flight. In-flight messages are messages traveling to the destination endpoint or picked up for processing but still need to be completed. The message processing will inevitably fail if the token expires before any opportunity to refresh it. A similar scenario is when the token is valid upon receiving the message. Still, processing fails for a different reason, and the message ends up in the [error queue](https://milestone.topics.it/2013/05/nservicebus-error-queues.html) (it's a post from 2013! Pardon my English). It's unavoidable that associated tokens will expire and cannot be refreshed, making it impossible to retry those messages.

## Conclusion

What do we do then? There isn't an easy answer. There are mostly questions.

One option is not to propagate security tokens using messages. The message sender appends the user's principal identifier to outgoing messages and signs the message. A receiver can validate the signature, determine that the message has not been tampered with, and trust the incoming principal. However, we need some form of delegation to solve the above-presented third-party API scenario. I know it horrifies you as much as it terrifies me. There's a reason why I'm not a security guy ;-)

I suggest always involving a security expert and presenting them with the above challenges. We need to agree on some compromises to overcome the presented issues.

---

Photo by <a href="https://unsplash.com/@bernardhermant?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Bernard Hermant</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
