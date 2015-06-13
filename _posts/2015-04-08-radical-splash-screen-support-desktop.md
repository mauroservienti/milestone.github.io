---
layout: post
title: "Radical Splash-Screen support for desktop apps"
date: '2015-04-08T12:32:00.000+01:00'
author: Mauro Servienti
tags:
- Radical
blogger_orig_url: http://milestone.topics.it/2015/04/radical-splash-screen-support-for.html
---

Take a look at the following snippet:

```csharp
public App()
{
    var bootstrapper = new WindsorApplicationBoostrapper<Presentation.MainView>()
             .EnableSplashScreen( new SplashScreenConfiguration()
             {
                 StartupAsyncWork = c => 
                 {
                     //async work while the splash screen is shown.
                 }
             } );
}
```

It is not available yet, it is a [feature we are working](https://github.com/RadicalFx/radical/issues/50) on that leverages the intrinsic power of [partial regions](https://github.com/RadicalFx/radical/wiki/UI-Composition#automatic-aka-partial-regions): it is enough to call the `EnableSplashScreen()` method (the configuration is optional) and define a partial named "`SplashScreenContent`", the partial user control will be automatically wired up at start-up and used as the splash screen content.
 
If you have any idea or comment [chime in](https://github.com/RadicalFx/radical/issues/50).

.m