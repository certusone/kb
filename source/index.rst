.. Certus One Knowledge Base documentation master file, created by
   sphinx-quickstart on Tue Sep 25 07:43:02 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Validator Operations Guide
==========================

Running a proof-of-stake validator puts a much greater emphasis on technical correctness, sound
systems architecture, security, and overall operational excellence than most distributed systems.
In a proof-of-stake cryptocurrency, operational skills take the place of raw computational power.
This means that the design process, documentation and knowledge sharing are particularly
important for validator operations.

This guide is a living document which details a set of best practices for running a validator
service as implemented by Certus One, as well as technical background to help you design your
own validator architecture.

The aim of this document is to provide a baseline for validator operations, both to make it easier
for new validators to get started, and to provide input to other teams. We believe that
collaboration and openness strongly benefits the overall ecosystem - the more well-run
validators there are, the more resilient will the network be.

While this document's focus is running blockchain validators, much of its content is
applicable to operating any highly available, distributed service.

While it's hard to provide an implementation that fits all use cases, we try to provide
reference implementations which implement our guidelines.

This guide assumes practical Linux systems administration experience and at least basic knowledge
of the blockchain you're validating on (we recommend reading at least their whitepaper).
For Cosmos, this includes both Tendermint and the Cosmos SDK.

Numerous books have been written about each of the topics in this knowledge base - keep in mind
that a knowledge base like ours is only ever a starting point and a guide, not an exhaustive
treatment of any of the topics we're discussing. We took a look at our bookshelves (and e-readers,
and browser bookmarks) and many articles have a literature list of books and articles
which we can personally recommend.

The document's source code is available `on GitHub <https://github.com/certusone/kb>`_.
Contributions and bug reports/feedback are greatly appreciated (feel free to use the
GitHub issues for discussion as well as bug reports).


Contents
++++++++

.. toctree::
   :maxdepth: 2

   monitoring
   peers
   systems
   security
   linux_config
   validator_ha
   hsm
   key_management
   testing
   building
   business_continuity
