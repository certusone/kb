Testing your tooling
====================

It is really important to test changes to your internal tooling as well as your processes
in an environment close to production.

The public gaia testnets can be a good place to try these kind of things out but most of the
time you need more control and need to introduce very special enviroments like a network
with byzantine validators or very bad networking.

Certus One has built a full, one-click deployable testnet setup which also includes a complete
monitoring stack. The system built on OpenShift Origin / Kubernetes allows you to spin up a fresh
Cosmos testnet with n nodes/validators in seconds.

.. figure :: testnet.svg 

That way you can deploy your tools in the network and test how they work in a really fast network since
by default the validators are configured to skip the timeout and produce blocks as fast as possible.

You can also simulate special network conditions like double signing by spawning a second instance of a validator
or any other scenario. You have got full control and if something goes wrong you can simply spin up a new network.

Case Study at Certus One
~~~~~~~~~~~~~~~~~~~~~~~~

At Certus One the testnet has simplified the integration tests of our active/active validator technology a lot.

We are spinning up a custom testnet with JANUS [#janus]_ and Aiakos [#aiakos]_ built right in the deployment and let it run in different conditions.

This helped us make the system really reliable and ensure that no commit breaks our production environment.

It also allows to test new dashboards, alerts and their meaningfulness. Since the testnet contains a full production like environment every component is in
place to be tested and experimented with.

Due to the nature of it being built on Kubernetes it also allows to easily deploy it on several cloud providers as well as bare metal to evaluate performance.
Also new components can be added by adding a few lines of Kubernetes deployment config.

How to deploy
~~~~~~~~~~~~~

The source code for the deployment can be found here: `Testnet Github`_

We have also prepared a video with setup instructions.

Before watching you have to setup a Openshift Origin cluster using OpenShift's documentation or our README.

**Warning**: We recommend to setup the Openshift Origin cluster using Ansible rather than ``oc cluster up`` since that is mostly untested and can cause
issues.

.. raw:: html
    
    <iframe width="630" height="355" src="https://www.useloom.com/embed/c281221bcfb04e4798659618eb15ac88" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

---------

.. [#janus] JANUS is Certus One's proprietary active/active technology
.. [#aiakos] Aiakos is also the name of Certus One's open source YubiHSM2 integration. However in this case it means a proprietary adaption of the KMS system.
.. _`Testnet Github`: https://github.com/certusone/testnet_deploy