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
    echo "$(jcli rest v0 account get $(cat ~/files/mastr.addr) -h  http://127.0.0.1:${REST_PORT}/api)"
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
    echo ${GREEN}$(jcli rest v0 stake-pools get --host "http://127.0.0.1:${REST_PORT}/api" | grep $(cat ~/files/stake_pool.id))
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

function schedule {
    leader_logs | grep scheduled_at_date | sort
}

function elections() {
    echo "How many slots has this node been scheduled to be leader?"
    echo "$(jcli rest v0 leaders logs get -h http://127.0.0.1:${REST_PORT}/api | grep created_at_time | wc -l)"
}

function pool_stats() {
    echo "$(jcli rest v0 stake-pool get $(cat ~/files/stake_pool.id) -h http://127.0.0.1:${REST_PORT}/api)"
}

function problems() {
    grep -E -i 'cannot|stuck|exit|unavailable' ~/logs/node.out
}

function jail() {
    curl http://127.0.0.1:${REST_PORT}/api/v0/network/p2p/quarantined | rg -o "/ip4/.{0,16}" | tr -d '/ip4tcp' | uniq -u
}

function jail_count() {
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
    cat ~/logs/node.out | grep tip
}

function delta() {
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

	    if [[ $deltaBlockCount < $deltaMax && ! -z $shelleyLastBlockCount ]]
	    then
                break
	    fi

	    counter=$(($counter+1))
	    echo "INVALID RESULT. RETRYING..."
	    sleep 3
	done

        if [[ -z "$shelleyLastBlockCount" ]]
        then
            echo ""
            echo "INVALID FORK!"
            echo ""
        else
            deltaBlockCount=`echo $(($shelleyLastBlockCount-$lastBlockCount))`
        fi

        echo "LastBlockCount: " $lastBlockCount
        echo "LastShelleyBlock: " $shelleyLastBlockCount
        echo "DeltaCount: " $deltaBlockCount
}

function d2() {
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
