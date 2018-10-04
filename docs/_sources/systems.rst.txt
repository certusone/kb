==============
Systems Design
==============

The key to building and maintaining highly secure and reliable systems is **simplicity** -
a good system will have nothing to take away, rather than nothing to add.

Each component you use you will have to secure, update and debug forever. Like open source
projects which reject code not because it's bad, but because they don't have sufficient
capacaties to maintain it, you need to be very careful about each piece of technology you
introduce into your stack and carefully weight its benefits against the extra complexity it
introduces.

Debugging and securing a system is an order of magnitude more complicated than building it.
There's a common saying that if you build the most clever system you can think of, you're by
definition unqualified to maintain it - and there's a lot of truth to it.

Why not Kubernetes?
-------------------

We've heard about many validators who plan to use Kubernetes for their production setups.

We strongly recommend against the use of Kubernetes and similar technologies for
your core validator operations - they solve problems validator operators don't have.
Validator core infrastructure are **pets, not cattle**. You can't just deploy a cloud instance,
you need to rent dedicated servers and plug HSMs into them. Even if you're running an
active-active setup like ours which tolerate full node outages, you're unlikely to gain enough
from Kubernetes to justify its costs.

Even plain Docker usage should be carefully evaluated - while Docker itself is quite stable, even
in 2018, the overlay filesystems and namespacing technology it uses haven't stabilized yet (not
for lack of trying, but any complicated piece of code in the kernel needs decades to mature;
people are still finding bugs in ext4 to this day). Any large-scale production user of either
Docker and Kubernetes will have tales of Docker daemon crashes in production, weird kernel
issues that required node reboots and scheduler bugs that required them to read the Kubernetes
source code at 3am in the morning. This is perfectly fine for the kind of stateless
infrastructure Docker and Kubernetes are designed for - they are built to tolerate single node
losses, or build systems. In fact, many production deployments can auto-update and reboot
cluster nodes (like CoreOS/Container Linux does).

However, none of this applies to core validator infrastructure. cosmos-sdk compiles to a *single
binary*, you don't need Docker to deploy it (it's quite useful for building it, though).
You're not going to need to scale your validator setup up and down across a fleet of thousands of machines.

Advanced security setups like eBPF seccomp policies, auditing, SELinux policies and just plain
debugging get a lot easier when there are no kernel namespaces, Docker daemons, runC wrappers and
overlay filesystems to reason about.

Both Docker and Kubernetes also add a lot of unnecessary attack surface (properly security
Kubernetes alone is pretty complicated - it's a REST API which hands out omnipotent tokens
which have root access to your nodes - that's the opposite of *defense in depth*!).

Certus One has extensive experience using both Docker, Kubernetes and Red Hat's
OpenShift k8s distribution in production and we're confident that we could pull it off, just
like we have no doubt that other teams will. However, we'd rather spend our time working
on security hardening and tooling.

That being said, we *do* use Kubernetes for our auxiliary infrastructure like our monitoring
stack, continous integration, testing setup and various other internal infrastructure needs. It's
perfect for that - our monitoring stack in particular consists of many small services talking to
each other, and Kubernetes is perfect for that. We just don't want it anywhere where it breaking
could affect the core of our business - running secure validators.
