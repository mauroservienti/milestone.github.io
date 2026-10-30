---
layout: post
title: "Radical goes cross-platform: Radical for Avalonia"
author: Mauro Servienti
synopsis: "Radical, the MVVM and UI composition framework for WPF, has always been Windows only. Not anymore. Meet Radical for Avalonia: the same API, running on Windows, macOS, Linux, mobile, and the browser."
header_image: /img/posts/radical-for-avalonia/header.jpg
tags:
- radical
- development
- ui-composition
---

The last time I wrote about Radical on this blog was in 2015, for the [Democracy release](https://milestone.topics.it/2015/06/10/radical-democracy-release.html). That's a long time ago. Radical is still here, though, and it's about to leave home.

[Radical](https://github.com/RadicalFx/Radical.Windows) is an infrastructure framework to build composite WPF applications based on the Model-View-ViewModel pattern. It comes with:

- conventions to bind views and view models;
- a message broker;
- UI composition through regions;
- change tracking with undo and redo;
- validation;
- a set of behaviors that make XAML development less painful.

All of that comes with a constraint: WPF runs on Windows only.

[Avalonia](https://avaloniaui.net/) removes that constraint. It's a XAML-based UI framework, close enough to WPF to feel at home. It runs on Windows, macOS, and Linux, and, with single-view applications, on mobile and in the browser. It was the natural candidate to take Radical beyond Windows.

Meet [Radical.Avalonia](https://github.com/RadicalFx/Radical.Avalonia).

## The same Radical, a different UI framework

Radical.Avalonia is the Avalonia counterpart of Radical.Windows. It targets Avalonia 12 and mirrors the Radical.Windows API, using the `Radical.Avalonia` root namespace instead of `Radical.Windows`. Concepts, conventions, and most of the code carry over. Moving an application from WPF to Avalonia should be mostly a matter of changing `using` directives and XAML namespaces.

Booting an application is a single line of code, as it is with WPF. The only difference is where the line goes. Avalonia applications initialize in `OnFrameworkInitializationCompleted` rather than in the `App` constructor, like the following:

```csharp
public partial class App : Application
{
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        this.AddRadicalApplication<Presentation.MainView>();

        base.OnFrameworkInitializationCompleted();
    }
}
```

When the application starts, Radical wires the default services into the container and resolves `MainView`. It then uses conventions to find `MainViewModel`, sets it as the view `DataContext`, and shows the view. Exactly as it happens with WPF.

There's a catch, though. Avalonia compiles bindings by default, and compiled bindings need to know the data context type at compile time. Conventions set the view model at runtime, so views declare it using `x:DataType`:

```xml
<Window xmlns="https://github.com/avaloniaui"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:vm="using:MyApp.Presentation"
        x:Class="MyApp.Presentation.MainView"
        x:DataType="vm:MainViewModel">
    <TextBlock Text="{Binding Title}" />
</Window>
```

The generic host is supported too. The `AddRadicalApplication` extension method is available on `IHostBuilder`, so the container can be any container the generic host supports, for example, Autofac.

## Where's the window?

With WPF, the shell is a window. With Avalonia, it depends on the platform. On desktop, the shell is shown in a window. On single-view platforms, mobile and browser, there are no windows, and the shell is the application main view.

That's why Radical.Avalonia allows any control to be the shell. A `Window` shell works on desktop only. A `UserControl` shell, instead, works everywhere: on desktop, Radical hosts it in a new window, and on single-view platforms, it becomes the main view.

The same applies to the splash screen. The default splash screen view is a `UserControl`. On desktop, it's hosted in a window. On single-view platforms, it's the main view until the shell replaces it.

## What's different?

Avalonia is close to WPF, but it's not WPF. Most differences come from Avalonia itself, and Radical.Avalonia follows Avalonia's lead rather than trying to hide them. Some examples:

- Avalonia has no `Visibility` enumeration. Elements have a boolean `IsVisible` property instead. The visibility converters keep their names and parameters, but produce `bool`.
- `ModifierKeys` becomes `KeyModifiers`. There are no routed commands, so command gestures work with `DelegateCommand` only.
- Behaviors are built on top of [Xaml.Behaviors for Avalonia](https://github.com/wieslawsoltes/Xaml.Behaviors), the counterpart of `Microsoft.Xaml.Behaviors.Wpf`.
- Drag and drop relies on the Avalonia `IDataTransfer`. Drag and drop command arguments expose `GetData` to retrieve the dragged objects.
- Avalonia raises `Loaded` on windows when they're created, not when they're shown. Radical raises the view loaded notifications for windows when they're opened.

A few features aren't available. Some make no sense in Avalonia: the multithreading busy indicator, for instance, since Avalonia has a single UI thread. Others lack the underlying infrastructure, like custom pixel shader effects or `ICollectionView`. The [migration guide](https://github.com/RadicalFx/documentation/blob/master/docs/avalonia/migrating-from-radical-windows.md) has the complete list, with the alternatives.

`EntityView` deserves a mention. It relies on custom type descriptors to expose custom properties to data grids. Neither Avalonia bindings nor the Avalonia `DataGrid` support them. How to bring that functionality to Avalonia is still an [open question](https://github.com/RadicalFx/Radical.Avalonia/issues/21).

## Reworking the samples

The [documentation repository](https://github.com/RadicalFx/documentation) has always come with samples. Most of them lived in a single "showcase" application: a WPF shell listing the showcases on the left and loading the selected one in a region on the right. Clever? Yes. A good sample? Not really. To understand a feature, you had to dig into the showcase infrastructure first.

Adding Avalonia was the right moment to change that. Now, each sample is a folder containing a standalone application focused on a single feature. The WPF version lives in the `Wpf` folder and the Avalonia version in the `Avalonia` folder, side by side:

```text
samples/
  focus/
    Wpf/FocusSample.Wpf.csproj
    Avalonia/FocusSample.Avalonia.csproj
  tab-control-region/
    Wpf/...
    Avalonia/...
```

The showcase application turned into 17 separate applications. The splash screen content it used became a dedicated splash screen sample. The existing standalone samples, such as modules, plugins, and the generic host integration, moved to the new layout. All WPF samples are part of the `Samples.Wpf.slnx` solution, all Avalonia ones of `Samples.Avalonia.slnx`, and CI builds both.

Out of 23 samples, 19 have an Avalonia version. The grayscale effect sample doesn't, because Avalonia has no custom pixel shader effects. Neither do the samples depending on `EntityView`, for the reason mentioned above. The [samples reference page](https://github.com/RadicalFx/documentation/blob/master/docs/samples.md) lists all of them, with the related documentation and whether there is an Avalonia version, and if not, why.

## Samples are tests too

Porting the samples wasn't only about translating XAML. Running them surfaced a bug.

Once ported, the generic host sample crashed with a stack overflow when closing the application. The sample uses the documented pattern, which stops the host when the application exits:

```csharp
desktop.Exit += async (s, e) =>
{
    using (host)
    {
        await host.StopAsync();
    }
};
```

Stopping the host shuts down the Radical application, which, in turn, shuts down the application lifetime. With WPF, that's harmless: calling `Shutdown` while the application is already shutting down does nothing. The Avalonia desktop lifetime, instead, raises `Exit` every time it's shut down, even while it's already exiting. `Exit` stops the host, which shuts down the lifetime, which raises `Exit`, and so on, until the stack gives up.

Same code, same API, different semantics. That's precisely the kind of difference that mirroring an API can't hide, and that shows up only when running something real. The fix is in [`1.0.0-alpha.2`](https://github.com/RadicalFx/Radical.Avalonia/releases/tag/1.0.0-alpha.2): when the lifetime is already exiting, stopping the host no longer shuts it down again.

## What about the documentation?

The [Radical documentation](https://docs.radicalframework.com/) has a new section dedicated to Avalonia:

- [Radical for Avalonia](https://github.com/RadicalFx/documentation/blob/master/docs/avalonia/README.md) covers how to bootstrap an application, compiled bindings, desktop and single-view platforms, and the generic host.
- [Migrating from Radical.Windows](https://github.com/RadicalFx/documentation/blob/master/docs/avalonia/migrating-from-radical-windows.md) lists, area by area, where the API or the behavior differs and what isn't available.
- The [samples page](https://github.com/RadicalFx/documentation/blob/master/docs/samples.md) makes the samples discoverable from the documentation itself.

The rest of the documentation applies to both WPF and Avalonia. Code snippets use WPF, and the migration guide covers what changes.

## How do I try it?

Radical.Avalonia is in alpha. Pre-releases are available on the Radical pre-releases feed on Feedz.io. Add it to a `nuget.config` file like the following:

```xml
<configuration>
  <packageSources>
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
    <add key="Radical pre-releases" value="https://f.feedz.io/radical-framework/pre-releases/nuget/index.json" />
  </packageSources>
</configuration>
```

Then, add a reference to the `Radical.Avalonia` package, or start from one of the Avalonia samples.

## Conclusion

Radical.Avalonia brings the same API, the same conventions, and the same way of building composite applications to every platform Avalonia runs on. Not everything carries over, and some things behave differently. The migration guide is there for that, and the samples show both versions side by side.

There's still work to do before a stable release: the [`DataGrid` behaviors](https://github.com/RadicalFx/Radical.Avalonia/issues/19) and the [`EntityView` and `ICollectionView` story](https://github.com/RadicalFx/Radical.Avalonia/issues/21), to name a couple. If you give it a try, [feedback and issues](https://github.com/RadicalFx/Radical.Avalonia/issues) are very welcome.

Radical has spent its whole life on Windows. It's about time it saw the rest of the world.

---

Photo by <a href="https://unsplash.com/@crisdinoto?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Cris DiNoto</a> on <a href="https://unsplash.com/photos/black-red-and-purple-digital-wallpaper-90TuupZZZkU?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
