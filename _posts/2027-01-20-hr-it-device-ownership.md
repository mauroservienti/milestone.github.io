---
layout: post
title: "Who decides who gets a laptop? Ownership when HR and IT overlap"
author: Mauro Servienti
synopsis: "HR hires people, IT hands out devices, and assigning a laptop to a new employee seems to need both. Does it? Let's dissect a scenario where ownership looks shared and find out who owns what."
header_image: /img/posts/hr-it-device-ownership/header.jpg
related:
- 2026-11-09-back-to-basics-data-ownership.md
- 2021-02-02-do-not-trust-the-user-mental-model.md
- 2021-07-15-own-the-cache.md
- 2021-07-28-dont-keep-a-saga-in-both-camps.md
tags:
- soa
- architecture
- viewmodel-composition
enable_mermaid: true
---

In many organizations, one of the responsibilities of the human resources (HR) department is to hire new people. The Information Technology (IT) department controls, among other things, what kind of hardware each employee receives. Some employees get a desktop computer, others a laptop and a desktop, and some also get a mobile phone or a tablet.

Oversimplifying, when someone gets hired, they sign papers with HR, then go to IT to get their hardware. Similarly, HR manages the legal bits when someone gets a promotion or changes units, and IT handles any device update.

Looks trivial. However, for the software development team implementing those scenarios, it isn't trivial at all.

Regardless of the chosen architectural style, the scenario is a challenge from the ownership perspective. HR is responsible for the person's role and IT for the assigned devices. However, they need to cooperate when assigning hardware to people.

The apparent overlap muddies the waters and risks introducing unneeded [coupling](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html).

> If you need a refresher on what owning data means, I covered it in ["Back to Basics: who owns the data?"](https://milestone.topics.it/2026/11/09/back-to-basics-data-ownership.html).

## Why does it look shared?

The problem arises from [trusting the user's mental model](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html) instead of dissecting the requirements and understanding how the different parts interact.

Users and business people present requirements in a _visual_ way. They think about how they'd do it on a user interface or (worse) how they always did it in the past. Because it's not their area of expertise, they describe those processes without paying much attention to the distinction between data and behaviors, or to ownership and coupling. That's why I suggest not trusting the users' mental model.

Let's start with a bird's-eye view. We're talking about two services, HR and IT, and a workflow, or a policy, to assign devices to employees. As users describe it, the policy crosses the boundary between HR and IT. And that might have long-term consequences we prefer to avoid.

> On why cross-service policies (or sagas) are suboptimal, I wrote ["Don't keep a saga in both camps"](https://milestone.topics.it/2021/07/28/dont-keep-a-saga-in-both-camps.html).

## What does each side actually own?

If we scratch the surface and go deeper, we can split the policy into multiple parts. Some are owned by HR and others by IT, with little to no coupling.

The crucial distinction is between device _types_ and _physical_ devices:

- Deciding that a manager gets a laptop and a salesperson gets a tablet and a phone is a decision about device types. It's about roles and entitlements, the politics of who gets what.
- Handing over a specific laptop, with a serial number, configured and ready to use, is about physical devices. It's about stock, procurement, and configuration.

Once you separate the two, ownership becomes clearer. IT owns the catalog of device types, their names, descriptions, and specifications, and the physical devices, from procurement to configuration. What's left is the policy that connects roles to device types.

## Who owns the policy?

For the sake of the discussion, let's assume HR decides who gets what. They control the policy and the politics around it: a manager receives a laptop, a salesperson a tablet and a phone, everyone else a desktop, and so on.

HR people need to configure that policy. They open their system, go to the "device assignment policy" screen, and see a list of roles. As expected, the list shows names and descriptions: HR owns roles, and their IDs, names, and descriptions are in HR storage. They click a role to view its details, where a list lets them select one or more device types. Again, as expected, the list shows human-readable device names and descriptions.

### Wait, aren't devices an IT responsibility?

Yes, they are. The system uses [ViewModel Composition](https://milestone.topics.it/series/view-model-composition.html) to compose data from different services into the user interface. The following diagram shows how it works:

<div class="mermaid">
flowchart LR
    UI["HR policy screen"] --> Composition["Composition gateway"]
    Composition --> HR["HR: roles and the device type IDs assigned to them"]
    Composition --> IT["IT: device type names and descriptions"]
</div>

HR gets all the information it needs to fulfill the requirements without copying IT data into HR storage. All the information about device types comes from the IT service. The composition engine shows HR personnel the list of device types, their names, and all the details needed to make a choice.

When a device type gets assigned to a role, HR stores that a role with a specific ID has one or more device type IDs. HR isn't interested in names or descriptions; only identifiers matter. When someone returns to that page, the same composition happens: HR provides the device type IDs it stored, and IT provides the names and descriptions to display.

## What happens when someone joins or changes role?

When a new person joins, HR publishes a corresponding event:

```json
{
  "type": "EmployeeHired",
  "employeeId": "E-456",
  "roleId": "R-123",
  "deviceTypeIds": ["DT-1", "DT-7"]
}
```

The role ID alone isn't enough for IT. The policy connecting roles to device types lives in HR, and IT shouldn't reimplement it or keep a copy to determine what the new employee is entitled to. Instead, HR applies its own policy and announces the outcome: employee E-456 is entitled to device types DT-1 and DT-7. IT doesn't need to know anything about roles. As I wrote in ["Back to Basics: who owns the data?"](https://milestone.topics.it/2026/11/09/back-to-basics-data-ownership.html), when a decision belongs to a service, that service makes it and announces it. Others only need to know the outcome.

The event carries identifiers and the decision, not names, descriptions, or anything else HR doesn't own.

HR uses a similar event, `EmployeeRoleChanged`, to broadcast promotions and changes of unit:

```json
{
  "type": "EmployeeRoleChanged",
  "employeeId": "E-456",
  "roleId": "R-789",
  "deviceTypeIds": ["DT-1", "DT-3"]
}
```

IT is responsible for managing devices. When someone joins, they go to the IT department to get their devices. Like HR, IT uses its own system to determine which devices to hand over. That system uses ViewModel Composition to show the employee's name and other details from the HR system. IT doesn't need to store any of that.

### Why does IT subscribe to HR events?

IT could wait until the new employee shows up. However, devices could be out of stock or need configuration before being used. IT wants to start a process to acquire or configure them as soon as a new employee is hired or changes role, not when they're standing in front of the IT desk.

Similarly, when someone changes role, some devices might no longer be needed. IT wants to find out which devices will become available again so it can start a different process to collect and reset them, making them available to others.

Who decides that a device must be returned? HR could send both the old and the new entitlements, but that would be HR telling IT what to do with its inventory. `EmployeeRoleChanged` carries only the new entitlement. IT knows which physical devices it handed out to employee E-456, compares them with the device types the employee is now entitled to, and decides what to do: the laptop stays, the tablet must be collected and reset, and a new phone must be prepared. HR owns the policy, IT owns the inventory, and each one decides what it manages.

## What if there are thousands of them?

What if we had thousands of employees or hundreds of different device types? We cannot expect anyone to scroll through a list of hundreds, if not thousands, of items. In those scenarios, searching is a given.

But the things we want to search for are in different places.

That means the service that owns the data must implement the search. HR will search for device types through IT's search capabilities, and IT will search for employees through HR's.

Does that create coupling?

In a sense, yes. But it's a different, and much milder, kind of coupling than the one we were trying to avoid.

The HR user interface depends on IT's search capabilities, at the edges, through composition. HR's storage and business logic know nothing about devices other than their identifiers. IT can change how it stores, describes, or indexes device types without HR noticing, as long as the search contract holds. The same goes the other way for employees.

Compare that with the alternative: copying device types into HR storage to make them searchable. HR would need to keep the copy up to date, decide when it's stale, and, sooner or later, start making decisions based on data it doesn't own. Storage, business rules, and release cycles would be coupled. That's the coupling that hurts.

## Conclusion

The overlap between HR and IT is in the users' mental model, not in the data. Once we split device types from physical devices, ownership becomes clear: HR owns roles and the policy that entitles each role to device types, and IT owns the device type catalog and the physical devices. The user interface composes data from both, and events carrying identifiers and decisions let IT act on what HR decides. Neither service copies the other's data, and neither makes decisions that belong to the other.

---

Photo by <a href="https://unsplash.com/@yolk_coworking_krakow?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Yolk CoWorking - Krakow</a> on <a href="https://unsplash.com/photos/white-wooden-table-with-chairs-k9aUYYkWWI0?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
