---
layout: post
title: "Who decides who gets a laptop? Ownership when HR and IT overlap"
author: Mauro Servienti
synopsis: "HR hires people, IT hands out devices, and assigning a laptop to a new employee seems to need both. Does it? Let's dissect a scenario where ownership looks shared and find out who owns what."
header_image: /img/posts/hr-it-device-ownership/header.jpg
tags:
- soa
- architecture
- viewmodel-composition
enable_mermaid: true
---

In many organizations, one of the responsibilities of the human resources (HR) department is to hire new people. The Information Technology (IT) department controls, among other things, what kind of hardware each employee receives. Some employees might get a desktop computer, others a laptop and a desktop, and some have a mobile phone or a tablet.

Oversimplifying, when someone gets hired, they sign papers with HR, then go to the IT people and get their hardware. Similarly, HR manages the legal bits when someone gets a promotion or changes units, and IT handles any device update.

Looks trivial. However, from the perspective of a software development team in charge of implementing those scenarios, it's no longer trivial.

Regardless of the chosen architectural style, the scenario is a challenge from the ownership perspective. HR is responsible for the person's role and IT for the assigned devices. However, they need to cooperate when assigning hardware to people.

The apparent overlap muddies the waters and risks introducing unneeded [coupling](https://milestone.topics.it/2023/05/17/back-to-basics-boundaries.html).

> If you need a refresher on what owning data means, I covered it in ["Back to Basics: who owns the data?"](https://milestone.topics.it/2026/11/09/back-to-basics-data-ownership.html).

## Why does it look shared?

The problem arises by [trusting the user's mental model](https://milestone.topics.it/2021/02/02/do-not-trust-the-user-mental-model.html) instead of dissecting the requirements and understanding how the different parts interact.

The way users and business people present requirements is _visual_. They think about how they'd do it on a user interface or (worse) how they always did it in the past. Given that it's not their area of expertise, they describe those processes without paying much attention to the distinction between data and behaviors, and without any attention to ownership and coupling. That's why I suggest not trusting the users' mental model.

Let's start with a bird's-eye view. We're talking about two services, HR and IT, and a workflow, or a policy, to assign devices to employees. As described by users, the policy crosses the boundary between HR and IT. And that might have long-term consequences we prefer to avoid.

> On why cross-service policies (or sagas) are suboptimal, I wrote ["Don't keep a saga in both camps"](https://milestone.topics.it/2021/07/28/dont-keep-a-saga-in-both-camps.html).

## What does each side actually own?

If we scratch the surface and go deeper, we can split the policy into multiple parts. Some are owned by HR and others by IT, with little to no coupling.

The crucial distinction is between device _types_ and _physical_ devices:

- Deciding that a manager gets a laptop and a salesperson gets a tablet and a phone is a decision about device types. It's about roles and entitlements, the politics of who gets what.
- Handing over a specific laptop, with a serial number, configured and ready to use, is about physical devices. It's about stock, procurement, and configuration.

<!--
TODO: confirm the split. The rest of the draft assumes HR owns the "role to device types" policy, and IT owns the device types catalog and the physical devices. If you see it differently (for example, IT owns the policy and HR only owns roles), the composition and events sections change accordingly.
-->

## Who owns the policy?

For the sake of the discussion, let's assume that HR is in charge of deciding who gets what. They control the policy and the politics around it: a manager receives a laptop, everyone else a desktop, a salesperson a tablet and a phone, and so on.

HR people need to configure that policy. They open their system, go to the "device assignment policy" screen, and see a list of positions. As expected, the list shows labels and descriptions: HR owns positions, and IDs, names, and descriptions are in HR storage. They click on a position to get to its details, where a dropdown list allows them to select one or more device types. Again, as expected, the list is a human-readable set of device names and descriptions.

### Wait, aren't devices an IT responsibility?

Yes, they are. The system uses [ViewModel Composition](https://milestone.topics.it/series/view-model-composition.html) to compose data from different services into the user interface. The following diagram shows how it works:

<div class="mermaid">
flowchart LR
    UI["HR policy screen"] --> Composition["Composition gateway"]
    Composition --> HR["HR: positions and the device type IDs assigned to them"]
    Composition --> IT["IT: device type names and descriptions"]
</div>

HR gets all the information it needs to fulfill the requirements without copying IT data into HR storage. All the information about device types comes from the IT service. The composition engine shows HR personnel the list of device types, their names, and all the details needed to make a choice.

When a device type gets assigned to a role, HR stores that a role with a specific ID has one or more device type IDs. HR isn't interested in names or descriptions; only identifiers matter. If someone returns to that page, something very similar happens. This time, however, HR already knows the device type IDs and composes the information to display.

## Something changes in the organization

When a new person joins, HR publishes a corresponding event:

```json
{
  "type": "EmployeeHired",
  "employeeId": "E-456",
  "roleId": "R-123"
}
```

HR uses a similar one, `EmployeeRoleChanged`, to broadcast promotions and changes of unit.

<!--
TODO: decide how IT knows which devices to prepare. The role-to-device-types policy lives in HR, so `roleId` alone isn't enough for IT. Two options:

1. HR applies its own policy and announces the outcome: the event also carries the device type IDs the employee is entitled to (for example, `"deviceTypeIds": ["DT-1", "DT-7"]`). IT doesn't need to know anything about roles. This matches the advice in the data ownership post: the owner makes the decision and announces it.
2. IT doesn't get the entitlement in the event, and IT people see it through composition when the employee shows up.

Pick one and update the event sample and the next section.
-->

IT is responsible for managing devices. When someone joins, they go to the IT department to get their devices. Similar to the HR personnel, IT people use their system to determine which devices to hand over. Their system uses ViewModel Composition to show the employee's name and other details from the HR system. There is no need for IT to store any of those.

### Why does IT subscribe to HR events?

IT could wait for the new employee to show up at the desk. However, devices could be out of stock or need configuration before being used. IT wants to start a process to acquire or configure them as soon as a new employee is hired or changes role, not when they're standing in front of the IT desk.

Similarly, when someone changes role, some devices might no longer be needed. IT wants to know which devices will become available again and start a different process to collect and reset them, making them available to others.

<!--
TODO: describe the role change flow. With option 1 above, `EmployeeRoleChanged` could carry both the old and the new entitlements, or just the new ones and let IT work out the difference against what it handed out. Who decides that a device must be returned: HR (policy) or IT (inventory)?
-->

## What if there are thousands of them?

What if we had thousands of employees or hundreds of different device types? We cannot expect anyone to scroll through a list of hundreds, if not thousands, of items. In those scenarios, searching is a given.

But the things we want to search for are in different places.

That means the search functionality must be implemented by the service that owns the data. HR will search for device types through IT's search capabilities, and IT will search for employees through HR's.

Does that create coupling?

In a sense, yes.

<!--
TODO: finish the argument. Suggested direction: it's a different and milder kind of coupling than copying data. The HR user interface depends on IT's search contract at the edges, through composition, while HR's storage and business logic don't know anything about devices. IT can change how device types are stored or described without HR noticing, as long as the search contract holds. Copying device data into HR would couple storage, business rules, and release cycles.
-->

## Conclusion

<!--
TODO: restate the thesis in your words. Suggested points: the overlap between HR and IT is in the user's mental model, not in the data. Split device types from physical devices, let HR own the entitlement policy and IT the inventory, compose at the user interface, and use events carrying identifiers and decisions to keep the two in sync.
-->
