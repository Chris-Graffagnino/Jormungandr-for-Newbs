# Guide to implementing pooltool.io sendmytip.sh

-- DISCLAIMER: This guide is for educational purposes only.  
-- DISCLAIMER: By using this guide, you assume sole risk and waive any claims of liability against the author.  

-- Note: This guide is for implementing a script to report lastBlockHeight to pooltool.io  
-- Note: anything preceded by "#" is a comment.  
-- Note: anything all-caps in between "<>" is an placeholder; e.g. `"<FILENAME>"` could be `"foo.txt"`.  

* Guide Author: Chris Graffagnino (stake-pool: __MASTR__)  
* Script Author: Mike, aka papacarp from [pooltool.io](https://pooltool.io/)  
-- Consider delegating Mike's pool, __LOVE__  

## About sendmytip.sh
sendmytip.sh shows lastBlockHeight, as reported by participating nodes. It is a useful alternative to Shelley explorer, which
may be under heavy load from time to time. It also gives node operators the opportunity to demonstrate that their node is
in sync with the network.

![pool_tool_badge](https://user-images.githubusercontent.com/8118351/73483749-e176bf80-4397-11ea-9a43-ac18a1eabb35.png)

## Sign up at pooltool.io
[https://pooltool.io/auth](https://pooltool.io/auth)  
(After creating your account, copy the provided API key)
![pool_tool_welcome](https://user-images.githubusercontent.com/8118351/73486697-8b0c7f80-439d-11ea-8be4-a6b5087ec10c.png)

## Modify/Save sendmytip.sh
`nano ~/files/sendmytip.sh`
(copy and paste the following)
```
#!/bin/bash
shopt -s expand_aliases
RESTAPI_PORT=<YOUR REST PORT>
MY_POOL_ID="<YOUR STAKE POOL ID>"
MY_USER_ID="<YOUR POOLTOOL API KEY>"  # https://pooltool.io/profile
THIS_GENESIS="8e4d2a343f3dcf93"   # We only actually look at the first 7 characters

function sendtip() {
  if [ ! $JORMUNGANDR_RESTAPI_URL ]; then export JORMUNGANDR_RESTAPI_URL=http://127.0.0.1:${RESTAPI_PORT}/api; fi
  alias cli="$(which jcli) rest v0"
  local nodestats=$(cli node stats get --output-format json > stats.json);

  local lastBlockHeight=$(cat stats.json | jq -r .lastBlockHeight)
  local lastBlockHash=$(cat stats.json | jq -r .lastBlockHash)
  local lastPoolID=$(cli block ${lastBlockHash} get | cut -c169-232)

  if [ "$lastBlockHeight" != "" ]; then
    local poolToolMax=$(curl -G -s "https://api.pooltool.io/v0/sharemytip?poolid=${MY_POOL_ID}&userid=${MY_USER_ID}&genesispref=${THIS_GENESIS}&mytip=${lastBlockHeight}&lasthash=${lastBlockHash}&lastpool=${lastPoolID}" | jq -r .pooltoolmax)
    echo $poolToolMax
  fi
}

poolToolHeight=$(sendtip)
```
(Please replace the <PLACEHOLDERS> above with appropriate values)

## Call the script manually, for testing purposes
```
# Make the script executable
chmod +x ~/files/sendmytip.sh

# Call the script, to test. You should see "success" in the response. Note that
# repeated calls may return "null," as the API requires at least 20-30 secondsi between calls.
~/files/sendmytip.sh

# If the response returned an error, check the values of RESTAPI_PORT, MY_POOL_ID, and MY_USER_ID.
```

## Call the script in the background
```
# Call the script using nohup, ("no hangup"), and redirect the output to /dev/null. The script will report our lastBlockHeight to pooltool.io.
nohup watch -n 75 ~/files/sendmytip.sh >> /dev/null 2>&1

# Suspend the script
ctrl+z

# Note the job number (in square brackets)
jobs

# Restart the script in the background
bg <JOB NUMBER>

```

