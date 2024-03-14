---
layout: post
author: Mauro Servienti
title: ".NET development on Apple Silicon"
synopsis: "I bought a MacStudio, I've been a long-time Windows user, and I'm a .NET developer. What could go wrong? Let's find out how my experience goes in this live-blogging session."

header_image: /img/posts/dotnet-development-on-apple-silicon/header.jpg
tags:
- development
---

_TL;DR_

_Apple Silicon devices are great. My MacStudio is powerful, and I have difficulty using all the available resources. The machine, for most of the workloads, is simply outstanding. The scenario for .NET development is twofold. On the one hand, .NET 6 (and onward) development works excellently on macOS and Apple Silicon. I'm a JetBrains Rider user; however, both Visual Studio Code and Visual Studio for Mac work great._

_On the other hand, there is .NET Framework development. It requires a virtual machine, and I have a Parallels one. The virtual machine OS must be ARM which poses a set of limitations to developers—most of the .NET development tools for Windows don't play nicely with an ARM architecture. Currently, the best option is to use Visual Studio 2022 Preview 2 (and onward), which comes with ARM support, and update the target framework to .NET 4.8.1. If that's not possible, get ready to spend time troubleshooting subtle errors._

I've used a Dell Precision Tower 5810 workstation (8-core Xeon, 32GB of RAM, and 1TB SSD) for the last seven years, and Windows has been my primary OS for most of my career. I had an experience with macOS for a couple of years, around 2010.

I recently (April 2022) bought a MacStudio (M1 Ultra, 64GB of RAM, 1TB SSD).

This post intends to be a live blog, sharing my experience as a long-time Windows user and, more importantly, a .NET developer. I started with .NET development in 1999 with one of the first alpha releases.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Let’s get started 😬 <a href="https://t.co/K55bOMQojn">pic.twitter.com/K55bOMQojn</a></p>&mdash; Mauro Servienti 🐙 (@mauroservienti) <a href="https://twitter.com/mauroservienti/status/1511755988453498881?ref_src=twsrc%5Etfw">April 6, 2022</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

<!-- let's get started -->

Before getting into the nitty-gritty details of .NET development using an M1 chip and macOS, let me give you an overview of the hardware. I'm famous among my friends and colleagues for my diplomacy.

The MacStudio built-in audio quality is shit. I had never heard something so utterly inadequate. I should have expected it. During the presentation, Apple never mentioned the audio using their usual style, "The best XYZ feature of all times." And so, there we go. Even for regular Zoom calls, you need external speakers or headphones.

Having six Thunderbolt ports on my model (four in the back and two in the front) is a huge bonus. Plugging in devices has never been so easy. Except if you want to plug in not-officially-supported USB-C screens.

I have two Dell 32" 4K screens (U3219Q) that claim to support DisplayPort over the USB-C connection. But things are not so easy. I'm not sure why, but external screens and projectors are almost always a source of pain with Apple machines.

The problem manifests itself at boot time. The screen is in standby mode, the machine starts, the screen wakes up and starts the USB-C handshaking process. But that happens too early, and the response from the Mac times out. The screen never retries and never connects. The "easy" workaround is disconnecting and reconnecting the USB-C cable, and the screen immediately starts working. However, if you're using the screen as a USB hub, that causes a mess with USB devices connected to the screen. Dell forums are full of people complaining about this issue, so it's not something new to the MacStudio, and it's not easy to understand who to blame. Anyway, the definitive solution is to use a USB-C to DisplayPort cable. No more problems. The downside is that to use the screens as a USB hub, I had to connect them using the USB-A cable, which is fine because the MacStudio has two ports.

Enough talking about the hardware.

## 2022-04-15 - One week into using macOS and an M1 for .NET Development.

Let's start with the easy stuff. [JetBrains Rider](https://www.jetbrains.com/rider/) is a joy. .NET 6, runtime and SDK, [are supported on ARM64](https://dotnet.microsoft.com/en-us/download/dotnet/6.0). We can build and execute all .NET projects targeting .NET, including .NET Core. Obviously, except for WPF and Windows Forms projects. They require Windows anyway.


We can install .NET Core 3.1. There is support only for the [x64 version](https://dotnet.microsoft.com/en-us/download/dotnet/3.1). It's not a big deal since it goes out of support soon.

Last but not least, [VS Code](https://code.visualstudio.com) works great. Its support for [dockerized environments](https://milestone.topics.it/2021/06/11/visual-studio-code-remote-containers.html) comes in handy.

### Windows virtualization using Parallels

For everything else .NET Framework-related, we need a virtual machine or some way to use Windows. Forget about Bootcamp. It doesn't exist and probably won't ever exist for ARM.

I installed the trial version of [Parallels](https://www.parallels.com/it/products/desktop/trial/). One caveat for using virtual machines on ARM hosts is that the virtualized operating system needs to be for ARM64. That might open issues in virtualizing Windows because there is an [agreement between Microsoft and Qualcomm](https://www.theverge.com/2021/11/23/22798231/microsoft-qualcomm-exclusivity-deal-windows-on-arm) that might affect our ability to license Windows for ARM on non-Qualcomm hardware.

That being said, Parallels does an excellent job. Once installed, the virtual machine creation wizard asks a few questions. The first one is what operating system we need. When I selected Windows 11, it automatically downloaded the required ISO and started the installation. It took a minute, or a little more, to install Windows 11 for ARM.

Windows 11 for ARM, executed in Parallels, is incredibly fast. When used on full screen, it's hard to perceive that it's a virtual machine.

Before developing, a couple of words about regular, non-development-related applications. I read here and there people complaining about poor performance. For the sake of the experiment, I installed [Adobe Photoshop Elements](https://www.adobe.com/products/photoshop-elements.html) using the 2012 bits, that's the license I own, and [Audacity](https://www.audacityteam.org/). Both are x64 applications that, at runtime, will go through the x64 to ARM emulation. No issues so far; they work. And they are as fast as they were on my Intel Xeon workstation.

#### Development tools on Windows for ARM

Visual Studio 2022 is not supported. The installation works fine, and like for other applications, Visual Studio runs smoothly. It's a bit slower than on my previous workstation, and it's not that it was stellar fast before. All in all, JetBrains Rider was still providing a better experience (except for the application's first startup time).

The only way to install .NET Framework developer packs was to [manually download the needed installers](https://dotnet.microsoft.com/en-us/download/visual-studio-sdks) instead of the Visual Studio Installer. The Visual Studio Installer installs them, but then Visual Studio complains they are unavailable.

I tried compiling a couple of solutions, intentionally selecting challenging ones. It worked, and the tests were green, too.

All .NET 6 projects, as expected, compile and run fine.

One last note: .NET 3.1 is tricky. As said, it comes only with x64 support. Visual Studio asks to install it:

![Visual Studio screenshot](/img/posts/dotnet-development-on-apple-silicon/vs-screenshot.png){:class="img-fluid mx-auto d-block"}

Based on my experience with the developers' pack, I downloaded the SDK installer. It fails. The error is that ARM is not a supported platform, which is interesting because we can install the same x64 SDK on the M1 Mac. The .NET Core 3.1 SDK installs fine using the Visual Studio Installer. But then I started getting all sorts of weird errors from Visual Studio. I suppose a lot of the Visual Studio tooling depends on .NET Core that tries to load other assemblies compiled for ARM, causing many operations to fail. Removing .NET Core 3.1 solved my problems. I assume that Visual Studio uses the latest runtime, .NET 6, in my case, if the expected one is not available. I have no idea how many latent problems are waiting for me around the corner.

## 2022-06-27 — A couple of months into using macOS and an M1 for .NET Development

The following section is only about .NET development, specifically WPF, using the Parallels Windows for ARM virtual machine. I have no issues with .NET 6 or .NET 7 development using macOS. Everything  I need works as expected.

Visual Studio 2022 is extremely slow when developing WPF code, regardless of editing XAML files or regular C# ones when using the Windows for ARM virtual machine. JetBrains Rider helps a lot. It's much more performant and an excellent Visual Studio replacement for most workloads.


There is no way, or at least no way I know to debug WPF applications using Visual Studio 2022. The application starts, the debugger is attached, and the WPF LivePreview tools work as expected. However, no breakpoint is hit. All of them show as disabled with the "no symbols loaded" error. Again, debugging works flawlessly in JetBrains Rider.


Microsoft recently released the [Visual Studio 2022 Preview 2 for ARM](https://devblogs.microsoft.com/visualstudio/arm64-visual-studio/). It's a game-changer. It's fast, faster than JetBrains Rider, and despite being the first preview, it's pretty stable. I have had no issues so far. Breakpoints don't work, though. I have a feeling that the culprit is the target framework. The application I'm working on targets .NET 4.8, which doesn't come with ARM support. There will be a .NET 4.8.1 targeting the ARM platform, which probably also addresses the debugging issue I'm facing.

## 2022-09-19 — .NET Framework development is a PITA, I'm ready to give up

A remark: I probably spent 30% of my time writing code in my current role. In the vast majority of the cases, the development stack is C# and .NET 6. It doesn't need Windows and works flawlessly on macOS using the excellent JetBrains Rider.

If the project multi-targets .NET and .NET Framework, and you know what to do (e.g., there is no need for full IntelliSense support to detect that a member is unavailable in one of the targeted frameworks), then macOS is again more than enough. The production build artifacts are a CI concern.

I recently upgraded Visual Studio 2022 for ARM to the latest preview bits, and none of the test-related things work. That effectively breaks .NET Framework development using the Windows for ARM virtual machine. I created an Azure virtual machine and use that for the few .NET Framework development needs I still have.

I will check if newer Visual Studio bits improve the situation from time to time, but that's a dead end for now.

## 2024-02 — .NET development is excellent, but not all that glitters is gold. One thing bothers me a lot: Uninstallations!

JetBrains Rider, .NET 6, .NET 7, and the recent .NET 8 are great. .NET development on macOS (and Linux, for what it matters) is a first-class citizen. Finally!

I don't miss Windows at all. Being it general-purpose usage or development, my experience with macOS has been superior so far.

If there is one thing I want to complain about, it is the experience of uninstalling .NET SDKs and Runtimes, particularly previews.

The essence of the story is that you're left groping in the dark. On Windows, we use MSI packages to perform the installation and uninstallation. On macOS, there are installers, but there are no uninstallers.

Microsoft offers a `dotnet-core-uninstall` command line utility for all the supported operating systems—more details in the [official documentation](https://learn.microsoft.com/en-us/dotnet/core/additional-tools/uninstall-tool). The problem is that the tool is in maintenance mode, according to [this GitHub comment](https://github.com/dotnet/cli-lab/issues/160#issuecomment-871729221), and thus it cannot uninstall anything newer than .NET 6. Weird, to say the least.

![dotnet-core-uninstall output](/img/posts/dotnet-development-on-apple-silicon/dotnet-uninstall-list-output.png){:class="img-fluid mx-auto d-block"}

.NET is available through [Home Brew](https://formulae.brew.sh/formula/dotnet), which would be perfect if there were preview bits. Also, it was outdated when I looked at it a while back.

Continuing my quest, I then found a [script that supposedly allows uninstalling .NET](https://github.com/MicrosoftDocs/visualstudio-docs/blob/main/mac/uninstall-net-2022.md):

```bash
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/dotnet/sdk/main/scripts/obtain/uninstall/dotnet-uninstall-pkgs.sh)"
sudo rm -r /etc/dotnet
```

In fine print, the caveat is that it removes all the installed versions. Useful...weird.

Finally, a [good article describing how to remove .NET installations manually](https://devkimchi.com/2021/11/24/removing-dotnet-sdks-from-macos-manually/) and [Dots](https://github.com/nor0x/Dots) a handy application for managing .NET installations on macOS.

Dots is still under development; there is space for improvements, but it does what it promises. At the time of this writing, it needs to be manually compiled because the released version is too old. It does the job pretty well:

- Lists installed .NET versions
- Lists available but not installed versions
- Allows to uninstall installed versions
- Allows to install new versions

More important than anything, it supports previews!

To recap. Installing .NET bits on macOS is simple, thanks to the Microsoft-provided packages. The drama starts when we want to remove them. That's particularly painful if, for some reason, we need to deal with .NET preview bits. Without a good uninstall story, we left machines cluttered with junk. Microsoft is no help. [Dots](https://github.com/nor0x/Dots) could be your best friend.

Now the circus starts again with .NET 9 previews, so please save me!

To be continued.

---

Photo by <a href="https://unsplash.com/@markkoenig?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Mark König</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
