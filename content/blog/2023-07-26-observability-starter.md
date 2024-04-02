+++
title = "An Observability Starter"
slug = "observability-starter"
date = 2023-07-26

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["observability", "swe"]
+++

Observability refers to how well the state of a system can be understood by external outputs. When a system is more observable, you can more quickly identify root causes of performance issues, business logic bugs, and more. In the software engineering space, Application Performance Monitoring (APM) tools help in assisting in the overall observability of a software stack. The ecosystem as a whole began to evolve as distributed computing gained popularity, monoliths were broken up into microservices, and horizontal pod autoscalers were introduced to Kubernetes. New tools around tracking metrics in your applications and distributed tracing across service-to-service communication has surfaced over the years, with some larger players at the forefront of the open source space such as [OpenTelemetry](https://opentelemetry.io/), [StatsD](https://github.com/statsd/statsd), and [OpenMetrics](https://openmetrics.io/).
A big part of these technologies is also collecting, indexing, and presenting them to users. In this regard, there are tons of commercial private and open source solutions, including Prometheus, Datadog, Dynatrace, and more. These tools capture observability signals from across your servers, network traffic, application code, and more to provide you as much insight into your code as possible. Some have core features that give them an edge over the rest of the market, such as Dynatrace's AI-powered root cause analysis engine or Datadog's user-friendly dashboarding and extensible generated metrics tooling. Some open source options like Zipkin support OpenTelemetry and allow you to quickly aggregate traces but do not support other observability constructs like logs or metrics.

## What are Logs

These are probably the most familiar of all of the observability constructs to any developer. From the most basic starter for any language, the Hello World, you are printing a string out to the console, thus generating a log. Logging in observability is a powerful too for understanding various decisions and state in a system. It can often be more expensive to track all logs compared to metrics and traces, particularly if context is injected into every log line. However, in combination with context, logs can serve as a vital tool in understanding which actions were taken within the context of a single trace. Most observability tools that support logs and traces will allow you to go from a log message with trace context to the specific trace in the system, as well as the opposite; allowing you to visualize all log messages related to a trace ID. Beyond this, they often boil down to just a string in the console, with perhaps some formal structure using JSON so you can provide not just a single message but additional context like error names and description, component names, and more.

## What are Metrics

Metrics are numeric aggregations about your application or infrastructure. They can tell you information about the number of requests to your web service over a time period or a statistical breakdown of median, minimum, and maximum of data sets for latency. These metrics can be used to measure all sorts of information about your systems, and are often a cost-effective way of doing so. You can use metrics around your application and requests to build the foundation of basic signals in your system, and all of the [four golden signals of monitoring in the Google Site Reliability Engineering book](https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals) can utilize metrics to easily capture these. Between the statistical measurement of request _Latency_, the total _Traffic_ to an application with request counts, the number of _Errors_ that are occurring, and the _Saturation_ of an application or database, metrics either directly provide and assist in deducing these signals about your system. They can often be quite simple to implement internally as well (see StatsD).

### StatsD

StatsD is an open source project originally released by Etsy, which is a NodeJS service and accompanying specification for simple and powerful metric collection. StatsD clients are typically lightweight, requiring only some configuration for a target host and

## What are Traces

Traces is a short-hand reference to distributed traces, which are graph data structures backed by some specification (OpenTelemetry, OpenTracing) that allow construct metadata about anything from database queries, HTTP requests, network calls and methods executing in your codebase. Any code execution, synchronous or asynchronous, can be visualized as a graph of spans. Spans are like the nodes of a graph, and by nature of the graph data structure there is no requirement to have a single parent node like in a tree. All spans have an implicit duration as a result of the span's start time and end time. They also support naming of the resource and the operation being performed. These constructs collectively allow you to build a graph that effectively describes various types of network, software, and hardware actions being taken, information about them, and then construct visualizations of these that elegantly portray these distributed traces across systems or calculate metrics pertaining to various types of operations. Tracing is a powerful tool in the belt of any software engineer supporting their software in a production system.

### OpenTelemetry

This project defines standards around various observability constructs, including distributing tracing, metrics, and logging. In this way, OpenTelemetry provides a superset of functionality of various tools that preceded its release such as OpenCensus and OpenTracing. As a newer project, not all languages have stable releases, and certain features in the standard have progressed further than others. However, the project continues to gain traction as the open, vendor-agnostic solution for observability.

### OpenTracing

This is an open specification which provides support for distributed tracing exclusively. It has since been superseded by OpenTelemetry, but is still supported and in use by certain vendors in the ecosystem.

### What Metadata Do I Include

There are some best practices defined, such as [OpenTelemetry's Semantic Conventions](https://opentelemetry.io/docs/concepts/semantic-conventions/) and [Elastic's Common Schema](https://www.elastic.co/guide/en/ecs/current/index.html), which help to ensure consistent usage of span tags and other metadata on these spans based on their domain.

Let's take for example a span generated for an HTTP client's request:
	> What HTTP method is the call?  
	> What headers or how many?  
	> What is the size of the payload?  

These standards help you define the metadata that answers these questions on the span in a way that's consistent across systems.

## Vendors

> ⚠️ More to come here

### Datadog

Datadog's dd-trace libraries are based on OpenTracing, and the clients in the package typically implement the OpenTracing client interface. OpenTracing itself is a deprecated project, but Datadog continues to base its tracing capabilities on this system. The backend for Datadog is proprietary, but their agents and dd-trace clients are all open source.

### Dynatrace

Dynatrace is an APM company which centers around its AI-powered root cause analysis engine. It participated in the original inception of OpenTelemetry as a new direction for observability bringing its expertise on distributed tracing. Another core product feature is the OneAgent, which is an executable you can install on any server and it will automatically handle configuring trace and log instrumentation regardless of the system or software*.
