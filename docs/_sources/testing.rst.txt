Testing your tooling
====================

It is really important to test changes to your internal tooling as well as your processes
in an environment closely resembling your production setup.

The public gaia testnets can be a good place to become familiar with the basics, but most of the
time, you need greater levels of control over the testing environment than a public testnet can
provide (like a network with byzantine validators, network partitions, packet reordering or
loss).

Certus One has built a full, one-click deployable testnet setup which also includes a complete
monitoring stack. The system built on OpenShift Origin / Kubernetes allows you to spin up a fresh
Cosmos testnet with n nodes/validators within seconds. Our largest single-node testnet had 400
validators and minted millions of blocks before eventually running out of disk space.

.. figure :: testnet.svg 

This allows you to deploy your tools network, iterate on them and run tests in a high-speed network -
by default, the validators are configured to skip the timeout and produce blocks as fast as possible.

You can also simulate special network conditions like double signing by spawning a second instance of a validator
or any other scenario. You have got full control and if something goes wrong you can simply spin up a new network.

Our use of Kubernetes makes our testnet easily extensible and scalable.

Case Study at Certus One
~~~~~~~~~~~~~~~~~~~~~~~~

At Certus One, the Kubernetes testnet has dramatically simplified the integration testing
of our JANUS active/active validator technology.

We are spinning up a custom testnet with JANUS [#janus]_ and Aiakos [#aiakos]_ right from
our internal CI pipeline, allowing us to quickly spot regressions.

This has significantly improved the speed at which we can iterate on our software, while being
confident not to break our production environment.

It also allows to test new dashboards and alerts to elimiate false posives or negative
before we deploy to production. We keep our testnet very close to production, such that every production
component is present to be tested and experimented with.

Due to the nature of it being built on Kubernetes, it also allows to easily deploy it on several
cloud providers as well as bare metal to evaluate performance.

Adding new components is as simple as adding a few lines of Kubernetes deployment config.

How to deploy
~~~~~~~~~~~~~

The source code for the public version of our testnet deployment can be found here: `Testnet Github`_

We have also prepared a video with setup instructions which will also guide you through the features of the setup.

Before watching, you have to setup a Openshift Origin cluster using OpenShift's documentation or our README.

.. raw:: html
    
    <iframe width="630" height="355" src="https://www.useloom.com/embed/c281221bcfb04e4798659618eb15ac88" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

---------

.. [#janus] JANUS is Certus One's proprietary active/active technology
.. [#aiakos] Aiakos is also the name of Certus One's open source YubiHSM2 integration. However in this case it means a proprietary adaption of the KMS system.
.. _`Testnet Github`: https://github.com/certusone/testnet_deploy
