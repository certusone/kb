Tendermint P2P Layer
====================

This article explains the Tendermint P2P Layer and many of its gotchas.
Understanding the P2P Layer has been very important us, since it has important
systems architecture implications.

Intro
-----

The Tendermint P2P implementation is based on a relatively simple
concept.

Types of peers
~~~~~~~~~~~~~~

Each node in the network is configured to dial a set of ``seed`` and
``persistentPeers`` when it is first started. Both of these parameters
can be set in the config.

**Persistent peers** 
    The Tendermint node will try to maintain a permanent
    connection with this peer during its runtime. That also means that it
    will persistently try to redial the node if the connection fails. This
    is for example useful for the connection between Validator and Sentry
    nodes, because they will immediately try to reconnect after a connection
    failure, and there is no scenario where they could be stuck in a
    unreasonably long backoff or generally be removed from the peers
    addressbook which could cause unforeseen issues in a Sentry architecture.

**Seeds** 
    Seed nodes are only there to provide an up-to-date list of
    peers of the network. If a node is configured to run as a seed node, it
    will actively search the network for new peers and store them in its
    addressbook. However, it will not maintain active connections with the
    peers it queries. Connections from a seed node are meant to be
    short-lived in order to just query the other peers addressbook, learn
    about its new peers and then disconnect again. If you specify a
    seed node in the config of your node it will try to dial it on startup to
    retrieve an up-to-date addressbook as well as a list of peers on the network to
    bootstrap its connections.

Addressbook
~~~~~~~~~~~

From the moment the node has acquired a list of peers on the network it
will store them in a weighted *addressbook*.

This addressbook stores all peers the client has ever learned about (and
possibly connected to). When a connection to a peer fails, this
is marked in the addressbook and will lead to a backoff before the next
reconnection attempt is made. If a peer connection fails for more than *x* times
(where *x* is a constant hardcoded in Tendermint at the moment), the peer
is marked as bad and removed from the addressbook.

Connection Types
~~~~~~~~~~~~~~~~

**Inbound connection**
    Every connection that was initiated by another peer
    which contacted our node from the outside is called an inbound
    connection. The number of maximum inbound connections can be specified
    with ``max_num_inbound_peers``. In order for another peer to create a
    connection to our node our P2P port (26656 by default) has to be
    publicly exposed.

**Outbound connection**
    Every connection that was initiated by our peer
    (because of persistent peers, manual dialing or the PEX reactor) is an
    outbound connection. In order to establish an outbound connection the
    P2P port does not have to be opened as long as outbound connections are
    allowed by firewall rules.

The peer reactor
----------------

Depending on whether you have a normal or seed node, the PEX (peer
exchange) reactor will execute the following loop regularly.

Normal peer
~~~~~~~~~~~

Startup
^^^^^^^

The node will check its addressbook for valid peers to connect to and
connect to all of the persistent peers specified. If the addressbook is
empty, it will try to connect to one of the specified nodes.

Loop
^^^^

In the peer exchange routine the node will try to connect to new nodes
from its addressbook until it has reached the ``max_num_outbound_peers``
(as of tendermint commit `6fad8eaf5`_).

It will also query a random peer for its addressbook if the addressbook
of itself is not yet “full” (currently 1000 entries).

.. _6fad8eaf5: https://github.com/tendermint/tendermint/commit/6fad8eaf5a7d82000c3f2933ec61e0f3917d07cf

Seed node
~~~~~~~~~

Startup
^^^^^^^

*as with a normal node*

Loop
^^^^

The node will try to clean up its connections by closing every connection
that has been found to be healthy.

Then, it will attempt to connect to all its known peers from the addressbook
and ask them for their addressbook.

This behaviour intends to get a picture of the network that contains
almost every public node available in order to allow new nodes to easily
bootstrap using an up-to-date addressbook.

Operation Notes
---------------

Knowing all of this, there are a number of different ways to improve your
network's resilience by taking advantage of how the P2P reactor works.

Running outbound only nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~

In order to reduce your DDoS attack surface you might want to run outbound only
sentry nodes.

Outbound only nodes behind a stateful firewall - that is, any firewall that isn't a
simple router ACL - allow you to completely drop incoming connections, permitting only
packets belonging to existing sessions.
That way, your node is not publicly reachable
from the internet except for the TCP sessions that you have established
with your peers. This greatly reduces the attack surface for network-layer
attacks. Depending on your peer selection policy, it can also reduce the
attack surface for L7 (application layer) attacks by only connecting to
trusted nodes.

With global TCP load balancers like Google Cloud and CloudFlare Spectrum,
the stateful firewall is moved closer to the providers edge points of
presence (PoPs), allowing you to absorb large denial-of-service attacks (the provider
will drop unknown packets right when they enter their network, distributing
attack traffic across their PoPs rather than congesting the single availability
zone your application is running in).

Additional safety measures could be to announce a wrong IP using PEX, which
confuses nodes other than those those you are connecting to. That way, only the
peers you have established connections with will know your true IP.

However, this also increases the importance of having uncompromised peers
because other peers of potentially good actors on the network won’t be
able to connect to you and if your maximum number of outbound peers is
filled with compromised peers, you will only see these nodes and no
others as we have learned above. Such a compromise may allow an attacker
to alter your view of the network, rendering you unable to catch up with the
network or even cause your node to exhibit byzantine behaviour,
if it's in a vulnerable state.

So it’s very important to (either): 

- Set a high number of outgoing peers 
- Add at least some trusted persistent peers 
- Implement additional measures to either select peers or rotate peers on a regular basis

.. warning::

  If your firewall is misconfigured or you are announcing a
  wrong public IP (e.g. your internal Docker IP) your node will be
  *outbound-only* unintentionally since no other nodes can connect from
  the outside (assuming you are not configured as persistent peer using
  your true IP). This can result in slow syncing and missed blocks due to
  delays in consensus message gossip, unless you apply the
  optimizations noted above.

.. note::

  Outbound-only peers are meant as an additional measure to
  protect your validator from DDoS and similar attacks. However, running
  only outbound peers can cause network partitioning, slow bootstrapping
  for new network participants and general network destabilization. Plase
  make sure that you run only a small portion of your sentries in an
  outbound-only configuration to ensure the overall quality of the
  network.

Running “full-duplex” nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Full-Duplex or inbound/outbound nodes are the default configuration for
nodes. They allow both inbound connections to be established from the
outside as well as outbound connections.

In order to run a full-duplex node your firewall needs to be opened for
both in- and outbound traffic on the relevant port (26656 by default).

Since the host can be reached from the public internet, the risk for DDoS
is higher. However, this configuration allows new peers to establish
connections with them and thereby increases the overall network's resilience.

You should run most of your sentries as "full-duplex" nodes.

Please keep in mind to set your number pf maximum inbound peers in the config
file to an appropriate value to get a better view of the network.

Private nodes
~~~~~~~~~~~~~

Private nodes communicate via VPN or other private networks and allow only selected peers
to establish connections with them. Such a configuration could be used for
validator-validator private peerings.

In order to not leak any information about the node, it can be run with
PEX disabled and the peering with the other nodes hardcoded as
*persistent peer*.

The Sentry architecture
=======================

In order to deploy multiple different kinds of nodes, as described above, in our network and
combine their strengths we need an additional layer besides our single validator node (or
multiple validator nodes).

In order to effectively mitigate DDoS attacks we also don't want to publicly expose our validator
nodes (IPs) to the internet.

This is implemented in an architecture developed by the Tendermint/Cosmos team called *Sentry node architecture*.

While the validators reside in a Virtual Private Network (like it's e.g. offered by many cloud providers) or actual private network that is disconnected from the internet
our Sentries basically build a *proxy* layer between this network and the public internet / cosmos network.

*Sentry* nodes are full cosmos nodes whose only task it is to relay messages and blocks to the validator nodes.

This is done by assigning the Sentry nodes both a public and private interface and hardcoding the validator nodes as persistent peers.
The PEX reactor is limited in a way to not broadcast the validator nodes to the other public peers in the network.

As a result no network participant will ever have a direct connection with one of our validator nodes and will therefore also not be able to DDoS these directly. The Sentry nodes form a shielding layer and are
not limited in their number since they only act as a proxy and have no special *stateful* task like signing. New nodes can be added and removed at any time as long as a minimum amount is kept online.

To learn more about the Sentry architecture and how to configure your nodes accordingly look at the `Cosmos Docs`_.

.. _`Cosmos Docs`: https://cosmos.network/docs/validators/security.html#sentry-nodes-ddos-protection

Sentry-Auto-Scaling
===================

*Actually*... Sentry Auto Scaling isn't the best way to protect yourself against DDoS attacks,
and Certus One is investing in proper DDoS protection rather than sentry scale-out.

Autoscaling is a common and successful defense against application-layer DDoS in webservers
and APIs - you just outnumber the attacker by responding to every single of their requests.

It might seem obvious to apply the same approach to sentry nodes, however, it's less effective
and more expensive than you might expect.

Let's first take a look at potential DDoS vectors of your validator:

**L7 - Application Layer**:
    Vulnerabilities in Tendermint or the Cosmos SDK can allow an attacker to slow or take your
    nodes down with little effort and bandwidth. Traditional DDoS solutions will mostly not be
    able to mitigate this since they lack protocol-level insight.

**L4 - Protocol Layer**:
    SYN floods and similar attacks which aim to overwhelm your load balancer or operating system
    or fill up its flow tracking tables.

**L2/3 - Network Layer**
    Large-scale high-bandwidth reflection attacks which aim to saturate
    the network interface of your hosts, or provider, or even your provider's provider (it happens).

Now, how does autoscaling mitigate these?

**L7 attacks** cannot be mitigated by creating more nodes. Since there are no high bandwidth
requirements on the attacker side, they can just continue attacking each new node, taking it down
as well which would trigger the creation of more new nodes in an auto-scaling environment. It's
not much of a difference to them whether they need to attack 100 or 200 nodes, but it makes a
huge difference to you. It won't get you anywhere, but will get really expensive, really fast
(which might be all the attacker wants, anyway).

To prevent this, one would need sophisticated auto-scaling algorithms which stops scaling up if new
nodes quickly stop responding.

So what about **L2/3/4 attacks**?

If your sentry nodes are getting attacked by large amplification attacks (which are easily in the
>100 Gpbs range), they will be down immediately - all it takes is 1-2 Gbits. Your provider is
probably going to nullroute your IP, preventing the attacker from taking down the provider's
network, sacrificing your IP for the greater good. On the other hand, if your provider is
experienced in mitigating DDoS attacks and has sufficient bandwidth, he will easily be able to
mitigate the attacks. They are straight-forward to filter (fixed source port).

The same goes for SYN floods - they either kill your node right away, or are easily defeated or rate
limited to insignificance by a competent provider or even a cloud provider's TCP proxy
(see above - GCE and CloudFlare can both proxy TCP connections).

Auto scaling of sentries *can* help with volumetric attacks, as you would just spawn more sentries until
the attacker no longer has sufficient capacities to attack all of them.

The issue is that this requires a lot of resources on your side. Spawning up nodes to match the
bandwidth of the attacker can be quite expensive, especially over longer periods of time. While
you might remain online during the attack, the attacker is still having the financial upper hand
and could potentially blackmail you (he's not paying for the compromised servers he's using!).

In order to quickly scale up Cosmos nodes you need to have snapshots of the blockchain
data in place because it would take very long for it to sync with the network. That is another
point of failure in case of such an attack especially considering the growing size of the
blockchain and the extra infrastructure you need. Even with recent snapshots, it will take
a while for you new node to catch up.

What else to do?

One of the very obvious alternatives and additional security measures is **outbound-only nodes**
as described above, in combination with a global TCP proxy like GCE's global LB or CloudFlare
Spectrum. These can handle bandwidths in excess of most realistic DDoS attacks, without any of
the traffic reaching your sentry node. Additionally, chances are that your attacker do not even
know the IP address of the node since it only initiates a limited amount of outbound connections
. This can further be stripped down to a selected set of peers to further increase security
which ultimately leads us to *private peers*.

With **private peers** in place, you have got nodes that are not publicly known and in the best case
(with potential direct *in-cloud peerings* or private network interconnects) expose almost no external
attack surface. An attacker would have to take down all of the other validators you peer with to
prevent them from relaying your messages.

This eliminates most of the DDoS threat - an attacker would have to overwhelm Google's TCP proxy or
CloudFlare spectrum as well as all of your private peers. If he even misses a single node, your
validator will still be functional.

We recommend you invest your time into advanced DDoS mitigation setups, good relationships with
other validators and a diverse set of sentries running at different providers rather than
building a less effective, but complex cloud autoscaling mechanism.
