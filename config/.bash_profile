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
    echo "Proto Recv-Q Send-Q Local Address           Foreign Address         State"
    nodes="$(netstat -tupan | grep jor | grep EST | cut -c 1-80)"
    total="$(netstat -tupan | grep jor | grep EST | cut -c 1-80 | wc -l)"
    printf "%s\n" "${nodes}" "----------" "Total:" "${total}"
}

function num_open_files() {
    echo "Calculating number of open files..."
    echo "$(lsof -u $(whoami) | wc -l)"
}

function is_pool_visible() {
    stake_pool_id="$(cat ~/files/node_secret.yaml | grep node_id | awk -F: '{print $2 }')"
    echo "Display my stake pool id if it is visible on the blockchain. Otherwise, return nothing."
    echo ${GREEN}$(jcli rest v0 stake-pools get --host "http://127.0.0.1:${REST_PORT}/api" | grep $stake_pool_id)
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

function schedule() {
    leader_logs | grep scheduled_at_date | sort
}

function when() {
    leader_logs | grep scheduled_at_time | sort
}

function elections() {
    echo "How many slots has this node been scheduled to be leader?"
    echo "$(jcli rest v0 leaders logs get -h http://127.0.0.1:${REST_PORT}/api | grep created_at_time | wc -l)"
}

function pool_stats() {
    echo "$(jcli rest v0 stake-pool get $(cat ~/files/node_secret.yaml | grep node_id | awk -F: '{print $2 }') -h http://127.0.0.1:${REST_PORT}/api)"
}

function problems() {
    grep -E -i 'cannot|stuck|exit|unavailable' ~/logs/node.out
}

function jail() {
    echo "List of IP addresses that were quarantined somewhat recently:"
    curl http://127.0.0.1:${REST_PORT}/api/v0/network/p2p/quarantined | rg -o "/ip4/.{0,16}" | tr -d '/ip4tcp' | uniq -u
    echo "End of somewhat recently quarantined IP addresses."
}

function busted() {
    echo "Have I been quarantined recently?"
    this_node=`jail | rg "${PUBLIC_IP_ADDR}"`
    if [[ ! -z ${this_node} ]]; then
        echo "Busted! You were quarantined at some point in the recent past!"
        echo "Execute 'nodes' to confirm that you are connecting to other nodes."
    else
        echo "You are clean as a whistle."
    fi
}

function blocked() {
    echo "These IP addresses were recently blocked by UFW:"
    sudo tail -n 150 /var/log/syslog | grep UFW | grep TCP
    echo "End of recently blocked IP addresses."
}

function nblocked() {
    echo "How many IP addresses were blocked by UFW?"
    sudo cat /var/log/syslog | grep UFW | grep TCP | wc -l
}

function jail_count() {
    echo "How many IP addresses were quarantined?"
    jail | wc -l
}

function disk() {
    echo "Testing disk-write speed in MB/s..."
    echo "-------------------------------"
    dd if=/dev/zero of=/tmp/output conv=fdatasync bs=384k count=1k; rm -f /tmp/output
}

function frags() {
    echo "What is the current frag count?"
    jcli rest v0 message logs -h http://127.0.0.1:${REST_PORT}/api | grep "frag" | wc -l
}

function portsentry_stats() {
    sudo grep portsentry /var/log/syslog | awk '{print $6}' | sort | uniq -c
}

function tip() {
    grep ~/logs/node.out
}

function delta() {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color

    lastBlockHash=`stats | head -n 6 | tail -n 1 | awk '{print $2}'`
    lastBlockCount=`stats | head -n 7 | tail -n 1 | awk '{print $2}' | tr -d \"`

    tries=6
    deltaMax=5
    counter=0

    while [[ $counter -le $tries ]]
    do
        shelleyExplorerJson=`curl -X POST -H "Content-Type: application/json" --data '{"query": " query {   allBlocks (last: 3) {    pageInfo { hasNextPage hasPreviousPage startCursor endCursor  }  totalCount  edges {    node {     id  date { slot epoch {  id  firstBlock { id  }  lastBlock { id  }  totalBlocks }  }  transactions { totalCount edges {   node {    id  block { id date {   slot   epoch {    id  firstBlock { id  }  lastBlock { id  }  totalBlocks   } } leader {   __typename   ... on Pool {    id  blocks { totalCount  }  registration { startValidity managementThreshold owners operators rewards {   fixed   ratio {  numerator  denominator   }   maxLimit } rewardAccount {   id }  }   } }  }  inputs { amount address {   id }  }  outputs { amount address {   id }  }   }   cursor }  }  previousBlock { id  }  chainLength  leader { __typename ... on Pool {  id  blocks { totalCount  }  registration { startValidity managementThreshold owners operators rewards {   fixed   ratio {  numerator  denominator   }   maxLimit } rewardAccount {   id }  } }  }    }    cursor  }   } }  "}' https://explorer.incentivized-testnet.iohkdev.io/explorer/graphql 2> /dev/null`
        shelleyLastBlockCount=`echo $shelleyExplorerJson | grep -m 1 -o '"chainLength":"[^"]*' | cut -d'"' -f4 | awk '{print $NF}'`
        shelleyLastBlockCount=`echo $shelleyLastBlockCount|cut -d ' ' -f3`
        deltaBlockCount=`echo $(($shelleyLastBlockCount-$lastBlockCount))`

        if [[ ! -z $shelleyLastBlockCount ]]; then
            break
        fi

        counter=$(($counter+1))
        echo -e ${RED}"INVALID RESULT. RETRYING..."${NC}
        sleep 3
    done

    if [[ -z "$shelleyLastBlockCount" ]]
    then
        echo ""
        echo -e ${RED}"INVALID FORK!"${NC}
        echo ""
    else
        deltaBlockCount=`echo $(($shelleyLastBlockCount-$lastBlockCount))`
    fi

    echo "LastBlockCount: " $lastBlockCount
    echo "LastShelleyBlock: " $shelleyLastBlockCount
    echo "DeltaCount: " $deltaBlockCount

    if [[ $deltaBlockCount > $deltaMax ]]; then
        echo -e ${RED}"Your node was possibily forked"${NC}
    else
        echo -e ${GREEN}"Your node is running well"${NC}
    fi
}
