---
layout: post
title: "VDesk: Windows 10 desktops made easy."
author: Mauro Servienti
synopsis: "I consider myself an happy Windows 10 user. With some issues, sometimes, due to the fact that I'm using a Windows 10 Insider beta version on both my work machines. Brave guy. As former OSX user I felt in love with multi-desktop support long time ago and I've always looked for ways to improve the very basic Windows 10 multi-desktop experience. Be aware that very basic doesn't mean poor."
tags:
- Windows 10
- Virtual Desktops
---

I consider myself an happy Windows 10 user. With some issues, sometimes, due to the fact that I'm using a Windows 10 Insider beta version on both my work machines. Brave guy. As former OSX user I felt in love with multi-desktop support long time ago and I've always looked for ways to improve the very basic Windows 10 multi-desktop experience. Be aware that very basic doesn't mean poor.

I use virtualization a lot, and my main requirement has even been to start a VM in full screen mode on its own dedicated desktop and benefit of the amazing experience, OSX-like, of the 4 fingers swipe to move from one desktop to another.

Starting a VirtualBox VM in full screen is not supported by default in the UI but can be easily achieved using the following command:

```
VirtualBox --startvm <vm-name> --fullscreen
```

Easy peasy.

Once the VM is started in full screen mode the only out of the box option on Windows 10 is to manually move the VM window to a different desktop. Annoying.

### VDesk to the rescue

[VDesk](https://github.com/eksime/VDesk) is nice comand line utility that enhances Windows 10 multi desktop management adding some very interesting features, such as what I was looking for:

```
vdesk run-switch VirtualBox --startvm <vm-name> --fullscreen
```

That's it. What VDesk will do is: Run the command on a different desktop and switch to it. Exactly what I was looking for.

As a bonus VDesk is open source.