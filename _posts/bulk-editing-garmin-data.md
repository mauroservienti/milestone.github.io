---
layout: post
author: Mauro Servienti
title: "They'll probably make it anyway: bulk editing Garmin data"
synopsis: "Users have needs. They want to get things done when using software. If what they have is not satisfactory, they'll get creative."
header_image: /img/posts/bulk-editing-garmin-data/header.jpg
tags:
- personal
---

I'm a Garmin user, as I said [multiple times](https://milestone.topics.it/tags/personal.html). To track and navigate during outdoor bike rides, I use a Garmin Edge 830. When the weather is terrible, I ride indoor using an old bike and an Elite Suito trainer. My friend [Sandro](https://www.rizzetto.com/), who lives in a beautiful area, makes fun of me. Take a look at [some of his photos in the gallery](https://www.rizzetto.com/photo/default.aspx)...he has a point!

Enough talking! Garmin Connect, the application used to review all the stats collected by Garmin devices, offers a nice Gears feature. It is a database of all the gear someone uses during sports activities. For example, equipment like running shoes or bikes are defined in the Gears database and later associated with performed activities. When adding gears, we can specify one of them as the default that Garmin will automatically use for future activities.

Bike riding is my primary activity alongside swimming, and the default gear is my road bike. The issue is that when I'm training indoor using the trainer, activities get associated with the road bike. Garmin should introduce a feature that allows associating default gears to activity types instead of having a generic default gear for every activity. Searching through Garmin public forums, the feature has quite a few requests. The oldest I've found is from 2017. That only confirms that Garmin is sort of deaf to users' feedback.

Let's imagine for a second that it's an incredibly complex feature. In the end, I have no idea what the data and services structure is behind the scene. It could be that it's hard to implement.

A less user-friendly option would enable users to bulk edit recorded activities. It's less user-friendly because it's a technical concept. Non-techies hardly think about bulk editing something. Anyway, it would be a good enough compromise. But no, there is no way to select many activities and change the associated gears in bulk.

At this point, the dormant engineer in me wakes up and states you can write software to solve the problem, Mauro.

We know that writing software usually opens a can of worms, but it's indeed fun!

Garmin has a developer program, which is a sort of no-go because it requires an enrollment process, and there is a far easier solution! They have a public API used by the website and apps. The problem is, how do I authenticate? There is no authentication API, well, there is, but it requires going through the developer program.

## The browser is the new IDE

It turns out that a brilliant solution is to use the browser console and JavaScript. Once you're logged in to the Garmin Connect website, the browser console runs in the same session. The public API used by their applications is also available to us. The only downside is that there is no documentation.

## Browser tools to the rescue

We can use the browser tools network tab to investigate the API calls Garmin Connect issues when talking to the backend and reverse engineer what we can use to solve our problem.

## Requirments

We need to change the automatically assigned gear for a specific subset of the recorded activities. The first thing is to list activities for particular gear. Once we have the desired activities, we want to filter out all not virtual training activities.

> We could be in a situation where today we're doing a virtual bike ride on the trainer, tomorrow a real bike ride outdoor, and the day after another virtual bike ride. We want to bulk edit gears only for the virtual bike rides.

Finally, we need to remove the pre-assigned gear and assign the trainer.

We can achieve the desired outcome by using the following code:

```javascript
jQuery.getJSON(
    '/modern/proxy/activitylist-service/activities/{gear-id}/gear?start=1&limit=25',
    function(gear_activities){
        var virtualRides = gear_activities.filter(function(act){
                return act.activityType.typeKey == "virtual_ride";
            });

        if(virtualRides.length == 0){
            return;
        }

        virtualRides.forEach(function(act){
            //unlink
            fetch('/modern/proxy/gear-service/gear/unlink/{gear-id}/activity/' + act['activityId'],
            {
                'headers': { 'Content-Type': 'application/json', 'nk': 'NT', 'X-HTTP-Method-Override': 'PUT' },
                'method': 'POST'
            });    

            //link
            fetch('/modern/proxy/gear-service/gear/link/{gear-id}/activity/' + act['activityId'],
            {
                'headers': { 'Content-Type': 'application/json', 'nk': 'NT', 'X-HTTP-Method-Override': 'PUT' },
                'method': 'POST'
            });
        });
    });
```

It's not that complex. We first retrieve a few activities:

```javascript
jQuery.getJSON(
    '/modern/proxy/activitylist-service/activities/{gear-id}/gear?start=1&limit=25',
```

The above snippet retrieves the top 25 activities for a given gear.

> Your mileage may vary with the 25 items limit. I run the above script more or less every couple of weeks. The query returns activities ordered by date, with the latest on top. I assume that there is no way I can record more than 25 activities for a specific gear in two weeks.

The next step is to filter to get only virtual activities:

```javascript
var virtualRides = gear_activities.filter(function(act){
   return act.activityType.typeKey == "virtual_ride";
});

if(virtualRides.length == 0){
   return;
}
```

If there are no virtual activities, we end prematurely. Finally, the script iterates over all the virtual activities, removes the incorrectly assigned gear, and assigns the desired one:

```javascript
virtualRides.forEach(function(act){
   //unlink
   fetch('/modern/proxy/gear-service/gear/unlink/{gear-id}/activity/' + act['activityId'],
   {
       'headers': { 'Content-Type': 'application/json', 'nk': 'NT', 'X-HTTP-Method-Override': 'PUT' },
       'method': 'POST'
    });    

     //link
     fetch('/modern/proxy/gear-service/gear/link/{gear-id}/activity/' + act['activityId'],
     {
        'headers': { 'Content-Type': 'application/json', 'nk': 'NT', 'X-HTTP-Method-Override': 'PUT' },
        'method': 'POST'
});
```

> Disclaimer: It's not my work. I limited myself to putting together snippets found on Garmin forums.

## Conclusion

First, if you are a Garmin user and need to bulk edit data, the presented solution might work out of the box or be adjusted to your needs.

Second, and probably more important, don't assume users won't get creative. Using our software solution, they'll find ways to achieve what they need, even if we did not intend to allow that functionality.

You might remember Usenet networks used to share illegal and cracked software. And users write scripts to split packages in chunks before posting and rebuilding the original package once all messages attachments are downloaded. I'm pretty sure that it wasn't the original intent.

---

Photo by <a href="https://unsplash.com/@dragos126?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Dragos Gontariu</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
