# How to register a stake pool
-- DISCLAIMER: This guide is for educational purposes only.  
-- DISCLAIMER: By using this guide, you assume sole risk and waive any claims of liability against the author.  

-- Note: This guide assumes you are on a Mac or Linux  
-- Note: anything preceded by "#" is a comment.   
-- Note: anything all-caps in between "<>" is an placeholder; e.g. `"<FILENAME>"` could be `"foo.txt"`.   
-- Note: anything in between "${}" is a variable that will be evaluated by your shell.  

# Prerequisites
The following steps assume you have jormungandr node up and running (not necessarily as leader-candidate).  
If you don’t, go here:  
[Cardano Shelley Node Setup Guide 4newbs (v0.8.3) · GitHub](https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/docs/jormungandr_node_setup_guide.md)

# IMPORTANT
If you followed the previous guide, you may have already registered the node on the blockchain as leader-candidate. If
this is the case, make SURE the address you register begins with `addr` (not `ca1`).

This guide relies on the context of the original "Guide 4newbs." If any of what you're
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
chmod 400 ~/.ssh/<THE FILENAME CONTAINING THE KEY YOU JUST GENERATED>

# Copy the contents of the filename containing the public key to your clipboard
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
# If you have NOT already created your public/private keys, complete the following steps:
# If you previously created keys from "Guide for Newbs," use those instead.

jcli key generate --type ed25519 | tee receiver_secret.key | jcli key to-public > receiver_public.key

jcli address account --testing --prefix addr $(cat receiver_public.key) > receiver_account.txt 
```

### Make a .json file with the contents of receiver_public.key as the filename.
`nano "$(cat receiver_public.key)".json


### Paste the follwing into the .json file, and replace the values with your own.
```
{
  "owner": "ed25519_pk1qppzz38el9zxtgaw0ttmf6d6zytllfu3fnwcl5tlc3pp044artxqru55mx",
  "name": "My Stake Pool",
  "description": "My really awesome stakepool",
  "ticker": "ADA1",
  "homepage": "https://cardanofoundation.org",
  "pledge_address": "addr1s0nyt67uwcg7dahrxug698h5xfasnyd5qhnsd0h0peqlqvtfqf48ymz680l"
}
```


NOTE: "owner" is the contents of receiver_public.key.
NOTE: "pledge_address" is the contents of `receiver_account.txt` (OR) some other "addr" prefixed address (for which you possess the pub/private keys).
(ctrl+o to save the file, ctrl+x to exit)

### IMPORTANT
The "owner" public key must match the key-pair that you register your node on the blockchain via createStakePool.sh (see jormungandr_node_setup_guide.md)
https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/docs/jormungandr_node_setup_guide.md




### Execute the following command (as-is) to sign the .json file. This will create a .sig file
```
jcli key sign --secret-key receiver_secret.key --output "$(cat receiver_public.key)".sig "$(cat receiver_public.key)".json
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

## No errors? What now?
Check back periodically to see if the Cardano Foundation has approved your pull request.

### Errors? Want to change something?
NEVER EVER edit your submission from the github web interface. Because there's no way to re sign the edited file.
You will have a bad time if you do this.
Keep reading...

## How to edit your Cardano Foundation submisson

```
# If you want to make a change AFTER your pull request has been merged, leave a
# comment on the pull request, asking to make a change. Be sure to confirm that the
# correct procedure is to open a new pull request, (possibly on a different branch name).

# If you want to make a change BEFORE your pull request has been merged:

git checkout master
git pull origin master
git branch -D submission

mv ./registry/<YOUR PUBLIC KEY>.json .
rm ./registry <YOUR PUBLIC KEY>.sig

cat <YOUR PUBLIC KEY>.json > <TEMP FILENAME>.json
mv <YOUR PUBLIC KEY>.json > ../old_submission.json

(edit your <TEMP FILENAME>.json)
(Make sure it is correct so you don't have to redo again)

mv <TEMP FILENAME>.json ./<YOUR PUBLIC KEY>.json
```

#### Make SURE you have the .json file correct; check every single item
```
-- Use double-quotes; single-quotes are not valid json
-- https links only
-- The last item does NOT end with a comma

Paste your json into jsonlint.com
cat <YOUR PUBLIC KEY>.json (copy the output to paste into a json validator)
```

![jsonlint](https://user-images.githubusercontent.com/8118351/71026225-a9c1fa00-2100-11ea-883e-7ca87327dd5f.png)


### Everything 100% correct? Resign the file
```
jcli key sign --secret-key <FILE W/PRIVATE KEY> --output "$(cat <FILE W/PUBLIC KEY)".sig "$(cat <FILE W/PUBLIC KEY>)".json

mv <YOUR PUBLIC KEY>.json registry
mv <YOUR PUBLIC KEY>.sig registry

git status (you should see two deleted files and the two new files you created)

git add .
git commit -m '<YOUR TICKER NAME>'

git checkout -b submission
git remote -v (you should see four entrys, two for master, two for submission)

# If not, do this
git remote add submission git@github.com:<YOUR GITHUB USERNAME>/incentivized-testnet-stakepool-registry

git push submission HEAD
```

# You finished! Buy me a beer?
```
DdzFFzCqrhsjtq9YsgFKeWABaC62QdnPSrsz4GHg762R9qE86YwQTrkCYtMEUtWgb5aEsRbqHAj6Gztdw3BJMKVrCDQbf8HKc9SsnvVk
```
