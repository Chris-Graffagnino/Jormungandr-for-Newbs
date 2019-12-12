# How to claim snapshot funds
-- DISCLAIMER: This guide is for educational purposes only.  
-- DISCLAIMER: By using this guide, you assume sole risk and waive any claims of liability against the author.  

-- Note: This guide assumes you are on a Mac or Linux . 
-- Note: anything preceded by "#" is a comment.  
-- Note: anything all-caps in between "<>" is an placeholder; e.g. "<FILENAME>" could be "foo.txt".  

## IMPORTANT
The private key you are about to restore can be lost or stolen. Take proper steps to protect your keys!

```
Chris Graffagnino, [Dec 10, 2019 at 11:31:51 AM]:
# Make a directory for the cardano-wallet binaries
mkdir ~/.local/bin

# Download & extract cardano-wallet

# Linux
curl -L https://github.com/input-output-hk/cardano-wallet/releases/download/v2019-12-09/cardano-wallet-jormungandr-linux64-v2019-12-09.tar.gz | tar xz -C $HOME/.local/bin

OR

# Mac
curl -L https://github.com/input-output-hk/cardano-wallet/releases/download/v2019-12-09/cardano-wallet-jormungandr-macos64-v2019-12-09.tar.gz | tar xz -C $HOME/.local/bin

# Check the exact filename of the cardano-wallet binaries
ls ~/.local/bin

# If ~/.local/bin already existed, check to see if it was in your $PATH
# You're looking for (order doesn't matter):
/home/<YOUR USERNAME>/.local/bin/<FILENAME>:<SOME PATH>:<SOME OTHER PATH>

# If it wasn't in your $PATH, add this line to the bottom of .bash_profile.
# If it WAS in your $PATH, skip this step
export PATH="$HOME/.local/bin:$PATH"

# reload .bash_profile
source ~/.bash_profile

# Type the following to see available commands
cardano-wallet -h

# You can also see available sub-commands for a given command such as mnemonic
cardano-wallet mnemonic -h

# Restore the private key from 15 word mnemonic phrase
cardano-wallet mnemonic reward-credentials
```

## Buy me a beer, if you like
```
DdzFFzCqrhsjtq9YsgFKeWABaC62QdnPSrsz4GHg762R9qE86YwQTrkCYtMEUtWgb5aEsRbqHAj6Gztdw3BJMKVrCDQbf8HKc9SsnvVk
```

