---
layout: post
author: Mauro Servienti
title: "I moved from LastPass to 1Password. I'm not happier"
synopsis: "I've been a long-time LastPass client. I recently switched to 1Password in an attempt to overcome a few LastPass cons. I solved them, but I'm not sure the situation improved."
header_image: /img/posts/one-password/header.jpg
tags:
- personal
---

In February 2021, [LastPass announced changes](https://blog.lastpass.com/2021/02/changes-to-lastpass-free/) to its free tier offering. The change forced people using mixed device types (e.g., computers and phones) to move to the premium tier because the free option allows only one device type.

I own a desktop computer, a laptop, an iPad, and an iPhone. I need access to my passwords from all those devices. I couldn't use the free tier anymore.

The community wasn't happy about the way LastPass handled the change. The general perception was that it was a way to milk money out of their users. I agreed, but at the time, I wasn't in a position to move immediately to something else. I made the most straightforward move: Ì threw money at the problem. I upgraded to the premium license, which gave me one year to decide what to do.

## Why switch?

At this point, that's a legit question.

There were some concerns related to LogMeIn, the LastPass parent company at the time, being acquired by private equity.

Second, I had a few minor technical issues. For example, two-factor authentication worked poorly on iOS devices in some circumstances.

Third, there is no way to log in to different vaults simultaneously. LastPass' solution to that is account sharing. For example, I had the LastPass company account for shared work accounts and security tokens. Given that I had no admin rights on the work account, the only solution was to share my private account with the company one. That made it so that logging in with my work credentials gave me access to my stuff too. The downside is that the work account with shared things is the default vault, so newly created credentials are stored there, and one must remember to switch the vault when storing new credentials. It's a UX issue, it's minor, but it was extremely annoying.

Finally, the overall UX was tremendously poor, especially when using the browser extension. It felt like using an application from a different era, something coming from the nineties.

### One last attempt

LastPass comes with a desktop application. I tried that:

1. I stopped sharing the accounts.
1. I signed in to the browser extension using my account (the one I use the most).
1. I signed in to the desktop application with work credentials.

It works, somewhat. The Windows desktop application SUCKS as if there is no tomorrow. It's a UWP application so ugly that one thinks it's a leftover from a developer test.

Me: what is this UWP thing? Let me try that.
LastPass: that's great. Let's go to production.

It's horrid, and it's missing features. Unusable.

## What's next?

I planned for a future switch when I upgraded my account to premium. I set a reminder for myself nine months ahead to start looking for alternatives with a significant enough buffer time before the LastPass renewal.

When the time came, based on the early cost of a password management solution, I decided not to go through the pain of other password manager trials. I didn't want to update all my devices to new software with a trial license. Import all my passwords, play with the bits, and switch to a different trial.

Based on friends' and colleagues' recommendations, I picked [1Password](https://1password.com) and went for a 1-year Personal subscription. I only checked two things:

- The features listed on the website satisfied my requirements
- There was support to import from LastPass

### So what?

I've been using 1Password for six months, and the balance is not that great.

Is it better than LastPass? Yes and no. It depends.

The biggest issue is GDPR related. By default, data are stored outside the European Union, posing a privacy concern. There is an option, at subscription time, to store data in the EU; however, the sign-up process doesn't highlight it enough (it's a euphemism). Afterward, it's possible to move data across regions, but the process is manual, cumbersome, and far from being user-friendly, which is never a good sign, in my opinion. I'll try it sooner or later.

The second issue is 2FA-related. 1Password, as LastPass does, supports storing the two-factor authentication token in the password manager. It's a handy feature, nonetheless. However, my spider sense perceives it as a security risk. There are scenarios in which it might be a [good enough compromise](https://security.stackexchange.com/questions/194142/is-it-safe-to-store-2fa-tokens-together-with-passwords-in-1password#194279), and [others](https://polansky.co/blog/psa-2fa-password-managers/). So I decided to continue using [Authy](https://authy.com) as the 2FA token storage.

And there comes the third issue. It seems impossible, or at least I couldn't find a way, to disable 2FA support in 1Password. That means 1Password will try to fill tokens when requested automatically. It's again a user experience problem and isn't very pleasant.

The last issue I faced so far is again UX related. On desktop computers, either macOS or Windows, the browser extension comes with a companion application that runs on the operating system. As far as I have understood, it's the companion application that stores data and takes care of encryption. It is probably a more secure solution than doing all that in the browser extension, as LastPass does. However, it comes with some UX issues. For example, the most annoying one happens when clicking on the browser extension, and a password is required to unlock 1Password. Sometimes, after inputting the password, the companion application pops up, full screen, in the foreground.

## Conclusion 

Generally speaking, after six months, 1Password is better than LastPass. However, there is space for improvement. I plan to move to [Bitwarden](https://bitwarden.com) as my 1Password subscription approaches its end and test for one year. If you have other suggestions, please, do leave a comment.

---

Photo by <a href="https://unsplash.com/@moneyphotos?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">regularguy.eth</a> on <a href="https://unsplash.com/s/photos/password?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
