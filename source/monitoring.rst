Monitoring
==========

Monitoring is an integral part of providing highly available services. By monitoring, we mean:

1.  Instrumenting your applications and servers and collecting as many useful **metrics** as
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

Symptoms-based alerting
+++++++++++++++++++++++

For on-call alerts, you want to strictly limit the amount of pages you send out in order to
maintain a high signal-to-noise ratio. Every page interrupts the on-call engineer's workflow, and in
the worst case, it wakes him up at night.

In order to do this, you want to alert on symptoms *as far up the stack as possible*. Instead of
having an alert that says "one of our MySQL database servers is down", you want "the website error
rate went up", which catches a huge number of potential issues, whereas a redundant database server
going down may not have any impact whatsoever.

Once you've been woken up, you can then use your detailed metrics and dashboards to narrow down
the cause of the outage, but there's no point on alerting on them.

Exceptions to this are cases where you can reliably extrapolate - like "this disk *will* up in
30 minutes, and it *will* take down our service unless it's fixed.

Low-severity alerts
-------------------

There are many conditions that need to be taken of, just not *immediately*. Your redundant database
server went down and nobody got paged - great! But, you still need someone to fix that database
server, or clean up the log partition that will soon fill up, or refill your coffee maker (you're
monitoring your coffee maker, right? It's critical infrastructure!).

A common approach is to have a separate, **low-severity notification channel** that won't wake anyone
up, but still ensure that the issue is resolved. We recommend a channel in your favorite business
messaging application, *plus* a dashboard which shows outstanding alerts (the dashboard is really
important, since it ensures that alerts are acted upon - it's basically a to-do list).

