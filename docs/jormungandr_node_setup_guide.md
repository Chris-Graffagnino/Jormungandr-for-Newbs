# Setup Cardano Shelley staking node (Ubuntu 18.04)

-- DISCLAIMER: This guide is for educational purposes only. Do not use in production with real funds.  
-- DISCLAIMER: By using this guide, you assume sole risk and waive any claims of liability against the author.  

-- Note: This guide is for running jormungandr on a virtual private server (VPS), running Ubuntu 18.04.  
-- Note: This guide assumes your local machine is a Mac, but most instructions are executed on the remote machine.  
-- Note: anything preceded by "#" is a comment.   
-- Note: anything all-caps in between "<>" is an placeholder; e.g. `"<FILENAME>"` could be `"foo.txt"`.   
-- Note: anything in between "${}" is a variable that will be evaluated by your shell.  

* Author: Chris Graffagnino (stake-pool: __MASTR__)  

* Thanks to these expert contributors!  
@ilap - __UNDR__  
@mark-stopka - __BLTN__  
@pheelLikeWater - __MONKY__  
@Willburn - __ANP__  
	
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

# Copy the contents of <YOUR KEYNAME>.pub to the clipboard
(If you are on a Mac, do the following. Otherwise, open the file and copy normally)  
`cat ~/.ssh/<YOUR KEYNAME>.pub | pbcopy
```

### If using Digital Ocean for vps, follow these instructions instead
[How to Upload SSH Public Keys to a DigitalOcean Account :: DigitalOcean Product Documentation](https://www.digitalocean.com/docs/droplets/how-to/add-ssh-keys/to-account/) 

  
## Add ssh public key to github

![go_to_settings](https://user-images.githubusercontent.com/8118351/70385781-575a3e00-1988-11ea-96e3-a792d8ffde68.png)

#### Go to "ssh and gpg keys"
![go_to_ssh_and_gpg_keys](https://user-images.githubusercontent.com/8118351/70385783-5cb78880-1988-11ea-9bda-11b71c62ec1a.png)

#### If you do NOT have an ssh key-pair on github, add them.

![click_new_ssh_key](https://user-images.githubusercontent.com/8118351/70385823-c46dd380-1988-11ea-9ae8-40f83091511e.png)

#### Title should be something you associate with your computer
(paste the entire contents of your public key file (<FILENAME>.pub) in the larger text-box)
![add_ssh_key](https://user-images.githubusercontent.com/8118351/70385826-cafc4b00-1988-11ea-8938-f725aa12ad89.png)
	
  
  
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
apt install jq
apt install python3-pip
apt-get install tcptraceroute
apt-get install chrony

# Nuke the chrony config, (we'll fix it later)
> /etc/chrony/chrony.conf

# Install tcpping
cd /usr/bin
wget http://www.vdberg.org/~richard/tcpping
chmod 755 tcpping
cd

# Install ripgrep, because it's awesome
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.2/ripgrep_11.0.2_amd64.deb
dpkg -i ripgrep_11.0.2_amd64.deb
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
<USERNAME> soft nofile 800000
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
# Change the line "#ClientAliveInterval 0" to "ClientAliveInterval 1800"

# Type ctrl+o to save, ctrl+x to exit
```

## Configure "uncomplicated firewall" (ufw)
```
# Set defaults for incoming/outgoing ports
ufw default deny incoming
ufw default allow outgoing

# Open ssh port (rate limiting enabled - max 10 attempts within 30 seconds)
ufw limit proto tcp from any to any port <THE PORT YOU JUST CHOSE IN sshd_config>

# Open a port for your public_address. This is the port other nodes will connect to.
ufw allow proto tcp from any to any port 3000

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

# Reload the ssh daemon
# NOTE: You will only be able to log-in using your SSH private key as non-root user
sudo service sshd reload
```

## Download some scripts
```
# Download files from my repo
git clone https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs.git -b files-only --single-branch files

# Make the scripts executable
chmod +x ~/files/*.sh
chmod +x ~/files/env

# Create .bashrc && .bash_profile
# Note: You downloaded these to the files directory, although they are hidden. Type "ls -la ~/files"
cat ~/files/.bashrc > ~/.bashrc && cat ~/files/.bash_profile > ~/.bash_profile && cat ~/files/.bash_aliases > .bash_aliases

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
echo "export REST_URL='http://127.0.0.1:<YOUR REST PORT>/api'" >> ~/.bashrc
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
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048

# If you suffer from low connections, set this to 60.
# Alternatively, if you want to conserve memory, try a lower number.
net.ipv4.tcp_keepalive_time = 30

net.ipv4.tcp_keepalive_intvl = 1
net.ipv4.tcp_keepalive_probes = 5

# Use Google's congestion control algorithm
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

vm.swappiness = 5
vm.vfs_cache_pressure = 50
```

### reload /etc/sysctl.conf
```
sudo sysctl -p /etc/sysctl.conf
```

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

### Edit /etc/chrony/chrony.conf
`sudo nano /etc/chrony/chrony.conf`  
Paste the following into /etc/chrony/chrony.conf
```
pool time.google.com       iburst minpoll 1 maxpoll 1 maxsources 3 prefer
pool ntp.ubuntu.com        iburst minpoll 1 maxpoll 1 maxsources 3 maxdelay 0.3
pool time.nist.gov         iburst minpoll 1 maxpoll 1 maxsources 3 maxdelay 0.3
pool us.pool.ntp.org       iburst minpoll 1 maxpoll 1 maxsources 3 maxdelay 0.3

# This directive specify the location of the file containing ID/key pairs for
# NTP authentication.
keyfile /etc/chrony/chrony.keys

# This directive specify the file into which chronyd will store the rate
# information.
driftfile /var/lib/chrony/chrony.drift

# Uncomment the following line to turn logging on.
#log tracking measurements statistics

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 5.0

# This directive enables kernel synchronisation (every 11 minutes) of the
# real-time clock. Note that it can’t be used along with the 'rtcfile' directive.
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 0.1 -1

# Get TAI-UTC offset and leap seconds from the system tz database
leapsectz right/UTC

# Serve time even if not synchronized to a time source.
local stratum 10
```

#### Finish configuring chrony
```
sudo systemctl restart chrony
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

# NOTE: the last item in the list; non-alpha tag is most recent, (ie v0.8.5 is newer than v0.8.5-alpha3)
(press 'q' to exit the list)

git checkout <THE TAG>
git checkout -b <NEW BRANCH NAME eg 8.14>

# Update submodules
git submodule update --init --recursive
```

## Install the executables
```
cargo install --path jormungandr --force
cargo install --path jcli --force
```

### Create directory & file for logging
```
mkdir ~/logs
touch ~/logs/node.out
```

### Measure trusted peer latency
```
# Make note of the ip addresses with the shortest response time (end of each line, measured in ms)
# If your node takes longer than 3-4 minutes to bootstrap, try commenting the trusted-peers with
# the longest response time in node-config.yaml
# This may take a few seconds to start
check_peers
```

### Modify node-config.yaml
nano ~/files/node-config.yaml
(replace placeholders with appropriate values)
```
log:
- output: stderr
  format: plain
  level: info
p2p:
  topics_of_interest:
    blocks: high
    messages: high
  public_address: "/ip4/<YOUR IP ADDRESS>/tcp/3000"
  gossip_interval: 5s
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

# What is the ip address of this node?
get_ip

# Stop jormungandr
stop

# Start node in passive-mode (before you register as a stake-pool)
start

# Start node as a stake-pool (once you've registered as a stake-pool)
start_leader

# Check stats
stats

# View the last 60 lines of your log file
logs

# Clear the log file
empty_logs

# Check balance
bal

# How many nodes are connected?
# Columns are [protocol, bytes-received, bytes-sent, your-ip, foreign-ip, state]
nodes

# Is node in sync with the network?
delta

# Check memory usage
# If you have multiple cpu's, press shift+i for an accurate measurement
memory (press "q" to quit)

# Is my stake pool id visible to other nodes?
is_pool_visible

# Is node scheduled to be leader?
leader_logs

# Leader logs, by blockDate
schedule

# Leader logs, by blockTime
when

# How many chances to I have to find a block in the current epoch?
elections

# Stake pool stats
pool_stats

# Search the logs for common errors
problems

# List IP addresses that have been recently quarantined
jail

# How many nodes are have been in jail?
jail_count

# Has my node been recently quarantined
busted

# Show the last 150 ip addresses blocked by ufw
blocked

# Show the total number of ip addresses blocked by ufw
nblocked

# Check bandwidth usage
(type q to quit)
nload -m

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

# How much diskspace is jormungandr using?
disk
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

cd
rustup update
git pull

# Use the tagged release
git checkout <A VERSION NUMBER SUCH AS v0.8.18>

# Can't find the tag you want?, delete what you have locally and re-download
git tag -l | xargs git tag -d && git fetch -t

# Create a new branch for yourself
git checkout -b <NAME OF BRANCH, e.g. 8.18>

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
# Before continuing, make sure receiver_account.txt has a balance of at least 500,300,000 lovelaces
# This may take a minute or two to finish
~/files/createStakePool.sh ${REST_PORT} <TAX VALUE> <TAX RATIO> $(cat ~/files/receiver_secret.key)

# Move node_secret & stake_pool.id to ~/files
mv node_secret.yaml ~/files && mv stake_pool.id ~/files
```

### Check that your stake pool is visible
```
is_pool_visible
```

### Restart node as leader-candidate
```
# After restarting, you will be eligible to receive rewards at the start of
# the next epoch

# Stop jormungandr
stop

# Dump the logs
empty_logs

# Start the node as leader
start_leader

# Always check the logs for errors when starting the node to
# make sure there were no errors.
logs
```

### Delegate your funds to your stake pool
```
~/files/delegate-account.sh $(cat ~/files/receiver_secret.key) $(cat ~/files/stake_pool.id):1
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
By now, your fingers are tired. Give them a rest by using .bash_aliases.    
```
cp ~/files/.bash_aliases ~/
. ~/.bash_profile
```

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
DdzFFzCqrht3kMqsjpaLjr3L8tw5Jn2E9Vr9id9R33jB1P4TqRKZ87UVkzrF9NMarNLNKx5fuahvHiaD4Cz9K71CD69QQDBzS5mExsMr
```

