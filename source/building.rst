==============================
Building your tools and Cosmos
==============================

Since there is no official source for binary builds of Cosmos, validators
and users have to build the node and client themselves.

This is *very good* security-wise, and we hope it stays this way. Trusting another party to provide
unaltered binary builds is very dangerous as you cannot easily verify whether the build hasn't been
backdoored. There have been plenty of cases of compromised supply chains in the past [#puush]_.

While Git repositories can also be backdoored, it's a lot harder to do so due to without getting
caught, since the repo is an immutable, replicated ledger (almost like - hah - a blockchain!) as
long as the repository is regularly pulled by contributors.

*Docker containers*: Docker containers (even with automatic builds) are no exception, in fact,
while Docker support signatures, containers aren't usually signed and Docker does not enforce
signature verification by default.

In this chapter, we will explain how to perform simple and reproducible builds of Cosmos'
gaiad and gaiacli as well as to maintain your own patches on top of the upstream sources.

Performing reproducible builds
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Reproducible builds ensure that two parties which build the same binary from the same source will
get an identical binary. This makes it a lot easier to trust third party binaries, since they can
be independently verified. It also makes it easier to trust your *own* builds.

Go makes this particularly easy - Go builds are reproducible by default, as long as your build
environment (including the compiler version and GOPATH) are identical.

By pinning the exact version of each dependency, we can ensure identical build inputs.

.. todo :: Explain why reproducible builds are important and add a simple guide to use the buildscripts

Here you can find example build scripts for reproducible Cosmos builds: `Certus Build scripts`_

Maintaining a mirror/fork
~~~~~~~~~~~~~~~~~~~~~~~~~

In order to be able to easily carry patches and check the authenticity of the Cosmos
repository, we always build from our local mirror of the cosmos-sdk repository (which also comes in
handy when GitHub is down).

Sometimes it might be necessary for you to apply small patchsets to the Cosmos node,
for features like our custom HSM signer (:doc:`hsm`), modifications to the peer discovery code,
or emergency bugfixes for exploits that you can't wait for the upstream team to patch because they're
causing monetary losses *right now*.

Even if you don't plan to run a Cosmos fork most of the time, you should be prepared to do so
on a short notice, if necessary.

A plain mirror can simply be turned into a fork by just committing on top of the master,
and doing rebases against origin/master when there's a new release.

We don't recommend forking the code base unnecessarily - most of the time, it's much better to
create a PR against the upstream repository. However, you sometimes need to maintain internal
modifications - if you do so, try to keep them as small, nonintrosive and self-contained as possible,
and in places where the code doesn't change often to avoid large merge conflicts when rebasing onto
upstream master.

This article is a great introduction on how to maintain a fork: `How to maintain a fork`_

For the Cosmos use-case, it might also make sense to mirror/fork Tendermint.
You will need to add a ``[source]`` directive to the ``Gopkg.toml`` in the cosmos-sdk project
to pull your Tendermint fork, and either commit the modified lockfile to your cosmos-sdk repo
or do a full `dep ensure` run at build time (not recommended).

.. [#puush] The puush hack, for instance https://imgur.com/qqjokYm
.. _`How to maintain a fork`: https://rhonabwy.com/2016/04/04/how-to-maintain-a-git-remote-fork/
.. _`Certus Build scripts`: https://github.com/certusone/buildscripts
