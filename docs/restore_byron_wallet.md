-- DISCLAIMER: This guide is for educational purposes only.    
-- DISCLAIMER: By using this guide, you assume sole risk and waive any claims of liability against the author.  

# THIS IS FOR LINUX

### Prerequisites
-- Assumption: you previously ran a node on the network testnet.   
-- two tabs open, all logged in to your node.   
-- updated to v.0.8.2.   

### Store new genesis hash in .bashrc
```
echo 'export GENESIS_BLOCK_HASH="8e4d2a343f3dcf9330ad9035b3e8d168e6728904262f2c434a4f8f934ec7b676"' >> ~/.bashrc
```
 
### Install the latest version of cardano-wallet
```
curl -L https://github.com/input-output-hk/cardano-wallet/releases/download/v2019-12-13/cardano-wallet-jormungandr-linux64-v2019-12-13.tar.gz | tar xz -C $HOME/.local/bin
```
```
# Check the exact filename of the cardano-wallet binaries
ls ~/.local/bin

# If ~/.local/bin already existed, check to see if it was in your $PATH
# You're looking for (order doesn't matter):
/home/<YOUR USERNAME>/.local/bin/<FILENAME>:<SOME PATH>:<SOME OTHER PATH>

# If it wasn't in your $PATH, add this line to the bottom of .bash_profile.
# If it WAS in your $PATH, skip this step
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# reload .bash_profile
source ~/.bash_profile

# Is cardano-wallet working?
cardano-wallet -h
```

### Make a directory called "wallet"
`mkdir wallet && cd wallet`

### Make a config for cardano-wallet
(nano config.yaml)
```
{
  "log": [
    {
      "format": "plain",
      "level": "info",
      "output": "stderr"
    }
  ],
  "p2p": {
    "topics_of_interest": {
      "blocks": "normal",
      "messages": "low"
    },
    "trusted_peers": [
      {
        "address": "/ip4/52.9.132.248/tcp/3000",
        "id": "671a9e7a5c739532668511bea823f0f5c5557c99b813456c"
      },
      {
        "address": "/ip4/52.8.15.52/tcp/3000",
        "id": "18bf81a75e5b15a49b843a66f61602e14d4261fb5595b5f5"
      },
      {
        "address": "/ip4/13.114.196.228/tcp/3000",
        "id": "7e1020c2e2107a849a8353876d047085f475c9bc646e42e9"
      },
      {
        "address": "/ip4/13.112.181.42/tcp/3000",
        "id": "52762c49a84699d43c96fdfe6de18079fb2512077d6aa5bc"
      },
      {
        "address": "/ip4/3.125.75.156/tcp/3000",
        "id": "22fb117f9f72f38b21bca5c0f069766c0d4327925d967791"
      },
      {
        "address": "/ip4/52.28.91.178/tcp/3000",
        "id": "23b3ca09c644fe8098f64c24d75d9f79c8e058642e63a28c"
      },
      {
        "address": "/ip4/3.124.116.145/tcp/3000",
        "id": "99cb10f53185fbef110472d45a36082905ee12df8a049b74"
      }
    ]
  },
}
```

### Launch wallet
```
cardano-wallet launch --genesis-block-hash $GENESIS_BLOCK_HASH -- --config config.yaml

# Go to your third open terminal tab
cd ~/wallet
cardano-wallet network information
```

### Recover Byron wallet
(Go to a second terminal tab)
```
cd ~/wallet

# Verify that your wallet is running
cardano-wallet network information

# Make a new Byron wallet by recovering with your 12 word mnemonic sentence
curl -X POST http://localhost:8090/v2/byron-wallets \
  -H "Content-Type: application/json" \
  -d '{
    "name": "<GIVE YOUR NEW BYRON WALLET A NAME>",
    "passphrase": "<GIVE YOUR NEW BYRON WALLET A NEW PASSPHRASE - DONT LOSE THIS>",
    "mnemonic_sentence": [
      "survey",
      "wonder",
      ...
  ]}'
  
# From the output, copy the "id" - this is your Byron wallet id
# Example output: { ..., "id": "aa129a07d1ce083e67597348f1788747a034686e", ... }

# Save the byron_wallet_id somewhere, and save as an environment variable, like this:
export BYRON_ID=<YOUR BYRON ID>

# Check if your Byron wallet has been recorded in the blockchain
curl http://localhost:8090/v2/byron-wallets/$BYRON_ID
```
### Create new Shelley wallet
```
# Generate a new 15 word mnemonic phrase
$ cardano-wallet mnemonic generate --size=15
perfect canvas ...
```
### Restore Shelley wallet with the phrase you just generated
```
# Make sure to write down the second factor and/or passphrase that you are about to enter
# Read the previous line again, it's important.

$ cardano-wallet wallet create MyShelleyWallet 
Please enter a 15–24 word mnemonic sentence: perfect canvas ...

(Enter a blank line if you didn't use a second factor.)
Please enter your 9–12 word mnemonic second factor: 

Please enter a passphrase: **********
Enter the passphrase a second time: **********
Ok.
{
...
"id": "2d4cc31a4b3116ab86bfe529d30d9c362acd0b44",
...
}

The "id" above is your Shelley wallet ID
# Copy/Save the SHELLEY_ID somewhere

# Save the SHELLEY_ID as an environment variable
export SHELLEY_ID="<PASTE THE SHELLEY_ID HERE>"
```

### Migrate your Byron wallet to your new Shelley wallet
```
curl -X POST http://127.0.0.1:8090/v2/byron-wallets/$BYRON_ID/migrations/$SHELLEY_ID \
  -H "Content-Type: application/json" \
  -d '{
    "passphrase": "<PASSPHRASE OF YOUR BYRON WALLET>",
    "migration_cost": 1000000
  }
  '
  
# Check if the migration was successful
cardano-wallet wallet get $SHELLEY_ID
```

### Make a brand new address on your Jormungandr node
(Back on tab #1)
```
cd ~/jormungandr

# Download script createAddress.sh from IOHK
curl -sLOJ https://raw.githubusercontent.com/input-output-hk/jormungandr-qa/master/scripts/createAddress.sh

# Make it executable
chmod +x createAddress.sh

# Create new address
./createAddress.sh account | tee owner.addr

# IMPORTANT
# You should now see the private key, publicc key, and address on your screen.
# It is very, very important that you do not lose these.

# Copy/paste the SECRET_KEY to a file
nano ~/files/owner.sk

# Copy/paste the PUBLIC_KEY to a file
nano ~/files/owner.pk

# Move the address file with the others
mv owner.addr ~/files
```

### Backup the keys to your local machine
```
# Open a new tab in terminal on your LOCAL machine
mkdir ~/jormungandr-backups
mkdir ~/jormungandr-backups/<JORMUNGANDR VERSION>

# Repeat this command for each file
scp -P <YOUR SSH PORT> -i ~/.ssh/<YOUR SSH PRIVATE KEY> <YOUR VPS USERNAME>@<VPS PUBLIC IP ADDRESS>:files/<FILENAME> ~/jormungandr-backups/<JORMUNGANDR VERSION>/
```

### Send Lovelaces to your new address
`cardano-wallet transaction create $SHELLEY_ID --payment <NUMBER OF LOVELACES>@$(cat ~/files/owner.addr)`


