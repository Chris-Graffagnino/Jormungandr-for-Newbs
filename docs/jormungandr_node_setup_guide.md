# Setup Cardano Shelley staking node (Ubuntu 18.04)

-- DISCLAIMER: This guide is for educational purposes only. Do not use in production with real funds.  
-- DISCLAIMER: By using this guide, you assume sole risk and waive any claims of liability against the author.  

-- Note: This guide is for running jormungandr on a virtual private server (VPS), running Ubuntu 18.04.  
-- Note: This guide assumes your local machine is a Mac, but most instructions are executed on the remote machine.  
-- Note: anything preceded by "#" is a comment.   
-- Note: anything all-caps in between "<>" is an placeholder; e.g. `"<FILENAME>"` could be `"foo.txt"`.   
-- Note: anything in between "${}" is a variable that will be evaluated by your shell.  

	
## Create free account on Github
[The world’s leading software development platform · GitHub](https://github.com/)

## Generate private/public ssh keys
(If you don’t have a ssh key on your machine)
```
# Generate private & public keys on your *LOCAL MACHINE* (public key will have a ".pub" extension)
# When prompted, name it something other than "id_rsa" (in case you're using that somewhere else)
ssh-keygen

# Lock down private key
chmod 400 ~/.ssh/<YOUR KEY>

# Do you have brew installed?
brew -v

# Install brew if you don't have it:
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Now install ssh-copy-id
brew install ssh-copy-id

# Push key up to your box
# See below if using Digital Ocean for vps
ssh-copy-id -i ~/.ssh/<YOUR KEYNAME>.pub root@<YOUR VPS PUBLIC IP ADDRESS>
```

### If using Digital Ocean for vps, follow these instructions instead
[How to Upload SSH Public Keys to a DigitalOcean Account :: DigitalOcean Product Documentation](https://www.digitalocean.com/docs/droplets/how-to/add-ssh-keys/to-account/) 

	
## Login to VPS via ssh
`ssh -i ~/.ssh/<PATH TO SSH PRIVATE KEY ON YOUR LOCAL MACHINE> root@<YOUR VPS PUBLIC IP ADDRESS>`

## Create non-root user
```
# Create user and password
useradd <USERNAME> && passwd <USERNAME>

# Add non-root user to sudo group
usermod -aG sudo <USERNAME>

# Give permissions to new user (please type sudo here... even as root user)
sudo visudo

# You should now be in the editor called "nano"
# ctrl+o to save, ctrl+x to quit
# add entry for new user under "User privilege specification"
<USERNAME> ALL=(ALL:ALL) ALL

# Now that you've saved & quit the file above...
# Add dir and permissions
mkdir /home/<USERNAME>
chown <USERNAME>:<USERNAME> /home/<USERNAME> -R

# Copy pub key to new user
rsync --archive --chown=<USERNAME>:<USERNAME> ~/.ssh /home/<USERNAME>

# Set new user shell to bash
chsh -s /bin/bash <USERNAME>
```

(Do not log out as root user just yet...)


## Update Linux and make files/directories
```
apt update
apt upgrade
apt install -y build-essential libssl-dev
apt install pkg-config
apt install nload
apt install python3-pip

# These instructions will prevent certain errors when installing Rust
mkdir /home/<USERNAME>/.cargo && mkdir /home/<USERNAME>/.cargo/bin
chown -R <USERNAME> /home/<USERNAME>/.cargo
touch /home/<USERNAME>/.profile
chown <USERNAME> /home/<USERNAME>/.profile
touch /home/<USERNAME>/.bashrc && touch /home/<USERNAME>/.bash_profile
chown <USERNAME> /home/<USERNAME>/.bashrc
chown <USERNAME> /home/<USERNAME>/.bash_profile
```

## Increase open file limit
```
nano /etc/security/limits.conf

# Add the following at the bottom of the file
<USERNAME> soft nofile 8192

# Save & close the file
ctrl+o
ctrl+x
```

## Disable firewall
```
# We're going to change the default ssh port to be a bit more secure
# To avoid any lockouts, disable the firewall
ufw disable
```

## Change default ssh port
```
# Changing this setting REQUIRES also opening the same port with ufw (next section of this guide)
# Don't skip the ufw section, or else you will be locked out.

# Note: there is also a file called "ssh_config"... don't edit that one
nano /etc/ssh/sshd_config

# Change the line "#Port 22", to "Port <CHOOSE A PORT BETWEEN 1024 AND 65535>"
# Remember to remove the "#"

# While we're here, let's give ourselves just a bit more time before getting disconnected, ie "broken pipe".
# Change the line "#TCPKeepAlive yes" to "TCPKeepAlive no"
# Change the line "#ClientAliveInterval 0" to "ClientAliveInterval 300"

# Type ctrl+o to save, ctrl+x to exit
```

## Configure "uncomplicated firewall" (ufw)
```
# Set defaults for incoming/outgoing ports
ufw default deny incoming
ufw default allow outgoing

# Open ssh port (rate limiting enabled - max 10 attempts within 30 seconds)
ufw limit from any to any port <THE PORT YOU JUST CHOSE IN sshd_config> proto tcp

# Re-enable firewall
ufw enable

# Double-check the port you chose for ssh was the same as what you set in /etc/ssh/sshd_config
grep Port /etc/ssh/sshd_config			
ufw status verbose

# Double-check your new user is in the sudo group
grep '^sudo:.*$' /etc/group | cut -d: -f4

# Reboot (You will be kicked off... wait a couple minutes before logging in)
reboot
```

## Sign-in as non-root user
```
# Sign-in as non-root user
ssh -i ~/.ssh/<YOUR SSH PRIVATE KEY> <USERNAME>@<YOUR VPS PUBLIC IP ADDRESS> -p <SSH PORT>
```

## Disable root login (and miscellaneous improvements)
```
# FYI You already edited this file just a couple minutes ago
sudo nano /etc/ssh/sshd_config

# Disabling root login is considered a security best-practice
(Change "PermitRootLogin" from "yes" to "no")

# Disabling log-in via password helps mitigate brute-force attacks
(Change "PasswordAuthentication" to "no")

# Give me MOAR LAWGS!
(Change "LogLevel" from "INFO" to "VERBOSE"

(ctrl+o to save, ctrl+x to exit)

# Restart the ssh daemon
# NOTE: You will only be able to log-in using your SSH private key as non-root user
sudo service sshd restart
```


## Configure .bash_profile
`sudo nano ~/.bash_profile`
(Paste the following into .bash_profile)
```
export ARCHFLAGS="-arch x86_64"
test -f ~/.bashrc && source ~/.bashrc

function start() {
    GREEN=$(printf "\033[0;32m")
    nohup jormungandr --config ~/files/node-config.yaml --genesis-block-hash $GENESIS_BLOCK_HASH >> ~/logs/node.out 2>&1 &
    echo ${GREEN}$(ps | grep jormungandr)
}

function stop() {
    echo "$(jcli rest v0 shutdown get -h http://127.0.0.1:${REST_PORT}/api)"
}

function stats() {
    echo "$(jcli rest v0 node stats get -h http://127.0.0.1:${REST_PORT}/api)"
}

function bal() {
    echo "$(jcli rest v0 account get $(cat ~/files/receiver_account.txt) -h  http://127.0.0.1:${REST_PORT}/api)"
}

function faucet() {
    echo "$(curl -X POST https://faucet.faucet.jormungandr-testnet.iohkdev.io/send-money/$(cat ~/files/receiver_account.txt))"
}

function get_ip() {
    echo "${PUBLIC_IP_ADDR}"
}

function get_pid() {
    ps auxf | grep jor
}

function memory() {
    top -o %MEM
}

function nodes() {
    nodes="$(netstat -tupan | grep jor | grep EST | cut -c 1-80)"
    total="$(netstat -tupan | grep jor | grep EST | cut -c 1-80 | wc -l)"
    printf "%s\n" "${nodes}" "----------" "Total:" "${total}"
}

function num_open_files() {
    echo "Calculating number of open files..."
    echo "$(lsof -u $(whoami) | wc -l)"
}

function is_pool_visible() {
    echo ${GREEN}$(jcli rest v0 stake-pools get --host "http://127.0.0.1:${REST_PORT}/api" | grep $(cat ~/files/stake_pool.id))
}

function delegate() {
    echo "$(~/files/delegate-account.sh $(cat ~/files/stake_pool.id) ${REST_PORT} $(cat ~/files/receiver_secret.key))"
}

function start_leader() {
    GREEN=$(printf "\033[0;32m")
    nohup jormungandr --config ~/files/node-config.yaml --secret ~/files/node_secret.yaml --genesis-block-hash ${GENESIS_BLOCK_HASH} >> ~/logs/node.out 2>&1 &
    echo "${GREEN}$(ps | grep jormungandr)"
}

function logs() {
    tail ~/logs/node.out
}

function empty_logs() {
    > ~/logs/node.out
}

function leader_logs() {
    echo "Has this node been scheduled to be leader?"
    echo "$(jcli rest v0 leaders logs get -h http://127.0.0.1:${REST_PORT}/api)"
}

function pool_stats() {
    echo "(jcli rest v0 stake-pool get $(cat ~/files/stake_pool.id) -h http://127.0.0.1:${REST_PORT}/api)"
}

function problems() {
    grep -E -i 'cannot|stuck|exit|unavailable' ~/logs/node.out
}
```

## Configure .bashrc
`sudo nano ~/.bashrc` 
(Paste the following into .bashrc)

```
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# colored vars
GREEN=$(printf "\033[0;32m")


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

function parse_git_branch() {
    BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    if [ ! "${BRANCH}" == "" ]
    then
        echo "(${BRANCH})"
    else
        echo ""
    fi
}

# Comment the following line if you prefer a prompt *not* include git branch info
export PS1="\[\e[36m\]\w\[\e[m\]\[\e[35m\] \`parse_git_branch\`\[\e[m\] \[\e[36m\]:\[\e[m\] "

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/bin/python3"
```

### A word about environment variables
```
# All-caps words are variables available to the current shell, ie "environment".
# You can declare an environment variable like this, (go ahead and try it): 
HELLO="Hello"

# an environment variable is referenced by invoking itwith a "$" prepended to it.
# Print your newly created environment variable:
echo $HELLO

# Environment variables are good for the current session. Next time you log-in, $HELLO will be no more...

# Want to see all the environment variables?:
printenv

# Next, we'll add some commands to .bashrc so important values are loaded as
# environment variables every time we log in.
```

## Type each of the following commands in terminal
##### (replace placeholder text)
```
echo "export USERNAME='<YOUR USERNAME>'" >> ~/.bashrc
echo "export PUBLIC_IP_ADDR='<YOUR PUBLIC IP ADDRESS>'" >> ~/.bashrc
echo "export REST_PORT='<YOUR REST PORT>'" >> ~/.bashrc
echo "export JORMUNGANDR_STORAGE_DIR='/home/<YOUR USERNAME>/storage'" >> ~/.bashrc
echo "export RUST_BACKTRACE=1" >> ~/.bashrc
echo "export GENESIS_BLOCK_HASH='<BETA OR NIGHTLY GENESIS BLOCK HASH>'" >> ~/.bashrc

# What did we just do?
# "echo" essentially means "print to screen"
# "export" declares a variable in a special way, so that any shells that spawn from it inherit the variable.
# ">>" means "take the output of the previous command and append it to the end of a file (.bashrc, in this case)
```

```
# You'll need one of these hashes in the previous command

# Genesis block hash for beta
# (Use nightly until Incentivized-Test-Net, ITN, is released)

# Genesis block hash for v0.8.0 nightly (Updated 12/11/19)
# 65a9b15f82619fffd5a7571fdbf973a18480e9acf1d2fddeb606ebb53ecca839
```

### Source config files to make our new variables available in the current shell
```
# FYI There's a command in .bash_profile that sources .bashrc.
source ~/.bash_profile
```

## Configure Swap to handle memory spikes
```
# Swap utilizes diskspace to temporarily handle spikes in memory usage
# Skip this section if you have limited diskspace, (you're running a raspberry-pi, for instance).

# Show current swap configuration
sudo swapon --show

# Check what swap is currently active, if any
free -h

# Check current disk usage
df -h

# Create swap file (Don't forget the "G")
sudo fallocate -l <SIZE EQUAL TO RAM>G /swapfile

# Verify swap settings
ls -lh /swapfile

# Only root can access swapfile
sudo chmod 600 /swapfile

# Mark the file as swap space
sudo mkswap /swapfile

# Enable swap settings every time we log in
# Make a backup of /etc/fstab
sudo cp /etc/fstab /etc/fstab.bak

# Type this command from the command-line to add swap settings to the end of fstab
echo '/swapfile none swap sw 00' | sudo tee -a /etc/fstab

# Enable swap
sudo swapon -a

# Verify swap is enabled
free -h

# Optimize swap performance
sudo nano /etc/sysctl.conf

(Add the following to the bottom of /etc/sysctl.conf)
vm.swappiness = 5
vm.vfs_cache_pressure = 50

# reload /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
```

### Create a file to preserve our system settings on reboot
sudo nano /etc/rc.local
(paste the follwing into /etc/rc.local
```
#!/bin/bash

# Give CPU startup routines time to settle.
sleep 120

sysctl -p /etc/sysctl.conf

exit 0
```

## Install Rust
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

## Get the source code
```
# First, tell git who you are.
git config --global user.name <YOUR GITHUB USERNAME>
git config --global user.email <YOUR EMAIL ADDRESS>

# Download jormungandr
git clone https://github.com/input-output-hk/jormungandr
cd jormungandr
git checkout v0.8.0
git checkout -b <NEW BRANCH NAME eg 8.0>
git submodule update --init --recursive
```

## Install the executables
```
cargo install --path jormungandr --force
cargo install --path jcli --force
chmod +x ./scripts/bootstrap
```

### Create directory & file for logging
```
mkdir ~/logs
touch ~/logs/node.out
```

### Create node-config.yaml
```
nano ~/files/node-config.yaml


# Check Telegram (StakePool Best Practice Workgroup) for up-to-date genesis-hash & trusted peers
# https://t.me/CardanoStakePoolWorkgroup/74812

# This is for the ** NIGHTLY ** release v0.8.0 (last updated 12/11/19)
# Paste the following into node-config.yaml, replacing <YOUR REST PORT> with the appropriate value
```
```
---
log:
- output: stderr
  format: plain
  level: info
p2p:
  topics_of_interest:
    blocks: normal
    messages: low
  max_connections: 256
  trusted_peers:
  - address: "/ip4/13.230.137.72/tcp/3000"
    id: fe3332044877b2034c8632a08f08ee47f3fbea6c64165b3b
  - address: "/ip4/13.230.48.191/tcp/3000"
    id: c38aabb936944776ef15bbe4b5b02454c46a8a80d871f873
  - address: "/ip4/18.196.168.220/tcp/3000"
    id: 7e2222179e4f3622b31037ede70949d232536fdc244ca3d9
  - address: "/ip4/3.124.132.123/tcp/3000"
    id: 9085fa5caeb39eace748a7613438bd2a62c8c8ee00040b71
  - address: "/ip4/18.184.181.30/tcp/3000"
    id: f131b71d65c49116f3c23c8f1dd7ceaa98f5962979133404
  - address: "/ip4/184.169.162.15/tcp/3000"
    id: fdb88d08c7c759b5d30e854492cb96f8203c2d875f6f3e00
  - address: "/ip4/52.52.67.33/tcp/3000"
    id: 3d1f8891bf53eb2946a18fb46cf99309649f0163b4f71b34
rest:
  listen: 127.0.0.1:<YOUR REST PORT>
storage: "/home/<YOUR USERNAME>/storage"
mempool:
    fragment_ttl: 2h
    log_ttl: 12h
    garbage_collection_interval: 2h
```

(Did you remember to replace the PLACEHOLDERS with the appropriate values)?

### create a directory for storage
```
mkdir /home/<YOUR USERNAME>/storage
```

### create a directory for your keys/scripts
```
mkdir /home/<YOUR USERNAME>/files
```

### generate the secret key
`jcli key generate --type=Ed25519Extended > ~/files/receiver_secret.key`

### derive the public key from the secret key
`cat receiver_secret.key | jcli key to-public > ~/files/receiver_public.key`

### derive the public address from the public key
```
jcli address account --testing --prefix addr $(cat ~/files/receiver_public.key) | tee files/receiver_account.txt
```

## Backup the keys
### Caution: Protect `receiver_secret.key` 
` Anyone who posesses receiver_secret.key can take the funds belonging to this key/address!`

### Backup keys to your local machine
```
# Open a new tab in terminal on your local machine
mkdir ~/jormungandr-backups
mkdir ~/jormungandr-backups/<JORMUNGANDR VERSION>

# Repeat this command for each file
scp -P <YOUR SSH PORT> -i ~/.ssh/<YOUR SSH PRIVATE KEY> <YOUR VPS USERNAME>@<VPS PUBLIC IP ADDRESS>:files/<FILENAME> ~/jormungandr-backups/<JORMUNGANDR VERSION>/
```

### Start the node in the background
```
# Start the node
nohup jormungandr --config node-config.yaml --genesis-block-hash ${GENESIS_BLOCK_HASH} >> ~/logs/node.out 2>&1 &

# Or use this shell function
start
```

### Inspect the output 

```
# Always check the logs when starting a node to make sure it started without error
logs
```

### Access faucet to receive funds
```
# This faucet will be turned off once incentivized-testnet officially launches (est 12/12/19)
faucet
```

## Monitor the node
(These are a list of various commands… execute when necessary)
```
# Find the PID of jormungandr (will be the first number on the left)
get_pid

# Stop jormungandr
stop

# Check stats
stats

# Check balance
bal

# Check memory usage (alias "memory")
top -o %MEM ("q" to quit)

# Check set limits on virtual memory (system-wide)
ulimit -Sa

# Check bandwidth usage
(type q to quit)
nload -m

# What nodes are connected to your node?
nodes

# Check resource limits for your node by PID
cat /proc/<PID>/limits

# Check number of files (or connections) opened by a process
# Note: every connection to another node is considered an "open file"
# Or type "num_open_files" to check num files open for your user

lsof -a -p <PID> | wc -l

# Move file from local machine to your instance
scp -P <YOUR SSH PORT> -i ~/.ssh/<YOUR PRIVATE KEY> <FILENAME> <USERNAME>@<VPS PUBLIC IP ADDRESS>:<DESTINATION>

# How much diskspace are you using?
df -H

# How much diskspace is jormungandr using? (alias "jordsk"
du -sh ${JORMUNGANDR_STORAGE_DIR}

# What are the biggest files on disk
du -a ${JORMUNGANDR_STORAGE_DIR} | sort -n -r | head -n 10
```

## Update 
```
# If you ever need to update your node, do the following

# Stop jormungandr
stop

# Empty the logs
empty_logs

# *IF* you need to delete the entire blockchain and start over...
# This MIGHT be necessary after upgrading to a new release-candidate (during beta testing)
# Consider making a backup copy of these files before deleting them, in case you change your mind.
rm -rf ${JORMUNGANDR_STORAGE_DIR}

rustup update
git pull

# Use the tagged release
git checkout <A VERSION NUMBER SUCH AS v0.8.0-rc9+1>

# Can't find the tag you want?, delete what you have locally and re-download
git tag -l | xargs git tag -d && git fetch -t

# Create a new branch for yourself
git checkout -b <NAME OF BRANCH, e.g. 8rc9+1>

# Compile the binaries
git submodule update --init --recursive
cargo install --path jormungandr --force
cargo install --path jcli --force

# Verify you're up to date
jormungandr --full-version
jcli --full-version
```

## Create script to send lovelaces
```
nano ~/files/send-lovelaces.sh

# Paste the following into send-lovelaces.sh
# This script is intended to be used, as-is... ie no placeholders need to be replaced.
```
```
#!/bin/sh

# Disclaimer:
#
#  The following use of shell script is for demonstration and understanding
#  only, it should *NOT* be used at scale or for any sort of serious
#  deployment, and is solely used for learning how the node and blockchain
#  works, and how to interact with everything.
#
#  It also asumes that `jcli` is in the same folder with the script.
#  The script works only for Account addresses type.
#
#  Tutorials can be found here: https://iohk.zendesk.com/hc/en-us/categories/360002383814-Shelley-Networked-Testnet

### CONFIGURATION
CLI="jcli"
COLORS=1
ADDRTYPE="--testing"
TIMEOUT_NO_OF_BLOCKS=200

getTip() {
  echo $($CLI rest v0 tip get -h "${REST_URL}")
}

waitNewBlockCreated() {
  COUNTER=${TIMEOUT_NO_OF_BLOCKS}
  echo "  ##Waiting for new block to be created (timeout = $COUNTER blocks = $((${COUNTER} * ${SLOT_DURATION}))s)"
  initialTip=$(getTip)
  actualTip=$(getTip)

  while [ "${actualTip}" = "${initialTip}" ]; do
    sleep ${SLOT_DURATION}
    actualTip=$(getTip)
    COUNTER=$((COUNTER - 1))
    if [ ${COUNTER} -lt 2 ]; then
      echo "  ##ERROR: Waited $(($COUNTER * $SLOT_DURATION))s secs ($COUNTER*$SLOT_DURATION) and no new block created"
      exit 1
    fi
  done
  echo "New block was created - $(getTip)"
}

### COLORS
if [ ${COLORS} -eq 1 ]; then
  GREEN=$(printf "\033[0;32m")
  RED=$(printf "\033[0;31m")
  BLUE=$(printf "\033[0;33m")
  WHITE=$(printf "\033[0m")
else
  GREEN=""
  RED=""
  BLUE=""
  WHITE=""
fi

if [ $# -ne 4 ]; then
  echo "usage: $0 <ADDRESS> <AMOUNT> <REST-LISTEN-PORT> <SOURCE-SK>"
  echo "    <ADDRESS>     Address where to send the funds"
  echo "    <AMOUNT>      Amount to be sent (in lovelace) - tx fees will be paid by the source address"
  echo "    <REST-LISTEN-PORT>   The REST Listen Port set in node-config.yaml file (EX: 3101)"
  echo "    <SOURCE-SK>   The Secret key of the Source address"
  exit 1
fi

DESTINATION_ADDRESS="$1"
DESTINATION_AMOUNT="$2"
REST_PORT="$3"
SOURCE_SK="$4"

REST_URL="http://127.0.0.1:${REST_PORT}/api"
BLOCK0_HASH=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'block0Hash:' | sed -e 's/^[[:space:]]*//' | sed -e 's/block0Hash: //')
FEE_CONSTANT=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'constant:' | sed -e 's/^[[:space:]]*//' | sed -e 's/constant: //')
FEE_COEFFICIENT=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'coefficient:' | sed -e 's/^[[:space:]]*//' | sed -e 's/coefficient: //')
MAX_TXS_PER_BLOCK=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'maxTxsPerBlock:' | sed -e 's/^[[:space:]]*//' | sed -e 's/maxTxsPerBlock: //')
SLOT_DURATION=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'slotDuration:' | sed -e 's/^[[:space:]]*//' | sed -e 's/slotDuration: //')
SLOTS_PER_EPOCH=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'slotsPerEpoch:' | sed -e 's/^[[:space:]]*//' | sed -e 's/slotsPerEpoch: //')

echo "================Send Money================="
echo "DESTINATION_ADDRESS: ${DESTINATION_ADDRESS}"
echo "DESTINATION_AMOUNT: ${DESTINATION_AMOUNT}"
echo "REST_PORT: ${REST_PORT}"
echo "SOURCE_SK: ${SOURCE_SK}"
echo "BLOCK0_HASH: ${BLOCK0_HASH}"
echo "FEE_CONSTANT: ${FEE_CONSTANT}"
echo "FEE_COEFFICIENT: ${FEE_COEFFICIENT}"
echo "=================================================="

STAGING_FILE="staging.$$.transaction"

#CLI transaction
if [ -f "${STAGING_FILE}" ]; then
  echo "error: staging already exist. restart"
  exit 2
fi

set -e

SOURCE_PK=$(echo ${SOURCE_SK} | $CLI key to-public)
SOURCE_ADDR=$($CLI address account ${ADDRTYPE} ${SOURCE_PK})

echo "## Sending ${RED}${DESTINATION_AMOUNT}${WHITE} to ${BLUE}${DESTINATION_ADDRESS}${WHITE}"
$CLI address info "${DESTINATION_ADDRESS}"

# TODO we should do this in one call to increase the atomicity, but otherwise
SOURCE_COUNTER=$($CLI rest v0 account get "${SOURCE_ADDR}" -h "${REST_URL}" | grep '^counter:' | sed -e 's/counter: //')

# the source account is going to pay for the fee ... so calculate how much
# FEE_COEFFICIENT should be multiplied witht the no of (INPUTS + OUTPUTS) - we use only 1 Source and 1 Destination
ACCOUNT_AMOUNT=$((${DESTINATION_AMOUNT} + ${FEE_CONSTANT} + $((2 * ${FEE_COEFFICIENT}))))

# Create the transaction
# FROM: ACCOUNT for AMOUNT+FEES
# TO: DESTINATION ADDRESS for AMOUNT
echo " ##1. Create the offline transaction file"
$CLI transaction new --staging ${STAGING_FILE}

echo " ##2. Add input details"
$CLI transaction add-account "${SOURCE_ADDR}" "${ACCOUNT_AMOUNT}" --staging "${STAGING_FILE}"

echo " ##3. Add output details"
$CLI transaction add-output "${DESTINATION_ADDRESS}" "${DESTINATION_AMOUNT}" --staging "${STAGING_FILE}"

echo " ##4. Finalize the transactions"
$CLI transaction finalize --staging ${STAGING_FILE}

TRANSACTION_ID=$($CLI transaction data-for-witness --staging ${STAGING_FILE})

echo " ##5. Create the witness"
# Create the witness for the 1 input (add-account) and add it
WITNESS_SECRET_FILE="witness.secret.$$"
WITNESS_OUTPUT_FILE="witness.out.$$"

printf "${SOURCE_SK}" >${WITNESS_SECRET_FILE}

$CLI transaction make-witness ${TRANSACTION_ID} \
  --genesis-block-hash ${BLOCK0_HASH} \
  --type "account" --account-spending-counter "${SOURCE_COUNTER}" \
  ${WITNESS_OUTPUT_FILE} ${WITNESS_SECRET_FILE}

echo " ##6. Add the witness to the transaction"
$CLI transaction add-witness ${WITNESS_OUTPUT_FILE} --staging "${STAGING_FILE}"

echo " ##7. Show the transaction info"
$CLI transaction info --fee-constant ${FEE_CONSTANT} --fee-coefficient ${FEE_COEFFICIENT} --staging "${STAGING_FILE}"

echo " ##7. Finalize the transaction and send it"
$CLI transaction seal --staging "${STAGING_FILE}"
$CLI transaction to-message --staging "${STAGING_FILE}" | $CLI rest v0 message post -h "${REST_URL}"

echo " ##8. Remove the temporary files"
rm ${STAGING_FILE} ${WITNESS_SECRET_FILE} ${WITNESS_OUTPUT_FILE}

waitNewBlockCreated

echo " ##9. Check the account's balance"
$CLI rest v0 account get ${DESTINATION_ADDRESS} -h ${REST_URL}

exit 0
```

### Make send-lovelaces.sh executable
```
# Make script executable
chmod +x ~/files/send-lovelaces.sh

# Usage
~/files/send-lovelaces.sh <DESTINATION ADDRESS> <AMOUNT LOVELACES TO SEND> ${REST_PORT} $(cat ~/files/receiver_secret.key)
```

## Create a stakepool
(Do this while your node is running in passive mode…edit node-config.yaml so blocks=normal, messages=low)

### Create scripts to register your node as stake pool
```
nano ~/files/createStakePool.sh

# Paste the following into createStakePool.sh
# This script is intended to be used, as-is... ie no placeholders need to be replaced.
```
```
#!/bin/sh

# Disclaimer:
#
#  The following use of shell script is for demonstration and understanding
#  only, it should *NOT* be used at scale or for any sort of serious
#  deployment, and is solely used for learning how the node and blockchain
#  works, and how to interact with everything.
#
#  It also asumes that `jcli` is in the same folder with the script.
#
# Scenario:
#   Configure 1 stake pool having as owner the provided account address (secret key)
#
#  Tutorials can be found here: https://iohk.zendesk.com/hc/en-us/categories/360002383814-Shelley-Networked-Testnet

### CONFIGURATION
CLI="jcli"
COLORS=1
ADDRTYPE="--testing"

if [ $# -ne 5 ]; then
    echo "usage: $0 <REST-LISTEN-PORT> <TAX_VALUE> <TAX_RATIO> <TAX_LIMIT> <ACCOUNT_SK>"
    echo "    <REST-LISTEN-PORT>   The REST Listen Port set in node-config.yaml file (EX: 3101)"
    echo "    <TAX_VALUE>   The fixed cut the stake pool will take from the total reward"
    echo "    <TAX_RATIO>   The percentage of the remaining value that will be taken from the total"
    echo "    <TAX_LIMIT>   A value that can be set to limit the pool's Tax."
    echo "    <SOURCE-SK>   The Secret key of the Source address"
    exit 1
fi

REST_PORT="$1"
TAX_VALUE="$2"
TAX_RATIO="$3"
TAX_LIMIT="$4"
ACCOUNT_SK="$5"

REST_URL="http://127.0.0.1:${REST_PORT}/api"
BLOCK0_HASH=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'block0Hash:' | sed -e 's/^[[:space:]]*//' | sed -e 's/block0Hash: //')
FEE_CONSTANT=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'constant:' | sed -e 's/^[[:space:]]*//' | sed -e 's/constant: //')
FEE_COEFFICIENT=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'coefficient:' | sed -e 's/^[[:space:]]*//' | sed -e 's/coefficient: //')
FEE_CERTIFICATE=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'certificate:' | sed -e 's/^[[:space:]]*//' | sed -e 's/certificate: //')

ACCOUNT_PK=$(echo ${ACCOUNT_SK} | $CLI key to-public)
ACCOUNT_ADDR=$($CLI address account ${ADDRTYPE} ${ACCOUNT_PK})

echo "================ Blockchain details ================="
echo "REST_PORT:        ${REST_PORT}"
echo "ACCOUNT_SK:       ${ACCOUNT_SK}"
echo "BLOCK0_HASH:      ${BLOCK0_HASH}"
echo "FEE_CONSTANT:     ${FEE_CONSTANT}"
echo "FEE_COEFFICIENT:  ${FEE_COEFFICIENT}"
echo "FEE_CERTIFICATE:  ${FEE_CERTIFICATE}"
echo "=================================================="

echo " ##1. Create VRF keys"
POOL_VRF_SK=$($CLI key generate --type=Curve25519_2HashDH)
POOL_VRF_PK=$(echo ${POOL_VRF_SK} | $CLI key to-public)

echo POOL_VRF_SK: ${POOL_VRF_SK}
echo POOL_VRF_PK: ${POOL_VRF_PK}

echo " ##2. Create KES keys"
POOL_KES_SK=$($CLI key generate --type=SumEd25519_12)
POOL_KES_PK=$(echo ${POOL_KES_SK} | $CLI key to-public)

echo POOL_KES_SK: ${POOL_KES_SK}
echo POOL_KES_PK: ${POOL_KES_PK}

echo " ##3. Create the Stake Pool certificate using above VRF and KEY public keys"
ACCOUNT_SK_FILE="account.privateKey"
STAKE_POOL_CERTIFICATE_FILE="stake_pool.cert"
SIGNED_STAKE_POOL_CERTIFICATE_FILE="stake_pool_certificate.signed"
echo ${ACCOUNT_SK} > ${ACCOUNT_SK_FILE}

$CLI certificate new stake-pool-registration --tax-fixed ${TAX_VALUE} --tax-ratio ${TAX_RATIO} --tax-limit ${TAX_LIMIT} --kes-key ${POOL_KES_PK} --vrf-key ${POOL_VRF_PK} --owner ${ACCOUNT_PK} --start-validity 0 --management-threshold 1 >${STAKE_POOL_CERTIFICATE_FILE}

echo " Sign the Stake Pool certificate"
$CLI certificate sign \
    --certificate ${STAKE_POOL_CERTIFICATE_FILE} \
    --key ${ACCOUNT_SK_FILE} \
    --output ${SIGNED_STAKE_POOL_CERTIFICATE_FILE}

echo "SIGNED_STAKE_POOL_CERTIFICATE: $(cat ${SIGNED_STAKE_POOL_CERTIFICATE_FILE})"

echo " ##4. Send the signed Stake Pool certificate to the blockchain"
./send-certificate.sh stake_pool.cert ${REST_PORT} ${ACCOUNT_SK}

echo " ##5. Retrieve your stake pool id (NodeId)"
cat stake_pool.cert | $CLI certificate get-stake-pool-id | tee stake_pool.id

NODE_ID=$(cat stake_pool.id)

echo "============== Stake Pool details ================"
echo "Stake Pool ID:    ${NODE_ID}"
echo "Stake Pool owner: ${ACCOUNT_ADDR}"
echo "TAX_VALUE:        ${TAX_VALUE}"
echo "TAX_RATIO:        ${TAX_RATIO}"
echo "TAX_LIMIT:        ${TAX_LIMIT}"
echo "=================================================="

rm ${STAKE_POOL_CERTIFICATE_FILE} ${ACCOUNT_SK_FILE} ${SIGNED_STAKE_POOL_CERTIFICATE_FILE}

echo " ##6. Create the node_secret.yaml file"
#define the template.
cat > node_secret.yaml << EOF
genesis:
  sig_key: ${POOL_KES_SK}
  vrf_key: ${POOL_VRF_SK}
  node_id: ${NODE_ID}
EOF

```

`nano ~/files/send-certificate.sh`
(Paste the following into send-certificate.sh)
```
#!/bin/sh

# Disclaimer:
#
#  The following use of shell script is for demonstration and understanding
#  only, it should *NOT* be used at scale or for any sort of serious
#  deployment, and is solely used for learning how the node and blockchain
#  works, and how to interact with everything.
#
#  It also asumes that `jcli` is in the same folder with the script.
#
#  Tutorials can be found here: https://iohk.zendesk.com/hc/en-us/categories/360002383814-Shelley-Networked-Testnet

### CONFIGURATION
CLI="jcli"
COLORS=1
ADDRTYPE="--testing"
TIMEOUT_NO_OF_BLOCKS=200

getTip() {
  echo $($CLI rest v0 tip get -h "${REST_URL}")
}

waitNewBlockCreated() {
  COUNTER=${TIMEOUT_NO_OF_BLOCKS}
  echo "  ##Waiting for new block to be created (timeout = $COUNTER blocks = $((${COUNTER}*${SLOT_DURATION}))s)"
  initialTip=$(getTip)
  actualTip=$(getTip)

  while [ "${actualTip}" = "${initialTip}" ]; do
    sleep ${SLOT_DURATION}
    actualTip=$(getTip)
    COUNTER=$((COUNTER - 1))
    if [ ${COUNTER} -lt 2 ]; then
      echo "  ##ERROR: Waited $(($COUNTER * $SLOT_DURATION))s secs ($COUNTER*$SLOT_DURATION) and no new block created"
      exit 1
    fi
  done
  echo "New block was created - $(getTip)"
}

### COLORS
if [ ${COLORS} -eq 1 ]; then
    GREEN=`printf "\033[0;32m"`
    RED=`printf "\033[0;31m"`
    BLUE=`printf "\033[0;33m"`
    WHITE=`printf "\033[0m"`
else
    GREEN=""
    RED=""
    BLUE=""
    WHITE=""
fi

if [ $# -ne 3 ]; then
    echo "usage: $0 <CERTIFICATE-PATH> <REST-LISTEN-PORT> <ACCOUNT-SOURCE-SK>"
    echo "    <CERT-PATH>   Path to a readable certificate file"
    echo "    <REST-PORT>   The REST Listen Port set in node-config.yaml file (EX: 3101)"
    echo "    <SOURCE-SK>   The Secret key of the Source address"
    exit 1
fi

CERTIFICATE_PATH="$1"
REST_PORT="$2"
ACCOUNT_SK="$3"

REST_URL="http://127.0.0.1:${REST_PORT}/api"

FEE_CONSTANT=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'constant:' | sed -e 's/^[[:space:]]*//' | sed -e 's/constant: //')
FEE_COEFFICIENT=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'coefficient:' | sed -e 's/^[[:space:]]*//' | sed -e 's/coefficient: //')
FEE_CERTIFICATE=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'certificate:' | sed -e 's/^[[:space:]]*//' | sed -e 's/certificate: //')
BLOCK0_HASH=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'block0Hash:' | sed -e 's/^[[:space:]]*//' | sed -e 's/block0Hash: //')
MAX_TXS_PER_BLOCK=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'maxTxsPerBlock:' | sed -e 's/^[[:space:]]*//' | sed -e 's/maxTxsPerBlock: //')
SLOT_DURATION=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'slotDuration:' | sed -e 's/^[[:space:]]*//' | sed -e 's/slotDuration: //')
SLOTS_PER_EPOCH=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'slotsPerEpoch:' | sed -e 's/^[[:space:]]*//' | sed -e 's/slotsPerEpoch: //')

echo "===============Send Certificate================="
echo "CERTIFICATE_PATH: ${CERTIFICATE_PATH}"
echo "REST_PORT: ${REST_PORT}"
echo "ACCOUNT_SK: ${ACCOUNT_SK}"
echo "BLOCK0_HASH: ${BLOCK0_HASH}"
echo "FEE_CONSTANT: ${FEE_CONSTANT}"
echo "FEE_COEFFICIENT: ${FEE_COEFFICIENT}"
echo "FEE_CERTIFICATE: ${FEE_CERTIFICATE}"
echo "=================================================="

STAGING_FILE="staging.$$.transaction"

if [ ! -r ${CERTIFICATE_PATH} ]; then
    echo "certificate file does not exist or is not readable"
    usage ${0}
    exit 1
fi

#CLI transaction
if [ -f "${STAGING_FILE}" ]; then
    echo "error: staging already exist. restart"
    exit 2
fi

set -e

ACCOUNT_PK=$(echo ${ACCOUNT_SK} | $CLI key to-public)
ACCOUNT_ADDR=$($CLI address account ${ADDRTYPE} ${ACCOUNT_PK})

# TODO we should do this in one call to increase the atomicity, but otherwise
ACCOUNT_COUNTER=$( $CLI rest v0 account get "${ACCOUNT_ADDR}" -h "${REST_URL}" | grep '^counter:' | sed -e 's/counter: //' )

# the account is going to pay for the fee ... so calculate how much
ACCOUNT_AMOUNT=$((${FEE_CONSTANT} + ${FEE_COEFFICIENT} + ${FEE_CERTIFICATE}))

# Create the transaction
# FROM: ACCOUNT for FEES
echo " ##1. Create the offline transaction file"
$CLI transaction new --staging ${STAGING_FILE}

echo " ##2. Add the Account to the transaction"
$CLI transaction add-account "${ACCOUNT_ADDR}" "${ACCOUNT_AMOUNT}" --staging "${STAGING_FILE}"

echo " ##3. Add the certificate to the transaction"
$CLI transaction add-certificate --staging ${STAGING_FILE} $(cat ${CERTIFICATE_PATH})

echo " ##4. Finalize the transaction"
$CLI transaction finalize --staging ${STAGING_FILE}

TRANSACTION_ID=$($CLI transaction data-for-witness --staging ${STAGING_FILE})

# Create the witness for the 1 input (add-account) and add it
WITNESS_SECRET_FILE="witness.secret.$$"
WITNESS_OUTPUT_FILE="witness.out.$$"

printf "${ACCOUNT_SK}" > ${WITNESS_SECRET_FILE}

echo " ##5. Make the witness"
$CLI transaction make-witness ${TRANSACTION_ID} \
    --genesis-block-hash ${BLOCK0_HASH} \
    --type "account" --account-spending-counter "${ACCOUNT_COUNTER}" \
    ${WITNESS_OUTPUT_FILE} ${WITNESS_SECRET_FILE}

echo " ##6. Add the witness to the transaction"
$CLI transaction add-witness ${WITNESS_OUTPUT_FILE} --staging "${STAGING_FILE}"

echo " ##7. Show the transaction info"
$CLI transaction info --fee-constant ${FEE_CONSTANT} --fee-coefficient ${FEE_COEFFICIENT} --fee-certificate ${FEE_CERTIFICATE} --staging "${STAGING_FILE}"

echo " ##8. Seal the transaction"
$CLI transaction seal --staging "${STAGING_FILE}"

echo " ##9. Auth the transactions"
$CLI transaction auth --key ${WITNESS_SECRET_FILE} --staging "${STAGING_FILE}"

echo " ##10. Encode and send the transaction"
$CLI transaction to-message --staging "${STAGING_FILE}" | $CLI rest v0 message post -h "${REST_URL}"

echo " ##11. Remove the temporary files"
rm ${STAGING_FILE} ${WITNESS_SECRET_FILE} ${WITNESS_OUTPUT_FILE}

waitNewBlockCreated

exit 0

```

### Change permissions so scripts are executable
```
chmod +x ~/files/createStakePool.sh
chmod +x ~/files/send-certificate.sh
```

### Execute script
```
# This may take a minute or two to finish
~/files/createStakePool.sh ${REST_PORT} <TAX VALUE> <TAX RATIO> <TAX LIMIT> $(cat ~/files/receiver_secret.key)

<TAX VALUE> The fixed cut the stake pool will take from the total reward, e.g. 25000
<TAX RATIO> The percentage of the remaining value that will be taken from the total e.g. 10/100
<TAX LIMIT> A value that can be set to limit the pool's Tax, e.g. 10000000

# Move node_secret & stake_pool.id to ~/files
mv node_secret.yaml ~/files && mv stake_pool.id ~/files
```

### Check that your stake pool is visible
```
# This will return your node id if it’s visible on the network)
# Note: takes current +1 epoch
jcli rest v0 stake-pools get --host "http://127.0.0.1:${REST_PORT}/api" | grep $(cat ~/files/stake_pool.id)

# Or use this function that does the same as above
is_pool_visible
```

### Stop node, edit node-config.yaml
```
# Stop jormungandr
stop

# Dump the logs
empty_logs

# Edit node-config.yaml so blocks=high, messages=high
nano ~/files/node-config.yaml
```

### Run node as a leader candidate - “Connecting to a Genesis blockchain”
```
# Start the node, pasting in the genesis-block-hash
nohup jormungandr --config ~/files/node-config.yaml --secret ~/files/node_secret.yaml --genesis-block-hash ${GENESIS_BLOCK_HASH} >> ~/logs/node.out 2>&1 &

# Or use this function that does the same as above
start_leader

# Always check the logs for errors when starting the node
logs
```

### Back up staking keys, etc
```
# In the terminal tab for your LOCAL machine
# Copy staking keys to your local machine

scp -P <YOUR SSH PORT> -i ~/.ssh/<YOUR SSH PRIVATE KEY> <YOUR VPS USERNAME>@<YOUR PUBLIC IP ADDR>:files/<FILENAME> ~/jormungandr-backups/<JORMUNGANDR VERSION>/
```

### Create script to delegate stake to your node
```
nano ~/files/delegate-account.sh

# Paste the following into delegate-account.sh
# This script is intended to be used, as-is... ie no placeholders need to be replaced.
```
```
#!/bin/sh

# Disclaimer:
#
#  The following use of shell script is for demonstration and understanding
#  only, it should *NOT* be used at scale or for any sort of serious
#  deployment, and is solely used for learning how the node and blockchain
#  works, and how to interact with everything.
#
#  It also asumes that `jcli` is in the same folder with the script.
#
#  Tutorials can be found here: https://github.com/input-output-hk/shelley-testnet/wiki

### CONFIGURATION
CLI="jcli"
COLORS=1
ADDRTYPE="--testing"
TIMEOUT_NO_OF_BLOCKS=200

getTip() {
  echo $($CLI rest v0 tip get -h "${REST_URL}")
}

waitNewBlockCreated() {
  COUNTER=${TIMEOUT_NO_OF_BLOCKS}
  echo "  ##Waiting for new block to be created (timeout = ${COUNTER} blocks = $((${COUNTER}*${SLOT_DURATION}))s)"
  initialTip=$(getTip)
  actualTip=$(getTip)

  while [ "${actualTip}" = "${initialTip}" ]; do
    sleep ${SLOT_DURATION}
    actualTip=$(getTip)
    COUNTER=$((COUNTER - 1))
    if [ ${COUNTER} -lt 2 ]; then
      echo "  !!!!!! ERROR: Waited $((${TIMEOUT_NO_OF_BLOCKS} * ${SLOT_DURATION}))s secs (${TIMEOUT_NO_OF_BLOCKS}*${SLOT_DURATION}) and no new block created"
      exit 1
    fi
  done
  echo "New block was created - $(getTip)"
}

### COLORS
if [ ${COLORS} -eq 1 ]; then
    GREEN=`printf "\033[0;32m"`
    RED=`printf "\033[0;31m"`
    BLUE=`printf "\033[0;33m"`
    WHITE=`printf "\033[0m"`
else
    GREEN=""
    RED=""
    BLUE=""
    WHITE=""
fi

if [ $# -ne 3 ]; then
    echo "usage: $0 <STAKE_POOL_ID> <REST-LISTEN-PORT> <ACCOUNT-SK>"
    echo "    <STAKE_POOL_ID>  The ID of the Stake Pool you want to delegate to"
    echo "    <REST-PORT>      The REST Listen Port set in node-config.yaml file (EX: 3101)"
    echo "    <ACCOUNT-SK>     The Secret key of the Account address"
    exit 1
fi

STAKE_POOL_ID="$1"
REST_PORT="$2"
ACCOUNT_SK="$3"

REST_URL="http://127.0.0.1:${REST_PORT}/api"
BLOCK0_HASH=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'block0Hash:' | sed -e 's/^[[:space:]]*//' | sed -e 's/block0Hash: //')
FEE_CONSTANT=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'constant:' | sed -e 's/^[[:space:]]*//' | sed -e 's/constant: //')
FEE_COEFFICIENT=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'coefficient:' | sed -e 's/^[[:space:]]*//' | sed -e 's/coefficient: //')
FEE_CERTIFICATE=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'certificate:' | sed -e 's/^[[:space:]]*//' | sed -e 's/certificate: //')
MAX_TXS_PER_BLOCK=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'maxTxsPerBlock:' | sed -e 's/^[[:space:]]*//' | sed -e 's/maxTxsPerBlock: //')
SLOT_DURATION=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'slotDuration:' | sed -e 's/^[[:space:]]*//' | sed -e 's/slotDuration: //')
SLOTS_PER_EPOCH=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'slotsPerEpoch:' | sed -e 's/^[[:space:]]*//' | sed -e 's/slotsPerEpoch: //')

echo "================DELEGATE ACCOUNT================="
echo "REST_PORT:        ${REST_PORT}"
echo "ACCOUNT_SK:       ${ACCOUNT_SK}"
echo "BLOCK0_HASH:      ${BLOCK0_HASH}"
echo "FEE_CONSTANT:     ${FEE_CONSTANT}"
echo "FEE_COEFFICIENT:  ${FEE_COEFFICIENT}"
echo "FEE_CERTIFICATE:  ${FEE_CERTIFICATE}"
echo "=================================================="

STAGING_FILE="staging.$$.transaction"

#CLI transaction
if [ -f "${STAGING_FILE}" ]; then
    echo "error: staging already exist. restart"
    exit 2
fi

ACCOUNT_PK=$(echo ${ACCOUNT_SK} | $CLI key to-public)
ACCOUNT_ADDR=$($CLI address account ${ADDRTYPE} ${ACCOUNT_PK})

echo " ##1. Create the delegation certificate for the Account address"

ACCOUNT_SK_FILE="account.prv"
CERTIFICATE_FILE="account_delegation_certificate"
SIGNED_CERTIFICATE_FILE="account_delegation_certificate.signed"
echo ${ACCOUNT_SK} > ${ACCOUNT_SK_FILE}

$CLI certificate new stake-delegation \
    ${ACCOUNT_PK} \
    ${STAKE_POOL_ID} \
    --output ${CERTIFICATE_FILE}

echo "Sign the delegation certificate"
$CLI certificate sign \
    --certificate ${CERTIFICATE_FILE} \
    --key ${ACCOUNT_SK_FILE} \
    --output ${SIGNED_CERTIFICATE_FILE}

ACCOUNT_COUNTER=$( $CLI rest v0 account get "${ACCOUNT_ADDR}" -h "${REST_URL}" | grep '^counter:' | sed -e 's/counter: //' )
ACCOUNT_AMOUNT=$((${FEE_CONSTANT} + ${FEE_COEFFICIENT} + ${FEE_CERTIFICATE}))

echo " ##2. Create the offline delegation transaction for the Account address"
$CLI transaction new --staging ${STAGING_FILE}

echo " ##3. Add input account to the transaction"
$CLI transaction add-account "${ACCOUNT_ADDR}" "${ACCOUNT_AMOUNT}" --staging "${STAGING_FILE}"

echo " ##4. Add the certificate to the transaction"
#cat ${SIGNED_CERTIFICATE_FILE} | xargs $CLI transaction add-certificate --staging ${STAGING_FILE}
cat ${CERTIFICATE_FILE} | xargs $CLI transaction add-certificate --staging ${STAGING_FILE}

echo " ##5. Finalize the transaction"
$CLI transaction finalize --staging ${STAGING_FILE}

# get the transaction data-for-witness
TRANSACTION_ID=$($CLI transaction data-for-witness --staging ${STAGING_FILE})

echo " ##6. Create the withness"
WITNESS_SECRET_FILE="witness.secret.$$"
WITNESS_OUTPUT_FILE="witness.out.$$"
printf "${ACCOUNT_SK}" > ${WITNESS_SECRET_FILE}

$CLI transaction make-witness ${TRANSACTION_ID} \
    --genesis-block-hash ${BLOCK0_HASH} \
    --type "account" --account-spending-counter "${ACCOUNT_COUNTER}" \
    ${WITNESS_OUTPUT_FILE} ${WITNESS_SECRET_FILE}

echo " ##7. Add the witness to the transaction"
$CLI transaction add-witness ${WITNESS_OUTPUT_FILE} --staging "${STAGING_FILE}"

echo " ##8. Show the transaction info"
$CLI transaction info --fee-constant ${FEE_CONSTANT} --fee-coefficient ${FEE_COEFFICIENT} --fee-certificate ${FEE_CERTIFICATE} --staging "${STAGING_FILE}"

echo " ##9. Seal the transaction"
$CLI transaction seal --staging "${STAGING_FILE}"

echo " ##10. Auth the transactions"
$CLI transaction auth --key ${WITNESS_SECRET_FILE} --staging "${STAGING_FILE}"

echo " ##11. Encode and send the transaction"
$CLI transaction to-message --staging "${STAGING_FILE}" | $CLI rest v0 message post -h "${REST_URL}"

waitNewBlockCreated

echo " Account delegation signed certificate: $(cat ${SIGNED_CERTIFICATE_FILE})"

echo " ##10. Check the account's delegation status"
$CLI rest v0 account get ${ACCOUNT_ADDR} -h ${REST_URL}

rm ${STAGING_FILE} ${ACCOUNT_SK_FILE} ${CERTIFICATE_FILE} ${SIGNED_CERTIFICATE_FILE} ${WITNESS_SECRET_FILE} ${WITNESS_OUTPUT_FILE}

exit 0

```
### Execute the script to delegate stake
```
# Make the script executable
chmod +x ~/files/delegate-account.sh

# Execute the script
~/files/delegate-account.sh $(cat ~/files/stake_pool.id) ${REST_PORT} $(cat ~/files/receiver_secret.key)

# Or use this shell function that executes the same thing
delegate
```

### Add delegation scripts to version control
```
# See what files have changed (red text)
git status

# Add files to the staging area
# FYI https://medium.com/@lucasmaurer/git-gud-the-working-tree-staging-area-and-local-repo-a1f0f4822018
git add .

# Save the changes as a commit (-m means "add a one-line comment")
git commit -m 'Add delegation scripts, etc.'
```

### Troubleshooting
```
# ERROR
# Can't log in to VPS

# WHY?
# We restricted access on two fronts: sshd_config (specifying a custom ssh port) & ufw ("uncomplicated firewall")
# If we changed the ssh port in sshd_config, we have to make sure ufw allows that port

# THE FIX:
# From your VPS dashboard, log-in via the console option.
# Type "ufw disable"
# Type "ufw status verbose"
# If you see your chosen ssh port listed, type "ufw enable" then "service ufw restart"
# If you don't see your chosen ssh port listed, review the ufw section above

---------------

# ERROR
# "nohup: failed to run command 'jormungandr': no such file or directory"

# WHY?
# Rust didn't load properly when .bash_profile was evaluated

# THE FIX
# Type "source $HOME/.cargo/env"
```

### Bonus: git cheat-sheet
```
# Git is version control software. Github is a centralized code repository.
# A "branch" is a version of your code. The "master" branch is best reserved as an exact copy of "production code."
# It is considered best-practice to make a copy of the master branch, and modify from there;

# List available branches
git branch

# Switch to another branch
git checkout <BRANCH NAME>

# Make a copy of the current branch, give it a new name, and switch to that branch
git checkout -b <NEW BRANCH NAME>

# List files that have been changed
git status

# Pull down the latest changes from the github repo (stop your node first)
git checkout master
git fetch origin master
git merge FETCH_HEAD

# Track changes to the file I just edited
git add <FILENAME>

# Track changes to every file I changed in this directory
git add .

# Commit the tracked changes to a snapshot (refered to as a "commit")
git commit -m 'Some useful comment about the changes'

# List commits to this branch (type "q" to quit)
git log

# Show the differences between two branches
git diff <OTHER BRANCH NAME> <OPTIONAL FILENAME>

# Jump back to a previous commit
git checkout <HASH OF THE COMMIT>

# Jump back to the most recent commit
git checkout HEAD

# Temporarily stash untracked changes (ie when you need to switch branches, but aren't ready to commit)
git stash
# Re-apply the stashed changes
git stash apply

# Revert changes to a single file from a previous commit
git log
git checkout <HASH OF THE COMMIT (OR A BRANCH NAME)> <FILENAME>
git add <FILENAME>
git commit -m 'Some comment about what you did'

# I've royally screwed up this branch. Delete all the changes, revert to a previous commit
git log
git reset --hard <HASH OF THE COMMIT I WANT TO REVERT TO>

# I just want to get back to where I was before I added/committed
git log
git reset --soft <HASH OF THE COMMIT I WANT TO REVERT TO>
```

## Optional .bash_aliases
`nano .bash_aliases`

```
# Cast Python2 aside and don't look back
alias python="python3"
alias pip="pip3"

# git
alias gb="git branch"
alias gpom="git pull origin master"
alias gcom="git checkout master"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gst="git status"
alias gad="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gmm="git merge master"

# misc
alias claer="clear"

# a "Recursively search current directory for file" that's easy to remember. Call it like this: f <FILENAME>
f() { find . -iname "*$1*"; }
```

# You finished! Buy me a beer?
```
DdzFFzCqrhsjtq9YsgFKeWABaC62QdnPSrsz4GHg762R9qE86YwQTrkCYtMEUtWgb5aEsRbqHAj6Gztdw3BJMKVrCDQbf8HKc9SsnvVk
```

