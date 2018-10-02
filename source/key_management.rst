Key Management
==============

For validator operations you need 2 types of keys in the Cosmos network.

**Validator Key**
    As discussed in :doc:`hsm` this key is used by your nodes to participate in the consensus.

**Account Key**
    The key for your Cosmos account. This account holds your Validator's balances and claim rights for rewards.
    This is the account you initially bonded your validator with and can also unbond it with.
    
As the handling of the *Validator Key* has already been handled by the above-mentioned article we will now
focus on the *Account Key*.

Handling of the Account Key
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Account Key is required once to initially bond your validator.

Afterwards in validator operations it is only needed to:

- Vote on governance proposals
- Create governance proposals from your validator's identity
- Unbond your validator's self-bond
- Unrevoke the validator
- Bond more ATOMs from the validator's balance
- Transfer ATOMs from your validator's balance (if they are stored in the validator account)
- Modify validator details (moniker, commission)
- Sign any transaction from this account

As we can see the key is needed for many important validator tasks.

Some of these look easy to automate like voting on governance and bonding rewards.

However if we look at the capabilities of the key something should catch your eyes. The key has the capability to unbond your validator's self-bond,
modify the validator and transfer funds.

This makes the account key very critical since it basically indicates the ownership of the validator. So we need to think about how to **protect** the key.

---------

It quickly becomes apparent that you don't want to keep this key on an online machine - especially not stored on a normal machine like in the (encrypted) format of gaiacli.

.. image :: ledger.jpg

.. raw:: html
    
    <a href="https://www.flickr.com/photos/kndynt2099/38807488710/in/photostream/" target="_blank">"IMG_7984"</a> by Dennis Amith is licensed under <a href="http://creativecommons.org/licenses/by-nc/4.0" target="_blank">CC BY-NC 4.0</a>

A possibility introduced by the Cosmos Team is the **Ledger Nano S**. It is a hardware wallet that stores the private key of your validator account just like
a HSM without any possibility for you to extract the key (except a backup phrase).

Support for the Ledger is built into the latest version of ``gaiacli``. However the `Ledger App`_ is still not in the public application store and has to be
installed manually.

In order to sign a transaction or message you need to click a physical button on the Ledger and are also able to check the authenticity of the 
transaction content on the display to prevent any attacks even on a compromised system.

The added security is basically a **no-brainer** for every validator since losing the key basically means the *death* of the validator's business.

Drawbacks
---------

The need to physically interact with the Ledger makes it *almost* impossible to automate any of these tasks like auto-bonding or governance participation.

But since the slashing for governance participation was removed [#governance]_ automatic participation is not necessary since the voting period
will be long enough for human interaction which is nonetheless necessary because the validator will want carefully assess each goverannce proposal.

Considering the added security and potential consequences that would otherwise arise from a compromised host drawbacks like no being able can be neglected.
Especially because bonding can be performed manually on a regular basis without huge disadvantages profit-wise.

.. [#governance] https://github.com/cosmos/cosmos-sdk/pull/2395
.. _`Ledger App`: https://github.com/cosmos/ledger-cosmos