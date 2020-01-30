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
