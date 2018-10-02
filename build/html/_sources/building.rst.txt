Building your tools and Cosmos
##############################

Since there is no official source for binary builds of Cosmos, validators and users have to build the node and client themselves.

This is *very good* security-wise since trusting another party to provide unaltered binary builds is very dangerous as you cannot
easily verify whether the build was really built from unmodified source. There have been enough cases of hacked distribution systems [#puush]_
to make the choice to perform own builds the obvious one.

*Docker containers*: For docker containers (even with automatic builds) the same rule applies since the repository or owner account could be compromised.

In this chapter we will explain how to perform simple and reproducible builds of Cosmos' gaiad and gaiacli as well as quickly
patch the programs by maintaining a mirror/fork.

Performing reproducible builds
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

TODO: Leo

Here you can find example build scripts for reproducible Cosmos builds.

Maintaining a mirror/fork
~~~~~~~~~~~~~~~~~~~~~~~~~

In order to be able to quickly perform patches and check the authenticity of the Cosmos repository we will maintain a remote mirror
of the source code. This can also turn out to be helpful when GitHub should be down for some reason.

Sometimes it might be necessary for you to apply small patchsets to the Cosmos node for example if you are using a modified
communication and peer discovery system for your sentry<->validators or you are under attack and don't want to wait until
the team provides a patch for it since the attack is causing you *monetary damage*.

All of these scenarios plus many more make it really useful to have a mirror and to have one's buildscripts configured on the said one.
The plain mirror can simply be turned into a fork in which you have an additional patchset which is always rebased on the new source from the upstream.

Generally it is recommend that you don't make modifications to the upstream code and maintain them in a fork if you could also create a PR on the upstream
project. But if you need to maintain internal modifications try to keep them as small as possible and in places where the code doesn't change often to avoid
conflicts when rebasing onto upstream changes.

Here you can find a very extensive guide about maintaining a fork: `How to maintain a fork`_

For the Cosmos use-case it might also make sense to mirror/fork Tendermint. Then you will need to add a ``[source]`` directive to the ``Gopkg.toml`` and update the
dep lock which would add the necessity to maintain this change on the Cosmos project. Alternatively you can perform this patch at build time. 


.. [#puush] The puush hack for example https://imgur.com/qqjokYm
.. _`How to maintain a fork`: https://rhonabwy.com/2016/04/04/how-to-maintain-a-git-remote-fork/