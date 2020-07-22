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

# Copy the contents of <YOUR KEYNAME>.pub to the clipboard
(If you are on a Mac, do the following. Otherwise, open the file and copy normally)  
`cat ~/.ssh/<YOUR KEYNAME>.pub | pbcopy
```

## Add ssh public key to github

![go_to_settings](https://user-images.githubusercontent.com/8118351/70385781-575a3e00-1988-11ea-96e3-a792d8ffde68.png)

#### Go to "ssh and gpg keys"
![go_to_ssh_and_gpg_keys](https://user-images.githubusercontent.com/8118351/70385783-5cb78880-1988-11ea-9bda-11b71c62ec1a.png)

#### If you do NOT have an ssh key-pair on github, add them.

![click_new_ssh_key](https://user-images.githubusercontent.com/8118351/70385823-c46dd380-1988-11ea-9ae8-40f83091511e.png)

#### Title should be something you associate with your computer
(paste the entire contents of your public key file (<FILENAME>.pub) in the larger text-box)
![add_ssh_key](https://user-images.githubusercontent.com/8118351/70385826-cafc4b00-1988-11ea-8938-f725aa12ad89.png)
