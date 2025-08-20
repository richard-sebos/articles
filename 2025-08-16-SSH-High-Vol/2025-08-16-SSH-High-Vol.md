# Optimizing SSH for High-Volume Environments

## Introduction

In many cases, a default SSH installation, especially with a few added security tweaks, is perfectly sufficient. But what happens when you're dealing with a corporate environment where hundreds or even thousands of users are logging in daily to access applications? Can a default configuration handle that kind of load effectively? The short answer is: not quite. In this article, we’ll walk through why changes are necessary and how to properly tune an SSH server to support high volumes of concurrent connections.

---
## Table of Contents

1. [Introduction](#introduction)
2. [Test Environment Setup](#test-environment-setup)

   * [SSH Servers](#ssh-servers)
   * [Testing Host](#testing-host)
3. [The Test](#the-test)
4. [SSH Configuration Changes](#ssh-configuration-changes)
5. [System-Level Tuning](#system-level-tuning)
6. [Reevaluating the Bottleneck](#reevaluating-the-bottleneck)

   * [Enabling SSH Multiplexing](#enabling-ssh-multiplexing)
7. [Conclusion](#conclusion)

---

## Test Environment Setup

### SSH Servers

To test this, I created a simple lab setup using two cloned virtual machines: `control.sebostech.local` and `highvol.sebostech.local`. Both were running on a Proxmox VE server with a basic configuration—8 CPU cores and 8 GB of RAM each. Under normal conditions, these resources would be more than adequate for a typical SSH server. Since both systems were cloned from the same image, they shared identical configurations, ensuring a consistent testing environment.

### Testing Host

The tests were executed from a third VM, which acted as the initiating server. This system had a slightly more powerful configuration with 6 CPU cores and 8 GB of RAM. I upgraded its resources after noticing that the test processes were putting a significant load on the system, and I didn’t want the testing server to become a bottleneck. The Proxmox host itself was an older system running DDR3 memory with dual-socket Xeon X5675 CPUs (24 threads total) and 94 GB of RAM. I also ensured that the host was not over-utilized and could handle the load. SSH authentication was configured using SSH keys to streamline connections.

Note: Initially, all three systems (including the test initiator) had only 2 CPU cores each, which is close to what many real-world SSH servers might run with. However, batch timings were nearly twice as high with just 2 cores, which is why I increased them to 8 and 6 cores respectively.

## The Test

The test was designed to simulate a heavy workload: it launched 400 parallel `scp` transfers of 1000 KB each, repeated in a loop 100 times. That added up to 40,000 total `scp` calls per run. The goal of the initial run was to establish a performance baseline, without any special SSH tuning.
[See Code](https://github.com/richard-sebos/sebostechnology/tree/main/assets/code/ssh-high-volume)

**Results:**

```
Control Server timing per loop
----------------------------------
Average batch time:   5380.76 ms
Min / Max batch time: 4743 ms / 6055 ms

High Volume Server timing per loop
----------------------------------
Average batch time:   5353.71 ms
Min / Max batch time: 4877 ms / 6192 ms
```

## SSH Configuration Changes

To improve performance on both servers, I modified the `/etc/ssh/sshd_config` file by adjusting the `MaxStartups` setting:

```bash
MaxStartups 500:30:1000
```
Surprisingly, after applying this setting, the batch processing time **increased** significantly:

```
Control Server timing per loop
----------------------------------
Batches:              100
Average batch time:   12405.26 ms
Min / Max batch time: 10412 ms / 12760 ms

High Volume Server timing per loop
----------------------------------
Average batch time:   12397.48 ms
Min / Max batch time: 10542 ms / 12927 ms
```

This change allows the server to handle a much larger number of simultaneous unauthenticated connections and now no connections where being dropped. Without it, users might experience connection drops or delays under heavy load.


At first glance, it looked like performance had degraded. But I soon realized the reason: the default `MaxStartups` setting is much more conservative:

```bash
MaxStartups 10:30:100
```

| Value | Description                                                                                   |
| ----- | --------------------------------------------------------------------------------------------- |
| `10`  | Allows up to 10 **unauthenticated connections** before throttling begins.                     |
| `30`  | Once over 10, starts **randomly dropping** new unauthenticated connections with a 30% chance. |
| `100` | At 100 unauthenticated connections, **drops all new connections** immediately.                |

## System-Level Tuning

The increased batch time wasn’t due to a configuration error. By lifting the default limits, the system was now accepting many more connections, but hitting operating system thresholds for file descriptors and processes.

To fix thi on the highvol host, I made several system-level tuning changes that increased the number of open files and processes allowed per user and for the SSH daemon. These changes are vital in environments with heavy SSH usage, such as:

* Parallel SCP transfers
* Automation frameworks
* Jump host scenarios

This prevented common bottlenecks like "too many open files" or dropped sessions.
[See Changes](https://github.com/richard-sebos/sebostechnology/blob/main/assets/code/System-Changes.md)

After applying the system tuning, I reran the test:

```
Control Server timing per loop
----------------------------------
Average batch time:   12405.26 ms
Min / Max batch time: 10412 ms / 12760 ms

High Volume Server timing per loop
----------------------------------
Average batch time:   12482.49 ms
Min / Max batch time: 10498 ms / 12788 ms
```

Performance was consistent between the two servers, but only marginally improved overall. This made me wonder: Had all this work made any real impact?

## Reevaluating the Bottleneck

After stepping away from the test setup, I had a realization: maybe the true bottleneck wasn’t server tuning—it was the SSH authentication overhead itself.

Each SCP transfer establishes a new SSH session, which requires a full key exchange and authentication. That alone can consume significant time, especially when multiplied across tens of thousands of transfers.

### Enabling SSH Multiplexing

To test this theory, I enabled SSH multiplexing. This allows a single SSH connection to be reused across multiple SCP commands, significantly reducing the overhead of session negotiation.

The results were striking:

```
Control Server timing per loop
----------------------------------
Average batch time:   5292.66 ms
Min / Max batch time: 3805 ms / 6411 ms

High Volume Server timing per loop
----------------------------------
Average batch time:   2068.88 ms
Min / Max batch time: 1979 ms / 2243 ms
```

With multiplexing enabled, the high-volume server saw its average batch time drop by nearly 80%. This clearly showed that the SSH authentication process was the major performance drain—and once optimized, the earlier tuning changes truly began to shine.

## Conclusion

This was an insightful test that led to some unexpected discoveries. The key takeaway: for short-lived connections like SCP transfers, the overhead of SSH authentication can completely overshadow the benefits of backend tuning.

While it’s still essential to optimize SSH for high-concurrency environments, doing so must go hand-in-hand with client-side improvements—such as SSH multiplexing—especially in scenarios with frequent session initiation. In the long run, users with persistent sessions or heavy interactive usage will still benefit from the improved server configuration.

.
