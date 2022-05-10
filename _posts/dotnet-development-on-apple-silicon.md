---
layout: post
author: Mauro Servienti
title: ".NET development on Apple Silicon"
synopsis: "I bought a MacStudio, I've been a long-time Windows user, and I'm a .NET developer. What could go wrong? Let's find out how my experience goes in this live-blogging session."

header_image: /img/posts/dotnet-development-on-apple-silicon/header.jpg
tags:
- development
---

I've used a Dell Precision Tower 5810 workstation (8 core Xeon, 32GB of RAM, and 1TB SSD) for the last seven years and Windows as my primary OS for most of my career. I had an experience with macOS for a couple of years around 2010.

I recently (April 2022) bought a MacStudio (M1 Ultra, 64GB of RAM, 1TB SSD).

This post intends to be a live-blogging thing, sharing my experience as a long-time Windows user and, more importantly, a .NET developer. I started with .NET development in 1999 with one of the first alpha releases.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Let’s get started 😬 <a href="https://t.co/K55bOMQojn">pic.twitter.com/K55bOMQojn</a></p>&mdash; Mauro Servienti 🐙 (@mauroservienti) <a href="https://twitter.com/mauroservienti/status/1511755988453498881?ref_src=twsrc%5Etfw">April 6, 2022</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

<!-- let's get started -->

Before getting into the nitty-gritty details of .NET development using an M1 chip and macOS, let me give you an overview of the hardware. I'm famous among my friends and colleagues for my diplomacy.

The MacStudio built-in audio quality is shit. I had never heard something so utterly inadequate. I should have expected it. Apple, during the presentation, never mentioned the audio using their usual style, "The best XYZ feature of all times." And so, there we go. Even for regular Zoom calls, you need external speakers or headphones.

Having a lot of thunderbolt ports, six on my model (four in the back and two on the front), is a huge bonus. Plugging in devices has never been so easy. Except if you want to plug in not-officially-supported USB-C screens.


I have two Dell 32" 4K screens (U3219Q) claiming to support DisplayPort over the USB-C connection. But things are not so easy. I'm not sure why, but it sounds like external screens and projectors are more or less always a source of pain with Apple machines.

The problem manifests itself at boot time. The screen is in standby mode, the machine starts, the screen wakes up and starts the USB-C handshaking process. But that happens too early, and the response from the Mac times out. The screen never retries and never connects. The "easy" workaround is disconnecting and reconnecting the USB-C cable, and the screen immediately starts working. However, if you're using the screen as a USB hub, that causes a mess with USB devices connected to the screen. Dell forums are full of people complaining about this issue, so it's not something new to the MacStudio, and it's not easy to understand who to blame. Anyway, the definitive solution is to use a USB-C to DisplayPort cable. No more problems. The downside is that to use the screens as a USB hub, I had to connect them using the USB-A cable, which is fine because the MacStudio comes with two USB-A ports.


Enough talking about the hardware.

## .NET development

_2022-04-15 - One week into using macOS and an M1 for .NET Development._

Let's start with the easy stuff. [JetBrains Rider](https://www.jetbrains.com/rider/) is a joy. .NET 6, runtime and SDK, [are supported on ARM64](https://dotnet.microsoft.com/en-us/download/dotnet/6.0). We can build and execute all .NET projects targeting .NET, including .NET Core. Obviously, except for WPF and Windows Forms projects. They require Windows anyway.


We can install .NET Core 3.1. There is support only for the [x64 version](https://dotnet.microsoft.com/en-us/download/dotnet/3.1). Not a big deal since it goes out of support soon.

Last but not least, [VS Code](https://code.visualstudio.com) works great. Its support for [dockerized environments](https://milestone.topics.it/2021/06/11/visual-studio-code-remote-containers.html) comes in handy.

### Windows virtualization using Parallels

For everything else, .NET Framework-related, we need a virtual machine or some way to use Windows. Forget about Bootcamp. It doesn't exist, and it probably won't ever exist for ARM.


I installed the trial version of [Parallels](https://www.parallels.com/it/products/desktop/trial/). One caveat for using virtual machines on ARM hosts is that the virtualized operating system needs to be for ARM64. That might open to issues in virtualizing Windows because there is an [agreement between Microsoft and Qualcomm](https://www.theverge.com/2021/11/23/22798231/microsoft-qualcomm-exclusivity-deal-windows-on-arm) that might affect our ability to license Windows for ARM on non-Qualcomm hardware.


That being said, Parallels does an excellent job. Once installed, the virtual machine creation wizard asks a few questions. The first one is what operating system we need, and when I selected Windows 11, it automatically downloaded the required ISO and started the installation. It took a minute, or a little more, to install Windows 11 for ARM.

Windows 11 for ARM, executed in Parallels, is incredibly fast. When used on full screen, it's hard to perceive that it's a virtual machine.


Before getting to development, a couple of words about regular, non-development-related applications. I read here and there people complaining about poor performance. For the sake of the experiment, I installed [Adobe Photoshop Elements](https://www.adobe.com/products/photoshop-elements.html) using the 2012 bits, that's the license I own, and [Audacity](https://www.audacityteam.org/). Both are x64 applications that, at runtime, will go through the x64 to ARM emulation. No issues so far; they work. And they are as fast as they were on my Intel Xeon workstation.

#### Development tools on Windows for ARM

Visual Studio 2022 is not supported. The installation works fine, and like for other applications, Visual Studio runs smoothly. It's a bit slower than on my previous workstation, not that it was stellar fast before. All in all, JetBrains Rider was still providing a better experience (except for the application's first startup time).

The only way to install .NET Framework developer packs was to [manually download the needed installers](https://dotnet.microsoft.com/en-us/download/visual-studio-sdks) instead of the Visual Studio Installer. The Visual Studio Installer installs them, but then Visual Studio complains they are unavailable.

I tried compiling a couple of solutions, intentionally selecting challenging ones. It worked. Tests were green too.

All .NET 6 projects, as expected, compile and run fine.

One last (dolent) note: .NET 3.1 is tricky. As said, it comes only with x64 support. Visual Studio asks to install it:

<screenshot here>

I downloaded the SDK installer based on my previous experience with the developers' pack. It fails. The error is that ARM is not a supported platform, which is an interesting error because we can install the same x64 SDK on the M1 Mac. The .NET Core 3.1 SDK installs fine using the Visual Studio Installer. But then I started getting all sorts of weird errors from Visual Studio. I suppose a lot of the Visual Studio tooling depends on .NET Core that tries to load other assemblies compiled for ARM, causing many operations to fail. Removing .NET Core 3.1 solved my problems. I assume that Visual Studio uses the latest runtime, .NET 6, in my case, if the expected one is not available. I have no idea how many latent problems are waiting for me around the corner.

To be continued.

---

Photo by <a href="https://unsplash.com/@markkoenig?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Mark König</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
