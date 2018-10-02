Monitoring, Alerting and Instrumentation
========================================

Monitoring is an integral part of providing highly available services. By monitoring, we mean:

1.  **Instrumenting** your applications and servers and collecting as many useful **metrics** as
    possible. Having detailed metrics is invaluable for debugging, incident response and
    performance analysis (observability - you can't improve what you can't measure).
     \

2.  Generating on-call **alerts** when a production system breaks and needs fixing.
     \

3.  Handling one-time **events** which need attention.

Traditionally, most teams used different systems for metrics and alerting, with a time-series
database like Graphite for metrics and a check-based monitoring system like Nagios for alerts.
Nowadays, a different paradigm is getting popular - **metrics-based alerting**. Instead of having
separate tooling for instrumentation and monitoring, alerts are realized by configuring rules
that are evaluated against collected metrics.

This is a very powerful approach, since it radically simplifies the monitoring stack and allows
for sophisticated queries over time ranges and groups of metrics.

Modern monitoring like Prometheus make modern metrics-based alerting very approachable.
Gone are the days of fiddling with Nagios performance and check scripts!

However, no tool can solve the hardest part about monitoring - figuring out what to monitor and
when to alert. As any on-call engineer can attest, the most common failure mode in alerting is
having *too many* alerts, rather than too few, with important alerts getting lost in the noise.

Therefore, the main goal of a good alerting system is a **high signal-to-noise ratio** -
every alert should be *relevant* (impact a production system in a way that requires
immediate attention), and *actionable* (require human input to resolve). Any condition that isn't
either relevant, or actionable, must not result in an alert.

You also need to figure out whom to alert - also called **on-call rotation**, how to compensate
for it, how to fairly distribute the load in the team, how to effectively communicate during an
incident, and handle the feedback loop (we'll dedicate a separate article to this topic).

A low number of meaningful, simple alerts paired with robust business procedures which ensure that
alerts are acted upon, false positives are quickly eliminated and outages are followed up are much
more powerful than "magic" approaches like anomaly detection, which sound good in theory, but don't
work well in practice [#anomaly]_.

..   [#anomaly] Anomaly detection - while useful in other contexts- tends to quickly break down for
     monitoring use cases. As soon as you compare a sufficiently large number of metrics, spurious
     correlations will show up and result in false positives. Your online shop saw a 10x traffic
     spike, but didn't go down - why would you page someone? Everything is working fine.
     Simple time offsets (do we see less traffic than last week?), linear extrapolation and
     even fixed thresholds are much more specific.

Symptoms-Based Alerting
+++++++++++++++++++++++

For on-call alerts, you want to strictly limit the amount of pages you send out in order to
maintain a high signal-to-noise ratio. Every page interrupts the on-call engineer's workflow, and in
the worst case, it wakes him up at night.

In order to do this, you want to alert on symptoms *as far up the stack as possible*, rather than
causes. Instead of having an alert that says "one of our MySQL database servers is down", you
want "the website error rate went up", which catches a huge number of potential issues, whereas
a redundant database server going down may not have any impact whatsoever.

Once you've been woken up, you can then use your detailed metrics and dashboards to narrow down
the cause of the outage, but there's no point on alerting on them unless they impact service
quality.

Exceptions to this are cases where you can reliably extrapolate that something is going to break
soon - like "this disk *will* up in 30 minutes, and it *will* take down our service unless it's fixed.

Low-Severity Alerts
-------------------

There are many conditions that need to be taken of, just not *immediately*. Your redundant database
server went down and nobody got paged - great! But, you still need someone to fix that database
server, or clean up the log partition that will soon fill up, or refill your coffee maker (you're
monitoring your coffee maker, right? It's critical infrastructure!).

A common approach is to have a separate, **low-severity notification channel** that won't wake anyone
up, but still ensure that the issue is resolved. We recommend a channel in your favorite business
messaging application, *plus* a dashboard which shows outstanding alerts (the dashboard is really
important, since it ensures that alerts are acted upon - it's basically a to-do list).

What To Monitor
+++++++++++++++

There are two commonly used methodologies to determine a baseline of what to monitor - *USE*
(utilization, saturation and errors) and *RED* (rate, errors and durations).

USE is a general-purpose resource-centric view. Examples of resources are CPUs, disks and
some software services that are effectively resources.

Utilization
  An average over a time interval of how much time your resource is busy vs. idle.
  A common example are CPU utilization values (90% busy), memory usage.

Saturation
  How much extra work is queued up/waiting. Common examples are the CPU load (processor run
  queue length), worker queue sizes, network interface queues or memory swapping.

Errors
  Accumulated number of error events like network interface error counters, queue overflows,
  application exceptions and restart counters.

RED is a higher-level service-centric view for request-based services like APIs and webservers.

Rate
  The rate of work being completed, like requests per second for APIs and webservers,
  packets per second for network devices, or concurrent sessions for push notification servers.

Errors
  Number of requests that failed.

Durations
  How long single requests take to complete.

Google's SRE book has a slightly different approach ("The Four Golden Signals") which combines
both - latency (durations), traffic (rate), errors and saturation (saturation being more broadly
defined as the utilization of a system's bottleneck/constraint).

Both methodologies complement each other and provide a comprehensive view of your applications
performance. Take them as suggestions, not gospel - they don't always fit. Make sure to
understand how your application behaves and define custom metrics as you see fit.

Here are examples of metrics we collect for our Cosmos validators:

- Network latencies between our different sites running our active-active validators
  (essential for troubleshooting high block signing latencies, since latency sets the
  lower bound for our internal consensus mechanism).

- BGP path distance and ASN-vs-distance metrics between our different sites
  (unexpected changes in BGP paths can explain changes in latency and need to be investigated,
  since they can increase the risk of network partitions).

- Metrics exposed by Tendermint

  - Block height (``consensus_height``)

  - Total online weight in the network (``consensus_validators_power``)

  - Missing validators (``consensus_missing_validators``)

  - Byzantine validators and weight
    (``consensus_byzantine_validators`` and ``consensus_byzantine_validators_power``)

  - Last block size (``consensus_block_size_bytes``)

  - Current consensus round (``consensus_rounds``)

  - Number of peers (``p2p_peers``)

- `chain_exporter`_ metrics

  - Blocks that our validators missed (miss_infos table)

  - Recent proposals in the network (proposals table)

  - Our validator's outbound peers (peer_infos table)

- Golang process statistics (automatically generated by the Go Prometheus exporter)

  - Process memory (``process_resident_memory_bytes``)

  - Go stack metrics (``go_memstats_alloc_bytes``)

  - Open file descriptors (``process_open_fds`` - fds are a limited resource!)

  - Number of goroutines (``go_goroutines`` - Goroutines aren't OS threads, they're limited by
    available memory and garbage collection costs; the metric is particularly important to spot
    Goroutine leaks which lead to high memory usage)

  - Garbage collector quantiles (``go_gc_duration_seconds``)

- `node_exporter`_ metrics

Of course, not all of them have alerts, but they're displayed in our operational dashboards
and are the first step in troubleshooting.

Our `testnet_deploy`_ GitHub repo includes example dashboards for these metrics.

.. _chain_exporter: https://github.com/certusone/chain_exporter
.. _testnet_deploy: https://github.com/certusone/testnet_deploy
.. _node_exporter: https://github.com/prometheus/node_exporter

What To Alert
+++++++++++++

All alerts should be, fundamentally, rooted in your business goals. If you're hosting an application,
you usually have customers, and your customers expect a certain service level. The service level can
be expressed in terms of application metrics - so-called **service level indicators**. You then define
**service level objectives** (SLOs) - the bar you set for yourself - and probably
**service level agreements** (SLAs) with your customers, usually lower than your SLOs.

.. Alerts help you maximize your service level by notifying you when you're risking your

Chapter `4`_ of Google's SRE book has a great writeup on how to define your service levels - we
recommend you read it (along with the rest of that book).

.. _4: https://landing.google.com/sre/book/chapters/service-level-objectives.html

.. todo:: Coming soon

How to Monitor
++++++++++++++

The only mature open-source implementation of metrics-based alerting is the `Prometheus`_ project.
It serves as metrics collector, time-series database and alerting system.

While Prometheus has a simple web UI for ad-hoc queries and debugging, `Grafana`_ (which includes a
Prometheus data source out of the box) is commonly used for complex dashboards.

.. _Prometheus: https://prometheus.io/
.. _Grafana: https://grafana.com/

.. todo:: Coming soon

.. Make sure to use the latest stable Prometheus release. Many Linux distributions package old
   versions of Prometheus.

Counters vs gauges
------------------

.. todo:: Coming soon

.. If your metric can be expressed as a counter of total events (number of packets received) rather
   than

Quantiles
---------

.. todo:: Coming soon

Push vs Pull
------------

.. todo:: Coming soon

.. One common point of confusion with Prometheus, especially if you're coming from a traditional
   time-series database like Graphite or InfluxDB, is

How to Alert
++++++++++++

.. todo:: Coming soon

Events
++++++

.. todo:: Coming soon

.. Metrics are always aggregations or point-in-time measurements, their resolution being limited by

Further Reading
+++++++++++++++

Recommended reads on this topic:

- *Site Reliability Engineering* by Google (Betsy Beyer, Chris Jones, Jennifer Petoff and Niall
  Richard Murphy). The systems reliability engineering bible. Its a great read in its entirety, but
  as far as monitoring and alerting are concerned, chapters `6`_ and `10`_ are must-reads.

  `Read it online <https://landing.google.com/sre/book.html>`_,
  `Amazon <https://www.amazon.com/Site-Reliability-Engineering-Production-Systems/dp/149192912X>`_

.. _6: https://landing.google.com/sre/book/chapters/monitoring-distributed-systems.html
.. _10: https://landing.google.com/sre/book/chapters/practical-alerting.html

- *My Philosophy on Alerting* by Rob Ewaschuk. Precursor to Google's SRE book and still a good
  and succinct read on its own.

  `Read it online <https://docs.google.com/document/d/199PqyG3UsyXlwieHaqbGiWVa8eMWi8zzAn0YfcApr8Q/edit>`_

- *The USE Method*, article by Brendan Gregg. Brendan Gregg is a well-known (if not *the*) expert
  on performance analytics. This article introduces the USE method.

  `Read it online <http://www.brendangregg.com/usemethod.html>`_

- *Systems Performance* by Brendan Gregg. The reference book for systems performance analysis
  and optimization, with a focus on UNIX (Linux, Solaris) performance.

  `Amazon <https://www.amazon.com/gp/product/0133390098?ie=UTF8&tag=deirdrestraug-20&linkCode=as2&camp=1789&creative=390957&creativeASIN=0133390098>`_ (affiliate link taken from Brendan's website)


