The Tendermint P2P Layer - Improving operations
===============================================

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
    will persistently try to redial the node if the connection fails. That
    is for example useful for the connection between Validator and Sentry
    nodes because they will immediately try to reconnect after a connection
    failure and there is no scenario where they could land in a
    unjustifiably long backoff or generally be removed from the peers
    addressbook which could cause unforseen issues in a Sentry-architecture.

**Seeds** 
    Seed nodes are only there to provide an up-to-date list of
    peers of the network. If a node is configured to run as a seed node it
    will actively search the network for new peers and store them in the
    addressbook. However it will not maintain active connections with the
    peers it queries. Connectinos from a seed node are meant to be
    short-lived in order to just query the other peers addressbook, learn
    about its new peers and then disconnect again. If you specifiy a
    seednode in the config of your node it will try to dial it on start to
    get an updated addressbook and get a list of peers on the network to
    bootstrap its connections.

Addressbook
~~~~~~~~~~~

From the moment the node has acquired a list of peers on the network it
will store them in a weighted *addressbook*.

This addressbook stores all peers the client has ever learned about (and
possibly connected to). When a connection to a peer fails however, this
is marked in the addressbook and will lead to a backoff in a possible
attempt to reconnect. If a peer connection fails for more than x times
(where x is a constant hardcoded in Tendermint at the moment) the peer
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
    (because of persistent peers, manual dialing or the PEX rector) is an
    outbound connection. In order to establish an outbound connection the
    P2P port does not have to be opened as long as outbound connections are
    allowed by firewall rules.

The peer reactor
----------------

Depending on whether you have a normal or seed node the PEX (peer
exchange) reactor will execute the following loop regularly.

Normal peer
~~~~~~~~~~~

Startup
^^^^^^^

The node will check its addressbook for valid peers to connect to and
connect to all of the persistent peers specified. If the addresbook is
empty it will try to connect to on of the specified nodes.

Loop
^^^^

In the peer exchange routine the node will try to connect to new nodes
from its addressbook until it has reached the ``max_num_outbound_peers``
(as of tendermint #6fad8eaf5a7d82000c3f2933ec61e0f3917d07cf).

It will also query a random peer for its addressbook if the addressbook
of itself is not yet “full” (currently 1000 entries).

Seed node
~~~~~~~~~

Startup
^^^^^^^

*as with a normal node*

Loop
^^^^

The node will try to cleanup its connections by closing every connection
that has been checked to be healthy.

Then it will try to connect to all its known peers from the addressbook
and ask them for their addressbook.

This behaviour intends to get a picture of the network that contains
almost every public node available in order to allow new nodes to easily
bootstrap using an up-to-date addressbook.

Operation Notes
---------------

There are several possibilities of improving your operations that result
from what you have learned above.

Running outbound only nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~

In order to reduce your DDoS surface you might want to run outbound only
nodes.

The advantage of Outbound only nodes is that you only allow connections
that are originating from your node on the Loadbalancing/Firewall layer
(see Network Topology). That way your node is not publicly reachable
from the internet except from the TCP sessions that you have established
with your peers. This only allows DoS attacks over these TCP sessions
which almost elimitates the whole surface as it is almost impossible to
perform a L3 attack with such limitations in place. Depending on your
way of selecting peers it can also reduce the surface for L7
(application layer) attacks.

Additional safety measures could be to announce a wrong IP using PEX to
irritate all nodes except those you are connecting to. That way only the
peers you have established connections with will know your true IP.

However this also increases the importance of having uncompromised peers
because other peers of potentially good actors on the network won’t be
able to connect to you and if your maximum number of outbound peers is
filled with compromised peers you will only see these nodes and no
others as we have learned above. Such a compromise may allow an attacker
to alter your image of the network rendring you unable to catch up for
example.

So it’s very important to (either): 

- Set a high number of outgoing peers 
- Add at least some trusted persistent peers 
- Implement additional measures to either select peers or rotate peers on a regular basis

**Warning**

If your firewall is misconfigured or you are announcing a
wrong public IP (e.g. your internal Docker IP) your node will be
*outbound-only* unintentionally since no other nodes can connect from
the outside (assuming you are not configured as persistent peer using
your true IP). This can result in slow syncing and missed blocks due to
delays in consensus message gossip if you don’t apply the above
mentioned optimizations.

**Notice**

Outbound-only peers are meant as an additional measure to
protect your validator from DDoS and similar attacks. However running
only outbound peers can cause network partitioning, slow bootstrapping
for new network participants and general network destabilization. Plase
make sure that you run only a small portion of your sentries in an
outbound-only configuration to ensure the overall quality of the
network.

Running “full-duplex” nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Full-Duplex or inbound/outbound nodes are the default configuration for
nodes. They allow both inbound connections to be established from the
outside as well as outbound connections to be made.

In order to run a full-duplex node your firewall needs to be opened for
both in- and outbound traffic on the relevant port (26656 by default).

Since the host can be reached from the public internet the risk for DDoS
is higher. However this configuration allows new peers to establish
connections with them and thereby benefits the overall network.

Please keep in mind to set you maximum inbound peer number in the config
appropriately to get a better view of the network.

Private nodes
~~~~~~~~~~~~~

Private nodes run on a VPN and allow only selected peers to establish
connections with them. Such a configuration could be used for
validator-validator private peerings.

In order to not leak any information about the node, it can be run with
PEX disabled and the peering with the other nodes hardcoded as
*persistent peer*.

Sentry-Auto-Scaling
-------------------

*Gotcha* ... Sentry-Auto-Scaling isn't actually the best solution to protect yourself against DDoS attacks.

Even though it might appear obvious that *Sentry-Auto-Scaling* is *the* solution
to mitigate DDoS attacks it is actually a quite **weak** and **expensive** countermeasure and here is why:

Let's first take a look at potential DoS vectors of your validator:

**L7 - Application Layer**:
    Vulnerabilities in Tendermint or the Cosmos SDK can allow an attacker to slow or take your
    nodes down with little effort and bandwidth. Traditional DDoS solutions will mostly not be
    able to mitigate this.

**L2/3 - Protocol Layer**:
    Attacks with a high amount of bandwidth / high amounts of sockets which are aiming to saturate 
    the network interface of your hosts and take them down in this way.

So let's see which of them could be handled by Auto-Scaling:

-------

**L7 Attacks** cannot be mitigated by creating more nodes. Since there are no high resource requirements on the attacker side
they can just continue attacking the new node thereby taking it down as well which would trigger the creation of a new node
in an auto-scaling environment. In the end that leads to extremely expensive scaling and can quickly exhaust/explode a validator's
budget on a cloud platform. To prevent this one would have to exclude "is-up" / latency as an auto-scaling metric.

So what about **L2/3 attacks**? 

If your Sentry nodes are getting attacked by massive amounts of bandwidth they will suffer and once the network
interface or uplink is saturated (which is provider/hardware specific) it will start to drop packets which renders your host unreachable
or simply "down".

That way an attacker can take your sentries down and prevent you from participating in Consensus. Which you want to avoid.

Auto-Scaling of sentries *can* help in that situation as you would just spawn more Sentries until the DDoS bandwidth of your attacker is depleted.

The issue is that this requires a lot of resources on your side. Spawning up nodes to match the bandwidth of the attacker can be quite expensive,
especially over longer periods of time. While you might remain online during the attack, the attacker is still in a cost-wise "hijack" scenario and could
potentially blackmail you.

Also in order to quickly scale up Cosmos nodes you need to have snapshotting of the blockchain data in place because it would take very long for it to
sync with the network. That is another point of failure in case of such an attack especially considering the growing size of the blockchain.

-------------

Considering this added complexity and cost-factor let's look at alternatives:

One of the very obvious alternatives and additional security measures is **outbound-only nodes**.
These are configured to not accept any incoming connections on the *Firewall/Load balancer* layer (e.g. GCP Global LB or AWS Network ELB).
These mostly distributed layers can handle bandwidths in excess of most realistic DDoS attacks in a single AZ so you are not limited by your sentry's interface.
Additionally chances are that your attacker does not even know the IP address of the node since it only initiates a limited amount of outbound connections.
This can further be stripped down to a selected set of peers to further increase security which ultimately leads us to *private peers*.

With private peers in place you have got nodes that are not publicly known and in the best case (with potential direct *in-cloud peerings*) expose almost no surface
for DDoS attacks.

    So at this point we already almost eliminated the attack surface for potential DDoS attacks.

If however still an attacker should be able to attack all of these targets the before-mentioned Loadbalancers which do TCP-termination will
first increase the resource requirements for an attack since UDP can be blocked and this way attackers would have to establish stateful connections.

Additionally there are plenty of established vendors providing DDoS protection solutions (some hosters even by default).
With such protection in place the risk for DDoS attacks can be reduced to a minimum.

So to sum it up we will implement the following protection measurements:

- Outbound-only sentrys
- Private Sentrys
- Global Load Balancers of cloud providers to terminate TCP and filter some DDoS traffic (like UDP)
- Additional DDoS protection services and hardware

of which many can be combined to increase security.

In the end with such a level of protection there is almost no need for a complex (error-prone) and expensive auto-scaling solution.