---
layout: post
title: "A small ServiceControl maintenance utility"
author: Mauro Servienti
synopsis: "From time to time, I enjoy writing code on the side, like an open-source project. This time, the opportunity came from a support case and the need to ease the customer's life in their daily maintenance tasks."
header_image: /img/posts/service-control-ghost-endpoints/header.jpg
tags:
- development
---
As I said multiple times, I work for [Particular Software](https://particular.net/), the makers of [NServiceBus](https://particular.net/nservicebus).

We offer a [platform](https://particular.net/service-platform) composed of:

- [NServiceBus](https://particular.net/nservicebus), a messaging framework
- [ServicePulse](https://particular.net/servicepulse), a system monitoring and operations tool.
- [ServiceInsight](https://particular.net/serviceinsight), a system visualization tool.
- [ServiceControl](https://github.com/Particular/ServiceControl/releases), the backend for ServicePulse and ServiceInsight.

## Knowing your system

One of the Platform's features is the visualization and monitoring of the system's endpoints. It does this in several different ways.

### Heartbeats

Messaging endpoints built using NServiceBus can be configured to send [heartbeats](https://docs.particular.net/monitoring/heartbeats/) to ServiceControl. ServiceControl stores heartbeat data and keeps track of the last received one. If it stops receiving heartbeats from one or more endpoints for a specific time, it marks the endpoints inactive and raises a warning event.

### Monitoring and metrics data

Similarly, endpoints can send [monitoring and metrics data](https://docs.particular.net/monitoring/metrics/definitions) to ServiceControl. Metrics data contains things like queue length and critical time, to name two. Queue length is the number of messages in the endpoint input queue waiting to be processed. Critical time is the total time a message takes from when it's sent to when it is successfully processed.

### Audit-derived endpoints

ServiceControl can deduce the existence of endpoints from [audited messages](https://docs.particular.net/nservicebus/operations/auditing) if none of the above is enabled. We can configure each endpoint to audit successfully processed messages to an audit queue. ServiceControl consumes and stores messages from that queue and deduces existing system endpoints.

## Scaled-out endpoints

When systems need more "endpoint power," operations people can scale out endpoint instances. Each endpoint can be deployed more than once in a [competing consumer](https://docs.particular.net/nservicebus/scaling#scaling-out-to-multiple-nodes-competing-consumers) fashion.

From the ServiceControl perspective, those endpoint instances belong to the same logical endpoint. When visualizing those, for example, in ServicePulse, they can be grouped. We can differentiate them because they generate a unique and stable host identifier.
At startup, the endpoint uses a few stable host-dependent information to generate a unique identifier communicated to ServiceControl. For example, an endpoint tells ServiceControl that its name is "Sales" and its Host ID is "qwerty123". Another instance will tell that its name is still "Sales" but with a different Host ID, allowing the Platform to deduct that those are two instances of the same logical endpoint.

We can [take control of the host identifier generation](https://docs.particular.net/nservicebus/hosting/override-hostid) in those scenarios where we know the underlying infrastructure is not stable, but the endpoint instances are. For example, when deploying to containers, the container instance could change. However, if we know we have a fixed number of instances, we can still generate a stable identifier for each instance, even if the underlying hosting container changes. For example, we could set an environment variable for each instance and use the value to generate a stable identity. For Kubernetes, we can use a [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).

### Elastic scaling

The number of endpoint instances in elastic scaling environments varies automatically based on some rules. For example, if the number of concurrent HTTP requests is higher than a threshold, the number of instances increases and similarly decreases with a decreasing load.

Considering that host identifiers are the only way to distinguish instances, if an instance gets a different identifier each time it starts, for ServiceControl, it'll be a different one. In elastic scaling environments, that might lead to ghost instances.

The system starts with a baseline of five instances. The load increases, and more instances start serving requests. ServiceControl correctly sees those new instances. As the load decreases, some instances get decommissioned, and the monitoring infrastructure correctly warns that the decommissioned instances no longer report heartbeats or metrics.

The load increases again, and more instances get deployed; however, those new instances have a new host identifier because the underlying infrastructure doesn't allow for stable ones or is not correctly configured to do so. As you can imagine, the more instances fluctuate, the more ghosts ServiceControl reports when those instances are decommissioned.

## Why is that a problem?

Ghost instances per se are not an issue. We get an alarm on one of the ServicePulse pages, and we can mute it. The problem starts when the number of ghost instances increases, or the fluctuation is fast. When that's the case, keeping up with manually muting alarms in ServicePulse can be challenging, making the user interface clunky and difficult to navigate.

We're investigating ways to mute ghost instances automatically. However, we don't know your system, and it's challenging to identify automated rules for doing so.

## A solution

[ServiceControl.RemoveStaleEndpoints](https://github.com/mauroservienti/ServiceControl.RemoveStaleEndpoints) is a command line utility that allows muting stale/ghost endpoints. We can schedule the CLI tool in elastic scale environments to routinely clean ghost endpoints. For example, the following command cleans endpoints that stopped reporting heartbeats:

```shell
servicecontrol-remove-stale-endpoints purge-service-control-stale-endpoints --url http://localhost:33333/ --cutoff 00:15:00
```

The `cutoff` determines how long they should've been stale before removal. In the above example, if an endpoint stopped reporting heartbeats five minutes ago, it won't be removed.

Similarly, we can use the following command to remove stale endpoint instances from the monitoring data:

```shell
servicecontrol-remove-stale-endpoints purge-service-control-monitoring-stale-instances --url http://localhost:33633
```

The CLI tool is available for free from my [GitHub repository](https://github.com/mauroservienti/ServiceControl.RemoveStaleEndpoints) and is not supported by Particular. It's available as a .NET tool, and you can install it using the following command:

```shell
dotnet tool install -g ServiceControl.RemoveStaleEndpoints --add-source https://f.feedz.io/mauroservienti/pre-releases/nuget/index.json
```

More details and command options are available in the linked repository.

## Conclusion

Monitoring elastic scale environments is challenging; instances and resources come and go quickly. Depending on the environment configuration, sometimes it is tricky to understand that a new resource is, in reality, a previous one that came back under a different name. When that happens with NServiceBus endpoints, we risk fooling ServiceControl and generating many ghost endpoints. In production, we can use the [ServiceControl.RemoveStaleEndpoints](https://github.com/mauroservienti/ServiceControl.RemoveStaleEndpoints) command line utility to keep the situation under control.

---

Photo by <a href="https://unsplash.com/@jeshoots?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">JESHOOTS.COM</a> on <a href="https://unsplash.com/photos/person-holding-yellow-plastic-spray-bottle-__ZMnefoI3k?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
