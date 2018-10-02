.. Certus One Knowledge Base documentation master file, created by
   sphinx-quickstart on Tue Sep 25 07:43:02 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Validator Operations Guide
==========================

Running a proof-of-stake validator puts a much greater emphasis on technical correctness, sound
systems architecture, security, and overall operational excellence than most distributed systems
than most applications. In a proof-of-stake cryptocurrency, operational skills take the place of
raw computational power. This means that the design process, documentation and knowledge sharing
are particularly important for validator operations.

This guide is a living document which details a set of best practices for running a validator
service, as implemented by Certus One, as well as technical background to help you design your
own validator architecture.

The aim of this document is to provide a baseline for validator operation, both to make it easier
for new validators to get started, and to provide input to other teams. We believe that
collaboration and openness strongly benefits the overall ecosystem - the more well-run
validators there are, the more resilient will the network be.

While this document's focus is running a Tendermint/Cosmos validator, but much of its content is
applicable to operating any highly available, distributed service.

While it's hard to provide an implementation that fits all use cases, we try to provide
reference implementations which implement our guidelines.

This guide assumes practical Linux systems administration experience and at least basic knowledge
of the Tendermint and Cosmos architecture.

The document's source code is available `on GitHub <https://github.com/certusone/kb>`_.
Contributions and bug reports/feedback are greatly appreciated (feel free to use the
GitHub issues for discussion as well as bug reports).


Contents
++++++++

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   monitoring
   peers
   hsm
   testing
   building
   business_continuity
