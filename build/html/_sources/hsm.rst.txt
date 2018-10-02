HSM for Signing
===============

To ensure high security of your validator you will want to sign your votes and block proposals using a HSM_.

Why use a HSM_
##############

Intro into Tendermint
~~~~~~~~~~~~~~~~~~~~~

In the Tendermint consensus all validators in the active validator set participate by submitting block proposals and voting on them (using prevotes and precommits).

The vote of your validator is authenticated using a cryptographical signature so that other people know that the vote came from you and no one can mimic you which
would make the consensus system useless.

This coordinated consensus, which is split into several steps, ensures that at least 2/3+ of the validators have the same view_ of the network
since it requires 2/3+ votes for a block in order to finalize it.

With this restriction in place we would assume that it is impossible for two different chains (*forks*) to exist a time 
since it is not possible to get 2 times 2/3+ votes on two conflicting_ blocks in a 3/3 validator set.

----

However this excludes the scenario of double voting/proposing.

In this scenario the byzantine proposer in the consensus round creates two conflicting_ blocks and sends them out to the network.

If we assume that we also have other byzantine actors in the validator set which want to profit from both chains these will also vote for both blocks.

That means that honest nodes in the network could see 2 different blocks at the same height with different contents and hashes.
From this point on the network has **forked**.

Outside viewers of the network will not know which block is correct and from now on there will not be a single truth.
This is the exact scenario we want to prevent with PBFT-like consensus systems.

How Cosmos prevents forks
~~~~~~~~~~~~~~~~~~~~~~~~~

Now that we know the 2 reasons that cause forks:

- Conflicting proposals by the same validator
- Conflicting votes by the same validator

To reduce the causes to a single one we can break it down to **double signing**. Because in order to create
2 conflicting proposals/votes a validator nees to sign 2 consensus messages for the same HRS_ pair with its key.

Tendermint allows other validators to record evidence of byzantine behaviour in blocks. Cosmos makes use of this features and slashes validators
that double sign. At the moment the slashing rate is set to 20% of all bonded Atoms at the moment which is very substantial.

This strict slashing condition makes it extremely important for validators to avoid double signing in order to ensure network security and prevent being slashed.

Problems of the default signing implementation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Lets assume a scenrio in which your validator host is compromised by a malicious actor who wants to financially
hurt you and your *customers* (people staking tokens with you).

If you are using the default FilePV which stores the private key associated with your validator on the file system
the attacker can simply steal the `priv_validator.json` file and from then on have the ability to sign any consensus
message with your validator's key therebye imposing you.

That way the attacker could **double sign** on your behalf triggering the slashing conditions for you forever since at
the moment the validator keys can not be exchanged which would essentially mean that your validator is *ruined*

The solution
~~~~~~~~~~~~

A HSM_ is a separate hardware component that stores keys and if not configured to perform differently will not
allow you to extract the private keys it stores. However it can take data from you and sign/encrypt it.

That way you can store you validator private key on a HSM and not keep it on the filesystem of the validator host.

Using a special software component Tendermint will ask the HSM to sign the consensus message without ever handling
the private key itself.

That way in the before-mentioned scenario the attacker would not be able to extract your private key and he could only
make you double sign as long as he controls your host.

This can be further mitigated by having an encrypted session between Tendermint and the HSM and doing proper secrets management.
With such measures in place it would be harder for a validator to get the HSM to sign data and you would have more time to detect and
mitigate the attack.

HSM implementations
###################

KMS by Tendermint
~~~~~~~~~~~~~~~~~

KMS (Key Management Service) is a reference implementation of pluggable signing modules in a separated software component curated by Tendermint.

.. image:: kms.svg

It uses a separate software component to take care of the signing and implement double signing protection (like keeping track of the last signed messages).

This component communicates with the Tendermint node using a encrypted channel to prevent MITM_ attacks.

Signers are implemented as plugins which makes is very extendible and flexible. Examples of implemented signers include the YubiHSM2, Ledger Nano S and the
traditional file signer mentioned above.

The advantage of running a separate host (or an SGX enclave) for key management is that in case of a validator host compromise your KMS host will remain secure and
the built-in double signing protection in the KMS will prevent it from responding to double signing requests from the compromised validator host.

-----

At the time of writing the KMS service is actively being developed and not yet ready to be used.

You can watch the progress and contribute here: `KMS Github`_

Aiakos by Certus One
~~~~~~~~~~~~~~~~~~~~

While KMS connects to Tendermint via a socket Aiakos is directly integrated in the node at compile time.

Aiakos uses the PrivValidator interface of Tendermint to implement a direct wrapper to the YubiHSM2.

In order to use Aiakos you have to install the Yubico YubiHSM2 connector on your host and patch your Cosmos node source.

Your Cosmos node will then try to connect with the YubiHSM and optionally import a key specified by you to the HSM.
All consensus messages will then be signed using the HSM.

This implementation does not deliver the full security improvements that a separate KMS host brings.

How to setup a Cosmos validator with Aiakos YubiHSM2 support
------------------------------------------------------------

1. **Clone** cosmos sdk version and **checkout** the version you want to use.
2. Open the file `server/start.go`
3. Insert the code in the ``startInProcess`` function before "// create & start tendermint node"

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
  	filepv := privval.LoadOrGenFilePV(cfg.PrivValidatorFile())
  	key := filepv.PrivKey.(ed25519.PrivKeyEd25519)
  	err = hsm.ImportKey(uint16(aiakosSigningKey), key[:32])
  	if err != nil {
  		ctx.Logger.Error("Could not import key to HSM; skipping this step since it probably already exists", "error", err)
  	}
  }

4. Add import for "github.com/certusone/aiakos" to the file's import section.
5. Run `dep ensure -v`
6. Build cosmos as described in the *README*
7. Install the YubiHSM connector_ on the host machine
8. Run the YubiHSM connector (as a service if you wish)
9. Update AuthKeys and generate a Eddsa signing-key on the HSM (optional)

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

--------------

Aiakos' source code can be found here: `Aiakos Github`_

--------------

HSM hardware
############

YubiHSM2
~~~~~~~~

The YubiHSM2 by Yubico is the most commonly used HSM_ among Cosmos validators.

It is quite affordable and offers the needed Eddsa standard which is not covered by many other HSMs.

The HSM runs from a USB port. We recommend you to use an internal USB port for physical security reasons.

.. [#HSM] Hardware Security Module
.. [#view] state of the blockchain, transactions and application
.. [#conflicting] containing different transactions, e.g. double-spending
.. [#HRS] pair of (block-) height, (consensus-) round, (consensus-) step
.. [#byzantine] malicious
.. [#MITM] man-in-the-middle
.. _`KMS Github`: https://github.com/tendermint/kms
.. _connector: https://www.yubico.com/products/services-software/download/yubihsm-2-libraries-and-tools/
.. _`Aiakos Github`: https://github.com/certusone/aiakos