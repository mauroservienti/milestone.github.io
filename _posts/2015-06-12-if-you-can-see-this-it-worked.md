---
layout: post
title: "If you can see this, it worked"
author: Mauro Servienti
tags:
- Jekyll
- Scheduling
---
One of the things that [Jekyll](http://jekyllrb.com/) misses is the ability to schedule future posts, but...

### Zapier to the rescue

[Zapier](https://zapier.com) is nice and powerful mesh-up engine that allows you to connect different services, react based on triggers and perform actions.

Here is my blog posts scheduling work-flow:

* create a branch to host the new post;
* write the post in the new branch;
* push the branch to remote;
* create an event in my Google Calendar to schedule the publish:
    * use as `location` the name of the branch;

I finally created in Zapier a trigger for the Google Calendar event that when the event is fired:

* automatically creates a `Pull Request` for the branch defined in the `location` field;
* if there are no merge conflicts immediately merges the PR;

Once the PR is merged into the `master` branch Jekyll automatically kicks in and `compiles` the markdown document and `publishes` it.

The interesting thing of using a calendar to schedule posts is that you can easily move them to a new schedule and cancel the publish simply deleting the appointment in the calendar without affecting the post sitting in the branch. 

.m