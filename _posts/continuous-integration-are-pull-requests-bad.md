---
layout: post
header_image: /img/posts/continuous-integration-are-pull-requests-bad/header.jpg
title: "Continuous integration: are pull requests bad?"
author: Mauro Servienti
synopsis: "There are continuous integration advocates and pull requests evangelists. They both present valid arguments to sustain their thesis. Is there a different point of view we should be considering before choosing one style or the other?"
tags:
- processes
---

Continuous integration (CI) is the practice of continuously pushing code changes to the mainline instead of the established or accepted practice of going through pull requests. CI supporters assume that pull requests slow you down because the review process implies too much waiting time. When waiting time is too much, the assumption is that the people waiting for the code review will shift their attention to something else, first context switch issue, and when the review requested changes come in, they can go back to the pull request to fix them, second context switch issue. The conclusion is that pull requests are bad because they lead to too much context switching.

> Source: https://infrastructure-as-code.com/book/2021/01/02/pull-requests.html

It might be the case in specific scenarios for sure, but I generally find it hard to point my finger at pull requests as the root cause of the problem. The practice of using pull requests can be for sure something that nudges in the direction of accepting long-wait time in reviews, but I fail to see the causation. If any, it's probably the other way around. When the organization structure pushes in the direction of code reviews that take a long time and is performed by a different group of people than the one committing the code, the only way to go through this frustrating process is through pull requests and the accompanying context switch. In fact, in most scenarios, this group is referred to as the committee. If this is the case, can we say that pull requests are the culprit? In essence, look for the cause, not the symptoms.

I also feel that using the context switching argument as the main problem is a weak argument. It seems to assume that a development team is doing one thing at a time, and thus while waiting for a pull request review, the team has to find something else to do and switch the context. In any organization, many things can slow down anyone; Being assigned to more than one task at a time is a well-known and established practice that helps fill any slack time caused by interruptions in the flow. I also find it hard to believe that once the pull request is ready, a development team has nothing else to do in the same context or for the same task, like documentation. The group can easily organize themselves to fill the waiting time caused by the pull request review.

However, let's assume that it's impossible.

## Poka-yokes

Pull requests and the inherent need for reviews are a [poka-yoke](https://seths.blog/2021/11/in-search-of-poka-yokes/), and as such, we should treat them.

If the above assumption that a team is not doing one thing is correct, what if the group was responsible for its reviews? Different team members could be cross-reviewing their pull requests.

While a subset of the team works on some documentation, they could review the changes related to the feature they are documenting. Those code changes are applied by a different group of people in the same team. Similarly, if a portion of the team is changing the frontend, the other group, updating the backend code, could be requested as reviewers.

With this minor change to the organization, teams become autonomous. They are fully empowered to make and push changes without needing an external committee that reviews the requested changes.

## Is it a minor change?

I guess it's not. It sounds trivial, but it implies a not-so-minor thing such as the need for trust: if an organization sets up an external committee, it sounds like a lack of trust in teams. No matter what development flow they are using, a gatekeeper needs to validate their changes. Hence the construction of overarching structures such as mandatory pull requests reviews or an external committee.

## Conclusion

Do we need pull requests? No. If teams are empowered and trusted, they could be choosing whatever development style they want. A team might prefer to push to the main branch and review commits there. Another group might favor pull requests and cross reviews before merging.

As with many problems, if not all, it's important not to stop at the surface and immediately jump the solution. Instead, deeply investigate the issue looking for its root cause, and try to improve the situation from there.

---
