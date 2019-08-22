HSM for Signing
===============

To ensure high security of your validator, you will want to sign your votes
and block proposals using a HSM_.

Why use a HSM
-------------

Tendermint introduction
~~~~~~~~~~~~~~~~~~~~~~~

In the Tendermint consensus, all validators in the active validator set participate by submitting
block proposals and voting on them (using prevotes and precommits).

The vote of your validator is authenticated using a cryptographic signature,
so that other people know that the vote came from you and no one can impersonate you (which
would break the consensus mechanism).

This coordinated consensus, which is split into several steps, ensures that at least
2/3+ of the validators have the same view_ of the network since it requires 2/3+ votes
for a block in order to finalize it.

With this restriction in place, we would assume that it is impossible for two different
chains (*forks*) to exist a time, since it is not possible to get 2 times 2/3+ votes
on two conflicting_ blocks in a 3/3 validator set.

Double signing
~~~~~~~~~~~~~~

However, this excludes the scenario of double voting/proposing.

In this scenario, the byzantine proposer in the consensus round creates two
conflicting_ blocks and sends them out to the network.

If we assume that we also have other byzantine actors in the validator set
which want to profit from both chains, these will also vote for both blocks.

That means that honest nodes in the network could see 2 different blocks at the same height with different contents and hashes.
From this point on the network has **forked**.

Outside viewers of the network will not know which block is correct and from now on there will not be a single truth.
This is the exact scenario we want to prevent with PBFT-like consensus systems.

How Cosmos prevents forks
~~~~~~~~~~~~~~~~~~~~~~~~~

Now that we know the reason that causes forks:

- Conflicting votes by the same validator

It can be summarized as **double signing**. In order to create
two conflicting votes, a validator needs to sign two consensus messages
for the same HRS_ pair with its key.

Tendermint allows other validators to record evidence of byzantine behaviour in blocks. Cosmos
makes use of this features and slashes validators that double sign. At the moment, the slashing
rate is set to 5% of all bonded Atoms, which is very substantial amount.

This strict slashing condition makes it extremely important for validators to avoid double
signing in order to ensure network security and prevent being slashed.


Problems of the default signing implementation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Lets assume a scenrio in which your validator host is compromised by a malicious actor who wants
to financially hurt you and your *customers* (people staking tokens with you).

If you are using the default *FilePV*, which stores the private key associated with your validator
on the file system, the attacker can compromise your host and steal your `priv_validator.json` file.
From then on, he has the ability to sign any consensus message with your validator's key.

That way, the attacker could **double sign** on your behalf, triggering the slashing conditions for
you forever since validator keys cannot currently be replaced, *ruining your validator*.

For this reason, it's crucial that your validator key cannot be stolen, even if your node is
compromised.

The solution
~~~~~~~~~~~~

A HSM is a separate hardware component that stores keys and - unless configured to perform
differently - will not allow you to extract the private keys it stores. However, it will use the
private key to sign/encrypt data for you.

HSMs use special tamper-proof secure elements which make it extremely hard to extract the secret keys,
even with physical access.

This allows you to store your validator private key on a HSM and not leave it exposed on the filesystem
of the validator host.

Using a special software component, Tendermint will ask the HSM to sign the consensus message without
ever handling the private key itself.

In case of validator compromise, the attacker would not be able to extract your private key and
he could only make you double sign as long as he controls your host.

This can be further mitigated by having an encrypted session between Tendermint and the HSM and
doing proper secrets management. With such measures in place, it would be harder for a validator
to get the HSM to sign arbitrary data and you would have more time to detect and mitigate the attack.

HSM implementations
-------------------

KMS by Tendermint
~~~~~~~~~~~~~~~~~

KMS (Key Management Service) is a reference implementation of pluggable signing modules in a
separate software component, maintained by Tendermint.

.. image:: kms.svg

KMS is a separate process which handles signing and implements double signing protection
(like keeping track of the last signed messages).

This component communicates with the Tendermint node using a encrypted channel
to prevent MITM_ attacks.

Signers are implemented as plugins which makes is very extensible and flexible.
Examples of implemented signers include the YubiHSM2, Ledger Nano S and the
traditional file signer mentioned above.

The advantage of running a separate host (or an SGX enclave) for key management
is that in case of a validator host compromise, your KMS host will remain secure and
the built-in double signing protection in the KMS will prevent it from responding to
double signing requests from the compromised validator host.

At the time of writing, the KMS service is actively being developed and not yet ready to be used.

You can watch the progress and contribute here in the `KMS Github`_ repository.

Aiakos by Certus One
~~~~~~~~~~~~~~~~~~~~

While KMS connects to Tendermint via a socket, `Aiakos <https://github.com/certusone/aiakos>`_
is an in-process signer implementation and compiled into gaiad.
Aiakos uses the PrivValidator interface of Tendermint to implement a direct wrapper to the YubiHSM2.

We also implemented a `YubiHSM Go library <https://github.com/certusone/yubihsm-go>`_.

In order to use Aiakos, you have to install the Yubico YubiHSM2 connector on your host
and apply a small patch your Cosmos node source to register it (a validator should always build
their own cosmos-sdk binaries - see the article on building Cosmos).

Your Cosmos node will then attempt to connect to the YubiHSM and optionally import a key
specified by you to the HSM. All consensus messages will then be signed using the HSM.

We initially designed Aiakos as part of our proprietary JANUS active-active validator,
but it can also be used as a standalone signer. We found the socket interface to be too unreliable,
and KMS not ready for production, so we set out to build a minimal, easily audited YubiHSM 2
PrivValidator. We chose to write it in Go to avoid the extra complexity of using Rust, which we
thought offered little tangible security benefits over Go in this use case.

By being in-process, Aiakos is much more reliable, but slightly less secure than KMS since it
doesn't implement double signing protection in the event of a validator compromise. We decided
that, for now, using the socket interface with the pre-release KMS software poses a greater risk
than the (unlikely, given the minimal attack surface for remote code execution) event of
an attacker somehow compromising the validator host, but not the KMS host unless completely
separate infrastructure is used for KMS.

Tendermint is written in Go, which is a memory-safe language, making remote code execution highly
unlikely. Most threat scenarios would involve a full infrastructure compromise, like a
compromised workstation, supply chain or operating system vendor.

The remaining issue of logic errors which would trick the validator into double signing can be
mitigated using double-signing prevention which we implemented at the JANUS layer.

However, we do believe that high-assurance double-signing prevention is worth pursuing, and we plan
to either switch JANUS to KMS once it's ready, and/or work with the community to improve support for
out-of-process signers and move Aiakas and JANUS to an out-of-process model. That being said, this
will only provide a tangible security advantage if the out-of-process signer itself runs in an
isolated environment like SGX *and* is able to replicate state to standby instances in a
high-availability setup.


How to setup a Cosmos validator with Aiakos YubiHSM2 support
------------------------------------------------------------

1. Clone cosmos-sdk and checkout the version you want to use.
2. Modify the file `server/start.go` and insert this  code in the ``startInProcess`` function,
   before "// create & start tendermint node"

::

  if os.Getenv("AIAKOS_URL") == "" {
  	return nil, errors.New("no Aiakos hsm url specified. Please set AIAKOS_URL in the format host:port")
  }
  aiakosUrl := os.Getenv("AIAKOS_URL")
  if os.Getenv("AIAKOS_SIGNING_KEY") == "" {
  	return nil, errors.New("no Aiakos signing key ID specified. Please set AIAKOS_SIGNING_KEY")
  }
  aiakosSigningKey, err := strconv.ParseUint(os.Getenv("AIAKOS_SIGNING_KEY"), 10, 16)
  if err != nil {
  	return nil, errors.New("invalid Aiakos signing key ID.")
  }
  if os.Getenv("AIAKOS_AUTH_KEY") == "" {
  	return nil, errors.New("no Aiakos auth key ID specified. Please set AIAKOS_AUTH_KEY")
  }
  aiakosAuthKey, err := strconv.ParseUint(os.Getenv("AIAKOS_AUTH_KEY"), 10, 16)
  if err != nil {
  	return nil, errors.New("invalid Aiakos auth key ID.")
  }
  if os.Getenv("AIAKOS_AUTH_KEY_PASSWORD") == "" {
  	return nil, errors.New("no Aiakos auth key password specified. Please set AIAKOS_AUTH_KEY_PASSWORD")
  }
  aiakosAuthPassword := os.Getenv("AIAKOS_AUTH_KEY_PASSWORD")
  // Init Aiakos module
  hsm, err := aiakos.NewAiakosPV(aiakosUrl, uint16(aiakosSigningKey), uint16(aiakosAuthKey), aiakosAuthPassword, ctx.Logger.With("module", "aiakos"))
  if err != nil {
  	return nil, err
  }
  // Start Aiakos
  err = hsm.Start()
  if err != nil {
  	return nil, err
  }
  if os.Getenv("AIAKOS_IMPORT_KEY") == "TRUE" {
  	ctx.Logger.Info("importing private key to Aiakos because AIAKOS_IMPORT_KEY is set.")
  	filepv := pvm.LoadOrGenFilePV(cfg.PrivValidatorFile())
  	key := filepv.PrivKey.(ed25519.PrivKeyEd25519)
  	err = hsm.ImportKey(uint16(aiakosSigningKey), key[:32])
  	if err != nil {
  		ctx.Logger.Error("Could not import key to HSM; skipping this step since it probably already exists", "error", err)
  	}
  }

4. Add import for ``"github.com/certusone/aiakos"``, ``"github.com/tendermint/tendermint/crypto/ed25519"``, 
   ``"os"`` and ``"strconv"`` to the file's import section.
5. Replace ``pvm.LoadOrGenFilePV(cfg.PrivValidatorFile())`` with ``hsm`` (keep the comma at the end of the line)
6. Run `dep ensure -v`
7. Build cosmos as described in the *README*
8. Install the YubiHSM connector_ on the host machine
9. Run the YubiHSM connector (we recommend a sytemd service unit)
10. Update AuthKeys and generate a EdDSA signing-key on the HSM (optional)

Now you can run your Cosmos node with HSM support.

You need to set the following environment variables when running your node:

**AIAKOS_URL**
    The URL of the YubiHSM connector. Usually localhost:12345

**AIAKOS_AUTH_KEY**
    The ID of the Auth Key. Default 1

**AIAKOS_AUTH_KEY_PASSWORD**
    The password of the Auth Key. Default "password"

**AIAKOS_SIGNING_KEY**
    The ID of the signing key. The one you generated before or a free slot.

**AIAKOS_IMPORT_KEY**
    Do you want to import your priv_validator.json to the HSM. "TRUE" if yes

.. todo:: Provide a patchset which applies on top of the latest cosmos-sdk master

HSM hardware
------------

For the sake of diversity, the Cosmos community shoudn't rely on a single HSM
and we hope that more vendors will add EdDSA support to their HSMs.

Aiakos is a great starting point for validators who want to implement a custom signer for a
new type of HSM.

YubiHSM2
~~~~~~~~

The YubiHSM2 by Yubico is the most commonly used HSM among Cosmos validators.

It is quite affordable and is among the (very) few HSMs which supports EdDSA.

The HSM runs from a USB port. We recommend you to use an internal USB port
for better protection against accidental damage as well as physical security considerations.

YubiHSM2 Installation with cosmos-sdk v0.34.7 (cosmoshub-2) on MacOS (Mac Mini)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*by* `MarcelMWS <https://github.com/MarcelMWS>`_

reset YubiHSM Key:

::

  insert the yubihsm and press the ring directly in the direction of the led and hold it for 10 seconds (especially when you think there's no button;))

Install `Software <https://developers.yubico.com/YubiHSM2/Releases/>`_ and set environment(set PATH vars if you want):

::

  package yubihsm2-sdk-2019-03-darwin-amd64.tar.gz: Version 2.0.0 (is inside)

  /Users/(***)/yubihsm2-sdk/bin/.yubihsm-connector -d

Install Rust:

::

  curl https://sh.rustup.rs -sSf | sh

  rustup default 1.37.0

Install:

- C compiler: e.g. gcc, clang
- pkg-config
- libusb (1.0+). Install instructions for common platforms:
  - macOS (Homebrew): ``brew install libusb``

NOTE (x86_64 only): Configure ``RUSTFLAGS`` environment variable:
``export RUSTFLAGS=-Ctarget-feature=+aes,+ssse3``

Install tmkms version: **tmkms 0.4.0**

::

  git clone https://github.com/tendermint/kms.git && cd kms

  cargo install tmkms --features=yubihsm --version=0.4.0


set tmkms.toml in ~/.tmkms dir:

::

  [[providers.yubihsm]]
   adapter = { type = "usb" }
   auth = { key = 1, password = "evil cat ... " }

refer to `tmkms.toml.example <https://github.com/tendermint/kms/blob/master/tmkms.toml.example>`_ if you want (version above should be okay):

Verifying YubiHSM support was included in a build
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

switch to ~/.tmkms dir (with tmkms.toml inside):

Run the following subcommand of the resulting tmkms executable to ensure
that YubiHSM 2 support was compiled-in successfully:

::

  $ tmkms yubihsm help                                                                           127 ↵
  tmkms 0.4.0
  Tony Arcieri <tony@iqlusion.io>, Ismail Khoffi <Ismail.Khoffi@gmail.com>
  Tendermint Key Management System

  USAGE:
    tmkms <SUBCOMMAND>

  FLAGS:
    -h, --help     Prints help information
    -V, --version  Prints version information

  SUBCOMMANDS:
    detect  detect all YubiHSM2 devices connected via USB
    help    show help for the 'yubihsm' subcommand
    keys    key management subcommands
    setup   initial device setup and configuration
    test    perform a signing test

Set environment:

::

  **-Mac-mini:.tmkms ***$ tmkms yubihsm setup
  This process will *ERASE* the configured YubiHSM2 and reinitialize it:

  - YubiHSM serial: *****

  Authentication keys with the following IDs and passwords will be created:

  - key 0x0001: admin:

      evil cat ***

  - authkey 0x0002 [operator]:  kms-operator-password-***
  - authkey 0x0003 [auditor]:   kms-auditor-password-***
  - authkey 0x0004 [validator]: kms-validator-password-***
  - wrapkey 0x0001 [primary]:   ***

  *** Are you SURE you want erase and reinitialize this HSM? (y/N): y
  [WARN] factory resetting HSM device! all data will be lost!
  [INFO] waiting for device reset to complete
  [INFO] installed temporary setup authentication key into slot ***
  [WARN] deleting default authentication key from slot 1
  [INFO] installing role: admin:
  [INFO] installing role: operator:
  [INFO] installing role: auditor:
  [INFO] installing role: validator:
  [INFO] installing wrap key: primary:2
  [INFO] storing provisioning report in opaque object ***
  [WARN] deleting temporary setup authentication key from slot ***
       Success reinitialized YubiHSM (serial: ***)

::

  ***-Mac-mini:.tmkms ***$ tmkms yubihsm keys generate 1
    Generated key #1: cosmosvalconspub1***

::

  tmkms yubihsm keys generate 2
    Generated key #2: cosmosvalconspub1***

::

  tmkms yubihsm keys list
  Listing keys in YubiHSM #***:
  - \#1: cosmosvalconspub1
  - \#2: cosmosvalconspub1

save std_out output above somewhere!!!

start yubihsm-connector:

::

  yubihsm-connetor -d

---

(maybe in another Terminal):

::

  yubihsm-shell

::

  yubihsm> connect
  Session keepalive set up to run every 15 seconds
  yubihsm>


(do not forget to close any session with ``session close 0`` )

---

Set Path Environments with:

::

  export AIAKOS_URL="localhost:12345"
  export AIAKOS_AUTH_KEY="1"
  export AIAKOS_AUTH_KEY_PASSWORD="evil cat ***"
  export AIAKOS_SIGNING_KEY="2"
  export AIAKOS_IMPORT_KEY="FALSE"

  ulimit -n 4096


Change gaiad to custom gaiad (hsm-version)(as described above) located in:

::

  /Users/***/go/bin/gaiad

gaiad start (pay attention if you setup a service (launchctl, systemd, ... to load env vars!!!))

(restore Backup in v0.34.7, if wrong app header hash error)

soft stop gaiad with(not with ctrl+c!):

::

  ps -ax | grep gaiad

read ``pid`` (e.x. 5842)

::

  kill -s 3 <pid> (5842)

.. [#HSM] Hardware Security Module
.. [#view] state of the blockchain, transactions and application
.. [#conflicting] containing different transactions, e.g. double-spending
.. [#HRS] pair of (block-) height, (consensus-) round, (consensus-) step
.. [#byzantine] malicious
.. [#MITM] man-in-the-middle
.. _`KMS Github`: https://github.com/tendermint/kms
.. _connector: https://www.yubico.com/products/services-software/download/yubihsm-2-libraries-and-tools/
.. _`Aiakos Github`: https://github.com/certusone/aiakos
