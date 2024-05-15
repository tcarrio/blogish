+++
title = "Datadog and StatsD for Serverless"
slug = "datadog-statsd-serverless"
date = 2024-05-15
draft = false

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["monitoring", "sre", "observability", "metrics", "statsd", "datadog"]
+++

## tl;dr

> **Do not use StatsD metrics with Datadog for serverless applications.** Instead, utilize the `distribution` metric type available in DogStatsD.

You will save yourself many hours or even days of lost time trying to get it to work. The `distribution` metric type is specifically designed for serverless applications and is more resilient to data loss and function termination.

## Monitoring Types

A quick review of available types of monitoring in applications:

- Logging
- Metrics
- Tracing
- Profiling

The focus of this article is on **metrics**, specifically the use of StatsD metrics with Datadog for serverless applications.

## Serverless Architecture

Serverless architecture is a cloud computing model that allows developers to build and run applications and services without having to manage infrastructure. Serverless applications are composed of one or more functions that are triggered by events such as HTTP requests, database events, or file uploads. These functions are typically short-lived and stateless, and are executed in response to events.

A serverless architecture is a great way to build scalable, cost-effective applications that can respond to events in real-time. However, monitoring serverless applications can be challenging due to the ephemeral nature of the functions and the lack of visibility into the underlying infrastructure.

## StatsD Architecture

StatsD is a simple, lightweight network daemon that listens for statistics, like counters and timers, sent over UDP or TCP and sends aggregates to one or more pluggable backend services (e.g., Graphite, Datadog, etc.). StatsD is commonly used to collect and aggregate metrics from applications and services and send them to a monitoring system for analysis and visualization.

## Datadog and StatsD: DogStatsD

Datadog is a popular monitoring and observability platform that provides a wide range of features for monitoring applications and infrastructure. Datadog supports StatsD metrics natively, allowing you to send metrics from your applications to Datadog using the StatsD protocol.

There is an embedded component in the Datadog agent called DogStatsD. This is a StatsD-compatible server that listens for metrics and forwards them to the Datadog backend. It supports a superset of the StatsD protocol, including additional metric types like `distribution`.

If you are using a Datadog Agent, you can send metrics to DogStatsD using the StatsD protocol. This allows you to leverage the full power of Datadog's monitoring and alerting capabilities with your serverless applications.

## DogStatsD and Serverless

When using DogStatsD with serverless applications, it is important to be aware of the limitations of the StatsD protocol. The StatsD protocol was designed for traditional server-based applications and may not be well-suited for serverless applications due to the ephemeral nature of the functions. StatsD servers typically aggregate metrics in memory and flush them to the backend at regular intervals. The implications of this are two-fold:

1. This can lead to data loss if the server is restarted or if the function is terminated before the metrics are flushed.
2. The in-memory aggregation of metrics is necessary for the data to be handed off successfully to Datadog, relying on properties such as `host` in the agent.

## Metrics in Serverless Functions

Datadog provides capabilities for serverless monitoring including a Lambda Layer which provides an embedded Serverless Datadog Agent. This supports most of the same functionalities as the Datadog Agent in a traditional server environment.

> ⚠️ Due to the second limitation of DogStatsD and Serverless though, it is important to use the `distribution` metric type instead of the `gauge` or `count` types.

The `distribution` metric type is specifically designed for serverless applications and is more resilient to data loss and function termination. It does not rely on in-memory aggregation, and the data is sent directly to the Datadog backend.

## Why do StatsD metrics not work well with serverless?

There are many components involved in the failure mode of StatsD metrics in serverless environments. Here are a few:

- **Data Loss**: The ephemeral nature of serverless functions can lead to data loss if the function is terminated before the metrics are flushed to the backend.
- **In-Memory Aggregation**: StatsD servers typically aggregate metrics in memory and flush them to the backend at regular intervals. This can lead to data loss if the function is terminated before the metrics are flushed.
- **Host Dependency**: The in-memory aggregation of metrics relies on properties such as `host` in the agent. This can lead to data loss if the function is terminated before the metrics are flushed.

## How to use `distribution` metrics with DogStatsD

To use the `distribution` metric type with DogStatsD, you need to send the metrics using the `distribution` method in the DogStatsD client. Here is an example of how to send a `distribution` metric in NodeJS:

```javascript
const StatsD = require("hot-shots");
const dogstatsd = new StatsD();

dogstatsd.distribution("metric.name", 42);
```

This will send a `distribution` metric with the name `metric.name` and the value `42` to the DogStatsD server. Behind the scenes, the way DogStatsD passes this data along is different than the way it handles `gauge` or `count` metrics. It is raw, unaggregated data that is sent directly to the Datadog backend.

## Conclusion

When monitoring serverless applications with Datadog, it is important to use the `distribution` metric type instead of the `gauge` or `count` types. This will ensure that your metrics are resilient to data loss and function termination and will provide more accurate monitoring and alerting capabilities for your serverless applications.
