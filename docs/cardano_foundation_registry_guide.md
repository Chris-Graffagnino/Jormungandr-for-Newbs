# How to register a stake pool
-- DISCLAIMER: This guide is for educational purposes only.  
-- DISCLAIMER: By using this guide, you assume sole risk and waive any claims of liability against the author.  

-- Note: This guide assumes you are on a Mac or Linux  
-- Note: anything preceded by "#" is a comment.   
-- Note: anything all-caps in between "<>" is an placeholder; e.g. `"<FILENAME>"` could be `"foo.txt"`.   
-- Note: anything in between "${}" is a variable that will be evaluated by your shell.  

-- IMPORTANT: There are two ways to do this, the simple way, and the way where you use the cardano-wallet api.
 
This guide ONLY covers the simple way. Once the *special incentivized-testnet Daedalu*s is released, restore using your seed phrase, then send funds to the address you create below, *owner.addr*.  The downside of this method is you won’t be able to see your rewards grow from the gorgeous Daedalus user interface. You will, however, be able to see your rewards grow from a slightly less gorgeous UNIX interface. We gonna party like it’s 1971…

# Prerequisites
The following steps assume you have jormungandr node up and running (not necessarily as leader-candidate).  
If you don’t, go here:  
[Cardano Shelley Node Setup Guide 4newbs (v0.8.0-rc9+1) · GitHub](https://gist.github.com/Chris-Graffagnino/4d1be0b88dcaa93440a81dcafdc47afd)

# IMPORTANT
If you followed the previous guide, you may have already registered the node on the blockchain as leader-candidate.  
Understand that the REAL incentivized-testnet will launch with a new genesis-block-hash. That means that
you'll start with a zero balance, although you'll be able to claim your tADA from the 11/29/19 main-net snapshot.   

Once you claim your snapshot ADA, you can send it from incentivized-testnet Daedalus to *owner.addr*. Then you will
run createStakePool.sh to register your (new) stakepool. Don't forget to run delegate-account.sh as well!  

HOWEVER, until you get the snapshot ADA, you'll have to wait to register using the scripts I just mentioned.  

Until then, Let's register your pool with the Cardano Foundation.  

One last thing... this guide relies on the context of the original "Guide 4newbs." If any of what you're
about to read is confusing, consider the official tutorial:  
https://github.com/cardano-foundation/incentivized-testnet-stakepool-registry/wiki/How-to-Register-Your-Stake-Pool


# The Basics
(If you have a github account and you've uploaded your ssh keys, skip to "START HERE")  

### If you don't have one, create free account on Github
[The world’s leading software development platform · GitHub](https://github.com/)

```
# Do you have ssh keys on your local machine?
cd ~/.ssh
ls

# By convention, a private/public key-pair have the same filename, but the public key has a ".pub" extention
# The default key-pair on a mac should be id_rsa (private key) and id_rsa.pub (public key)

# If you're curious what the difference is, have a look...
cat id_rsa
cat id_rsa.pub

# If you DON'T have a key-pair in ~/.ssh/, generate them.
# When prompted, give it a name and password.
ssh-keygen

# Lock down private key
chmod 400 ~/.ssh/<YOUR KEY>

# Copy the public key to your clipboard
```

## Check that you have ssh keys on github
![go_to_settings](https://user-images.githubusercontent.com/8118351/70385781-575a3e00-1988-11ea-96e3-a792d8ffde68.png)

### Go to "ssh and gpg keys"
![go_to_ssh_and_gpg_keys](https://user-images.githubusercontent.com/8118351/70385783-5cb78880-1988-11ea-9bda-11b71c62ec1a.png)

### If you do NOT have an ssh key-pair on github, add them.

![click_new_ssh_key](https://user-images.githubusercontent.com/8118351/70385823-c46dd380-1988-11ea-9ae8-40f83091511e.png)

### Title should be something you associate with your computer
(paste the entire contents of your public key file (<FILENAME>.pub) in the larger text-box)
![add_ssh_key](https://user-images.githubusercontent.com/8118351/70385826-cafc4b00-1988-11ea-8938-f725aa12ad89.png)



# START HERE

### Fork the repo
[GitHub - cardano-foundation/incentivized-testnet-stakepool-registry](https://github.com/cardano-foundation/incentivized-testnet-stakepool-registry)

![fork_the_repo](https://user-images.githubusercontent.com/8118351/70385733-e1ee6d80-1987-11ea-8adb-7cbe336b62a7.png)


### Get the ssh link to clone the repo (click the green button to open the drop-down)
![clone_the_repo](https://user-images.githubusercontent.com/8118351/70385745-f9c5f180-1987-11ea-9fb8-b9ee50d03bd9.png)


### Open new tab in the terminal app.
```
# Clone the repo on your local machine, using ssh
git clone <THE LINK YOU COPIED>
cd ~/incentivized-testnet-stakepool-registry
git checkout -b submission
```

### Open another tab in the terminal app, log in to your VPS
```
ssh -i ~/.ssh/<YOUR SSH PRIVATE KEY> <USERNAME>@<VPS PUBLIC IP ADDRESS> -p <SSH PORT>
cd jormungandr
```

## Get your rewards credentials
```
# If you previously used my "guide 4newbs", you're probably used to seeing
# receiver_secret.key, receiver_public.key, receiver_account.txt
# The keys created in the following step will REPLACE those, once the real incentivized-testnet launches.

jcli key generate --type ed25519 | tee owner.prv | jcli key to-public > owner.pub

jcli address account --testing --prefix addr $(cat owner.pub) > owner.addr
```

### Make a .json file with the contents of owner.pub as the filename.  
`nano "$(cat owner.pub)".json`


### Paste the follwing into the .json file, and replace the values with your own.
```
{
  "owner": "ed25519_pk1qppzz38el9zxtgaw0ttmf6d6zytllfu3fnwcl5tlc3pp044artxqru55mx",
  "name": "My Stake Pool",
  "description": "My really awesome stakepool"
  "ticker": "ADA1",
  "homepage": "https://cardanofoundation.org",
  "pledge_address": "addr1s0nyt67uwcg7dahrxug698h5xfasnyd5qhnsd0h0peqlqvtfqf48ymz680l"
}
```


NOTE: "owner" is the contents of `owner.pub`.  
NOTE: "pledge_address" is the contents of `owner.addr` (OR) some other "addr" prefixed address (for which you possess the pub/private keys).
(ctrl+o to save the file, ctrl+x to exit) . 


### Execute the following command (as-is) to sign the .json file. This will create a .sig file
```
jcli key sign --secret-key owner.prv --output "$(cat owner.pub)".sig "$(cat owner.pub)".json
```

### Copy the .json & .sig file to your current location
 On your LOCAL machine, execute the following command for EACH of the two .json & .sig files, which will copy them to your current location.  

```
scp -P <YOUR SSH PORT> -i ~/.ssh/<YOUR SSH PRIVATE KEY> <YOUR VPS USERNAME>@<VPS PUBLIC IP ADDRESS>:jormungandr/<FILENAME> .
```

### Check that you're happy with the .json file before you move it to the massively populated registry directory
cat <FILENAME>.json

### If you need to make changes, delete the two files, go back to where your public/private keys are and start over.
(Let's assume you're happy now with the files)

### Move both files to the registry directory
mv <FILENAME> ~/incentivized-testnet-stakepool-registry/registry

### Check that you can push to the "submission" branch
```
git remote -v 

# You should see something like this:

origin git@github.com:Chris-Graffagnino/incentivized-testnet-stakepool-registry.git (fetch)
origin git@github.com:Chris-Graffagnino/incentivized-testnet-stakepool-registry.git (push)
submission git@github.com:Chris-Graffagnino/incentivized-testnet-stakepool-registry (fetch)
submission git@github.com:Chris-Graffagnino/incentivized-testnet-stakepool-registry (push)
```

#### Don't see the "submission" lines? Try this:
`git remote add submission git@github.com:<YOUR GITHUB USERNAME>/incentivized-testnet-stakepool-registry`

### GIT add/commit/push
```
cd ..
git add .
git commit -m '<YOUR TICKER NAME>'
git push submission HEAD
```


### In a browser, navigate to
`https://github.com/<YOUR GITHUB USERNAME>/incentivized-testnet-stakepool-registry`


Click the green button.  
![click_the_green_button copy](https://user-images.githubusercontent.com/8118351/70454377-40a80a00-1aa2-11ea-966d-126f76b887c7.png)

Don't see the green button? Try this instead.
![pull_request_no_green_button](https://user-images.githubusercontent.com/8118351/70454509-6df4b800-1aa2-11ea-9433-6b9c67d377d3.png)

Some automated checks will run. Do you see Errors? Click "Details" for more information.   
![automated_tests_failed](https://user-images.githubusercontent.com/8118351/70454744-dba0e400-1aa2-11ea-8741-20491897d6dc.png) 

Look at the very bottom of the output for info about the error.
![errors](https://user-images.githubusercontent.com/8118351/70454753-e196c500-1aa2-11ea-92ab-76a3621f3a66.png)



#### Fix the errors
```
# In terminal app, go to the tab for your VPS

# Fix the errors in the .json file

# Delete the existing .sig file
rm "$(cat owner.pub)".sig

# Generate the .sig file once again
jcli key sign --secret-key owner.prv --output "$(cat owner.pub)".sig "$(cat owner.pub)".json

# Copy the files back down via scp
# GIT add/commit/push

# You won't have to open another pull request
# Check the github page to see if the automated checks have passed
```

# What now?
Check back periodically to see if the Cardano Foundation has approved your pull request.

## How do I delegate my incentivized-testnet ADA?
Once you've downloaded special incentivized-testnet wallet, restore using your 12 or 15
word neumonic phrase. Then do the following:  
```
# Copy the contents of owner.addr
cat owner.addr

# From incentivized-testnet-daedalus, send a small amount of ADA to <ADDRESS YOU JUST COPIED>
# Did you receive the ADA? Send more...

# Now that owner.addr has a balance, create a stakepool & register it on the new blockchain.
# You'll need three scripts from the original guide-4newbs if you don't already have them:  
createStakePool.sh
send-certificate.sh
delegate-account.sh

# If you didn't already have those, execute the following command for each of them:  
chmod +x <FILENAME>

# Create/register your stakepool on the new blockchain
# Check to make sure you remember the correct order of args
cat createStakePool.sh | grep usage

# You should see something like this
$0 <REST-LISTEN-PORT> <TAX_VALUE> <TAX_RATIO> <TAX_LIMIT> <ACCOUNT_SK>

# Here's an example of how you might execute createStakePool.sh
./createStakePool.sh 3101 50000000 1/10 10000000000 $(cat owner.prv)

# If you hadn't noticed, createStakePool.sh calls send-certificate.sh

# Execute the following command to delegate your owner stake
./delegate-account.sh $(cat stake_pool.id) <REST-LISTEN-PORT> $(cat receiver_secret.key)

# While you're waiting for the transaction to go through, open node-config.yaml to check that "blocks" & "messages"
# are both set to "high". If not, fix that and start the node as leader:
nohup jormungandr --config node-config.yaml --secret node_secret.yaml --genesis-block-hash <GENESIS BLOCK HASH> >> <PATH TO LOG FILE> 2>&1 &

### Or if you setup the node using the original Guide-4newbs
start_leader
```

# You finished! Buy me a beer?
```
DdzFFzCqrhsjtq9YsgFKeWABaC62QdnPSrsz4GHg762R9qE86YwQTrkCYtMEUtWgb5aEsRbqHAj6Gztdw3BJMKVrCDQbf8HKc9SsnvVk
```
