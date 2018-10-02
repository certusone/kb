.. Certus One Knowledge Base documentation master file, created by
   sphinx-quickstart on Tue Sep 25 07:43:02 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Validator Operations Guide
==========================

This guide is a living document which details a set of best practices for
running a validator service, as implemented by Certus One. Running a validator
puts a much greater emphasis on technical correctness, sound systems architecture,
security, and overall operational excellence.

The aim of this document is to provide a baseline for validator operation, both to
make it easier for new validators to get started, and to provide input to other
teams. We believe that collaboration and openness strongly benefits the overall
ecosystem - the more well-run validators there are, the more resilient will the
network be.

While this document's focus is running a `Cosmos`_ validator, but most of its
content is applicable to operating any highly available, distributed service.

The document's source code is available on `GitHub`_.
Contributions are greatly appreciated.

While it's hard to provide an implementation that fits all use cases, we usually
provide reference implementations which implement our guidelines.

.. _GitHub: https://github.com/certusone/kb
.. _Cosmos: https://cosmos.network

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
