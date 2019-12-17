# Delegating To Multiple Accounts

This guide describes how to delegate to multiple stake pools.

Before even starting, make sure you have a safe place to store dozens of critical strings such as mnemonics, secret keys, and passwords.

## Restore Snapshot Funds

Your first step is to restore the funds you held on November 29th ([restore_byron_wallet](https://github.com/marimes/Jormungandr-for-Newbs/blob/master/docs/restore_byron_wallet.md)).

Upon successful completion of the restoration, you should have a Shelley wallet. You can check its balance with ```cardano-wallet wallet list```.

## ADA and Lovelaces

1 ADA equals 1 million lovelaces (like 1 Bitcoin equals 100 million satoshis). When you issue commands, please pay attention to whether it expects your input in the form of ADA or in the form of lovelace.

The script `sendADA.sh` makes it quite clear it expects ADA. Other scripts may not tell you in their names but only in the usage text (script --help).

## Setup Account For Delegation

The funds in your restored Shelley wallet consists as UTXOs (unspent transaction outputs). These are great for payments but cannot be used for delegation and rewards collection.

Now let us assume that you hold 100,000 ADAs, and you wish to split them into two accounts so that you can delegate to two separate stake pools.

### Create Accounts

1. First, get your mnemonic words. With these, you can restore everything, your account's secret key, the public key, and the account address.

```cardano-wallet mnemonic generate```

You will see an output such as _frozen mouse vanish ..._. **Store these safely and securely**. 

2. Next, you derive the secret key from these 15 words:

Type ```cardano-wallet mnemonic reward-credentials``` and enter/copy the 15 words from above. I just hit enter on the second factor to leave this blank. You now see your secret key in the terminal. Although the secret key is redundant with the mnemonic words, I also stored it because it is used a lot for signing transactions.

3. Next, you derive the public key

Type ```jcli key to-public``` and enter the above secret key. The output is the public key and needs to be saved, too. The public key is less critical than the secure key, as nobody is able steal your funds using it.

4. Finally, you derive the account address

Type ```jcli address account --testing <public key>```. 

(Repeate steps 1-4 to create a second account).

### Transfer Funds To Reward Accounts

We are going to transfer some of the funds in the restored Shelley wallet to the first of our two newly created accounts.

Type ```cardano-wallet transaction create <wallet-id> --payment <amount_in_lovelace>@<target_address>```. Use ```cardano-wallet wallet list``` to obtain the wallet id. The target address is the account address we have created in step 4.

Now we need to check if the transaction has worked. Enter the target address in the [Cardano Shelley Explorer](https://shelleyexplorer.cardano.org/en/). It may take half a minute or so to show up.

_Note: To send funds from one reward account to another, you cannot use the above wallet command. Instead you will use a script called [sendADA.sh](https://github.com/rdlrt/Alternate-Jormungandr-Testnet/tree/master/scripts/jormu-helper-scripts)._

### Delegation

With our accounts setup and loaded, we can now delegate to our favorite stake pool. In the context of this guide we want to delegate to two distinct stake pools. So we need to selecte two pools. You find them listed in [adapools.org](https://adapools.org) and in [pooltools.io](https://pooltool.io)(here choose itn_rewards_v1). 

Copy the pool IDs of your two favorite pool (looks like ```6f23b9a72c....```).

To delegate to your two favorite pools use the script ```delegate-account.sh```:
- ```~/files/delegate-account.sh <ACCOUNT_SK> <STAKE_POOL_ID_1>:<WEIGHT> <STAKE_POOL_ID_2>:<WEIGHT>``` where <ACCOUNT_SK> is your secret key corresponding to the first account you generated in step 2 above.

Weights are expressed as integers, and are calculated as follows: <WEIGHT> / <SUM_OF_ALL_WEIGHTS>

For instance, delegating to three pools in a ration of 10/30/60:
`~/files/delegate-account.sh <SECRET_KEY> 111:10 222:30 333:60`

`delegate-account.sh` is part of a script collection called [Alternate-Jormungandr-Testnet](https://github.com/rdlrt/Alternate-Jormungandr-Testnet/tree/master/scripts/jormu-helper-scripts).

You can verify the delegation with ```jcli rest v0 account get <account_public_key>``` where the public key is what you have obtained in step 3 above.

