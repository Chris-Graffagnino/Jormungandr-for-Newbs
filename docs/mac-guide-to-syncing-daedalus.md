
# Guide to syncing Daedalus Rewards - v1 (ITN)

-- Note: This guide is for improving the time-to-sync of (incentivized testnet) Daedalus.  
-- Note: This guide should __NOT__ be used to modify main-net Daedalus.  

-- DISCLAIMER: By using this guide, you assume sole risk and waive any claims of liability against the author.  
-- DISCLAIMER: By using this guide, you agree to make a backup copy of jormungandr-config.yaml.  

* Guide Author: Chris Graffagnino (stake-pool: __MASTR__)  
* Special thanks to @cryptobaer (stake-pool: __HRMS__)

## Open finder

![daedalus_guide_open_finder](https://user-images.githubusercontent.com/39073373/73613497-3d3a8600-45ee-11ea-97cd-d198c98d0b46.png)

## Select Applications directory

![daedalus_guide_select_applications](https://user-images.githubusercontent.com/39073373/73613506-63f8bc80-45ee-11ea-8104-512f5eff186e.png)

## Select "Daedalus Rewards - v1"

![daedalus_guide_select_itn](https://user-images.githubusercontent.com/39073373/73613535-a6ba9480-45ee-11ea-8f47-8f8d2cf6dbc3.png)

## Press the control-key while clicking, and choose "Show Package Contents"

![daedalus_guide_show_pkg_contents](https://user-images.githubusercontent.com/39073373/73613563-f731f200-45ee-11ea-9c06-5212a4c6cad3.png)

## Open resources directory

![choose_resources_directory](https://user-images.githubusercontent.com/8118351/79615874-499c8e00-80c9-11ea-8361-804e5d8626e2.png)

## Press the control-key while clicking jormungandr-config.yaml

![rename_jormungandr-config](https://user-images.githubusercontent.com/8118351/79616501-d0059f80-80ca-11ea-8edb-1b1c10344549.png)


## Rename the file to jormungandr-config-copy.yaml

![rename_jormungandr-config-copy](https://user-images.githubusercontent.com/8118351/79616582-06431f00-80cb-11ea-8613-f6b58c7f8274.png)



## Press command+spacebar, and type "terminal" to open the program

![daedalus_guide_open_terminal](https://user-images.githubusercontent.com/39073373/73613653-d28a4a00-45ef-11ea-8502-8b10d71cfd80.png)


## Download an improved copy of jormungandr-config.yaml
-- copy/paste the following in to the terminal program, then press enter
```
curl https://raw.githubusercontent.com/Chris-Graffagnino/Jormungandr-for-Newbs/files-only/jormungandr-config.yaml -O
```

## Move the new file to the correct location
-- copy/paste the following in to the terminal program, then press enter
(When prompted, enter your login password)
```
sudo mv ./jormungandr-config.yaml /Applications/"Daedalus - Rewards v1.app"/Resources/
```

## Open Daedalus - Rewards wallet
Daedalus may take a while to download the blockchain. I recommend restarting every 20 minutes until complete.

## Thank you for supporting my efforts!
(My ADA address)
```
DdzFFzCqrhsxYxFWE4iD2XuyjTdKU5ywA98ggnD4qxJ1nreiC3X65ACTa8m8KsYAy7fCNV1BLbFGdR6NLSthMnJZ1gKXqbqFi37qjrYq
```
