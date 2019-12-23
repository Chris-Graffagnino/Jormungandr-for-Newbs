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

# Install ripgrep, because it's awesome
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.2/ripgrep_11.0.2_amd64.deb
sudo dpkg -i ripgrep_11.0.2_amd64.deb
rm ripgrep_11.0.2_amd64.deb

# These instructions will prevent certain errors when installing Rust
mkdir /home/<USERNAME>/.cargo && mkdir /home/<USERNAME>/.cargo/bin
chown -R <USERNAME> /home/<USERNAME>/.cargo
touch /home/<USERNAME>/.profile
chown <USERNAME> /home/<USERNAME>/.profile
```

## Increase open file limit
```
nano /etc/security/limits.conf

# Add the following at the bottom of the file
<USERNAME> soft nofile 32768
<USERNAME> hard nofile 1048576

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

# Choose a port between 1024 and 6535 for other nodes to connect to. This will be your PUBLIC_ADDRESS_PORT
 sudo ufw allow proto tcp from any to any port <NUMBER BETWEEN 1024 AND 65535>

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

## Download some scripts
```
# Download files from my repo
git clone https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs.git -b files-only --single-branch files

# Make the scripts executable
chmod +x ~/files/send-lovelaces.sh
chmod +x ~/files/createStakePool.sh
chmod +x ~/files/send-certificate.sh
chmod +x ~/files/delegate-account.sh

# Create .bashrc && .bash_profile
# Note: You downloaded these to the files directory, although they are hidden. Type "ls -la ~/files"
cat ~/files/.bashrc > ~/.bashrc && cat ~/files/.bash_profile > ~/.bash_profile

# Now that you've copied the files to the proper location, delete the duplicate from the files directory
rm ~/files/.bashrc && rm ~/files/.bash_profile

# Change ownership of .bashrc and .bash_profile
chown <USERNAME> ~/.bashrc
chown <USERNAME> ~/.bash_profile

# Restrict access to .bashrc and .bash_profile
chmod 700 ~/.bashrc && chmod 700 ~/.bash_profile

# Reload environment variables in to your current shell
source ~/.bash_profile

# Hey, my prompt looks funny now? Yes, it does. Did you really need it to tell you who you are :)
# The prompt can get quite long, depending how deep in the directory structure you are. Better to
# save space. So what you'll see now is your location in the directory tree, followed by which
# git branch you're on.
# If you like your original prompt better, open .bashrc and comment out this line
# export PS1="\[\e[36m\]\w\[\e[m\]\[\e[35m\] \`parse_git_branch\`\[\e[m\] \[\e[36m\]:\[\e[m\] "
```

### About environment variables
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

# Okay, enough about that. Next, we'll add some commands to .bashrc so important values are loaded as
# environment variables every time we log in.
```

## Type each of the following commands in terminal
##### (replace placeholder text)
```
echo "export USERNAME='<YOUR USERNAME>'" >> ~/.bashrc
echo "export PUBLIC_IP_ADDR='<YOUR PUBLIC IP ADDRESS>'" >> ~/.bashrc
echo "export REST_PORT='<YOUR REST PORT>'" >> ~/.bashrc
echo "export PUBLIC_ADDRESS_PORT='<YOUR PUBLIC ADDRESS PORT>'" >> ~/.bashrc
echo "export JORMUNGANDR_RESTAPI_URL='http://127.0.0.1:<YOUR REST PORT>/api'" >> ~/.bashrc
echo "export JORMUNGANDR_STORAGE_DIR='/home/<YOUR USERNAME>/storage'" >> ~/.bashrc

# What did we just do?
# "echo" essentially means "print to screen"
# "export" declares a variable in a special way, so that any shells that spawn from it inherit the variable.
# ">>" means "take the output of the previous command and append it to the end of a file (.bashrc, in this case)
```

## Configure swap to handle memory spikes
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
```

## Optimize linux performance
`sudo nano /etc/sysctl.conf`  

(Add the following to the bottom of /etc/sysctl.conf)
```
fs.file-max = 10000000
fs.nr_open = 10000000

net.core.netdev_max_backlog = 100000
net.core.somaxconn = 100000
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 100000
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.tcp_mem = 786432 1697152 1945728
net.ipv4.tcp_reordering = 3
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_sack = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 5
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_wmem = 4096 16384 16777216

net.netfilter.nf_conntrack_max = 10485760
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 15

vm.swappiness = 5
vm.vfs_cache_pressure = 50
```

### reload /etc/sysctl.conf
`sudo sysctl -p /etc/sysctl.conf`

### Create a file to preserve our system settings on reboot
`sudo nano /etc/rc.local`   
(paste the follwing into /etc/rc.local)
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

# Find the latest release
git tag
(press shift+g to jump to the bottom of the list)

# Take note of the last item in the list, (ie v0.8.5-alpha3)
(press 'q' to exit the list)

git checkout <THE LAST TAG IN THE LIST>
git checkout -b <NEW BRANCH NAME eg 8.5>

# Update submodules
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

### Modify node-config.yaml
```
nano ~/files/node-config.yaml

# Check Telegram (StakePool Best Practice Workgroup) for up-to-date genesis-hash & trusted peers
# https://t.me/CardanoStakePoolWorkgroup/74812

# Replace <THE PLACEHOLDERS> with the appropriate values
```
```
log:
- output: stderr
  format: plain
  level: info
p2p:
  topics_of_interest:
    blocks: normal
    messages: low
  listen_address: "/ip4/0.0.0.0/tcp/<YOUR PUBLIC ADDRESS PORT>"
  public_address: "/ip4/<YOUR PUBLIC IP ADDRESS>/tcp/<YOUR PUBLIC ADDRESS PORT>"
  # Adjust max_connections based on your cpu/ram usage. This setting typically works well for 2cpu/4G ram.
  # Monitor usage w/ "memory" shell function; if you have multiple cpu's, press shift+i to measure the load across all cpu's
  max_connections: 4096
  gossip_interval: 20s
  trusted_peers:
    - address: "/ip4/13.56.0.226/tcp/3000"
      id: 7ddf203c86a012e8863ef19d96aabba23d2445c492d86267
    - address: "/ip4/54.183.149.167/tcp/3000"
      id: df02383863ae5e14fea5d51a092585da34e689a73f704613
    - address: "/ip4/52.9.77.197/tcp/3000"
      id: fcdf302895236d012635052725a0cdfc2e8ee394a1935b63
    - address: "/ip4/18.177.78.96/tcp/3000"
      id: fc89bff08ec4e054b4f03106f5312834abdf2fcb444610e9
    - address: "/ip4/3.115.154.161/tcp/3000"
      id: 35bead7d45b3b8bda5e74aa12126d871069e7617b7f4fe62
    - address: "/ip4/18.182.115.51/tcp/3000"
      id: 8529e334a39a5b6033b698be2040b1089d8f67e0102e2575
    - address: "/ip4/18.184.35.137/tcp/3000"
      id: 06aa98b0ab6589f464d08911717115ef354161f0dc727858
    - address: "/ip4/3.125.31.84/tcp/3000"
      id: 8f9ff09765684199b351d520defac463b1282a63d3cc99ca
    - address: "/ip4/3.125.183.71/tcp/3000"
      id: 9d15a9e2f1336c7acda8ced34e929f697dc24ea0910c3e67
    - address: "/ip4/52.9.132.248/tcp/3000"
      id: 671a9e7a5c739532668511bea823f0f5c5557c99b813456c
    - address: "/ip4/52.8.15.52/tcp/3000"
      id: 18bf81a75e5b15a49b843a66f61602e14d4261fb5595b5f5
    - address: "/ip4/13.114.196.228/tcp/3000"
      id: 7e1020c2e2107a849a8353876d047085f475c9bc646e42e9
    - address: "/ip4/13.112.181.42/tcp/3000"
      id: 52762c49a84699d43c96fdfe6de18079fb2512077d6aa5bc
    - address: "/ip4/3.125.75.156/tcp/3000"
      id: 22fb117f9f72f38b21bca5c0f069766c0d4327925d967791
    - address: "/ip4/52.28.91.178/tcp/3000"
      id: 23b3ca09c644fe8098f64c24d75d9f79c8e058642e63a28c
    - address: "/ip4/3.124.116.145/tcp/3000"
      id: 99cb10f53185fbef110472d45a36082905ee12df8a049b74
rest:
  listen: "127.0.0.1:<REST_PORT>"
storage: /home/<YOUR USERNAME>/storage
mempool:
    fragment_ttl: 2h
    log_ttl: 24h
    garbage_collection_interval: 2h
```

(Did you remember to replace the PLACEHOLDERS with the appropriate values)?

### create a directory for storage
```
mkdir /home/<YOUR USERNAME>/storage
```

### generate the secret key
`jcli key generate --type=Ed25519Extended > ~/files/receiver_secret.key`

### derive the public key from the secret key
`cat ~/files/receiver_secret.key | jcli key to-public > ~/files/receiver_public.key`

### derive the public address from the public key
```
jcli address account --testing --prefix addr $(cat ~/files/receiver_public.key) | tee ~/files/receiver_account.txt
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
nohup jormungandr --config ~/files/node-config.yaml --genesis-block-hash ${GENESIS_BLOCK_HASH} >> ~/logs/node.out 2>&1 &

# Or use this shell function
start
```

### Inspect the output 

```
# Always check the logs when starting a node to make sure it started without error
logs
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

# How much diskspace is jormungandr using? (alias "jordsk")
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
git checkout -b <NAME OF BRANCH, e.g. 8.0>

# Compile the binaries
git submodule update --init --recursive
cargo install --path jormungandr --force
cargo install --path jcli --force

# Verify you're up to date
jormungandr --full-version
jcli --full-version
```

## Script Usage
```
# send-lovelaces.sh
~/files/send-lovelaces.sh <DESTINATION ADDRESS> <AMOUNT LOVELACES TO SEND> ${REST_PORT} $(cat ~/files/receiver_secret.key)

# createStakePool.sh
usage: ~/files/createStakePool.sh <REST-LISTEN-PORT> <TAX_VALUE> <TAX_RATIO> <TAX_LIMIT> <ACCOUNT_SK>
    <REST-LISTEN-PORT>   The REST Listen Port set in node-config.yaml file (EX: 3101)
    <TAX_VALUE>   The fixed cut the stake pool will take from the total reward
    <TAX_RATIO>   The percentage of the remaining value that will be taken from the total
    <SOURCE-SK>   The Secret key of the Source address

# send-certificate.sh is called by createStakePool.sh and is not intended for you.

# delegate-account.sh
usage: ~/files/delegate-account.sh <ACCOUNT-SK> <STAKE_POOL_ID>:1
    <ACCOUNT-SK>     The Secret key of the Account address
    <STAKE_POOL_ID:WEIGHT>  An stake pool ID, followed by ":<SOME INTEGER>"

    Multiple pools, separated by spaces, e.g. <ID>:<WEIGHT> <ID>:<WEIGHT>
```

## Create stake pool
```
# This may take a minute or two to finish
~/files/createStakePool.sh ${REST_PORT} <TAX VALUE> <TAX RATIO> <TAX LIMIT> $(cat ~/files/receiver_secret.key)

# Move node_secret & stake_pool.id to ~/files
mv node_secret.yaml ~/files && mv stake_pool.id ~/files
```

### Check that your stake pool is visible
```
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
# Start the node as leader
start_leader

# Always check the logs for errors when starting the node
logs
```

# Delegate your funds to your stake pool
```
~/files/delegate-account.sh $(cat ~/files/receiver_secret.key) $(cat ~/files/stake_pool.id):1

# Or use this shell function that executes the same thing
delegate
```

### Back up staking keys, etc
```
# In the terminal tab for your LOCAL machine
# Copy staking keys to your local machine

scp -P <YOUR SSH PORT> -i ~/.ssh/<YOUR SSH PRIVATE KEY> <YOUR VPS USERNAME>@<YOUR PUBLIC IP ADDR>:files/<FILENAME> ~/jormungandr-backups/<JORMUNGANDR VERSION>/
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

