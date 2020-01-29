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

function tcp_stats() {
    cat /proc/net/netstat | awk '(f==0) { i=1; while ( i<=NF) {n[i] = $i; i++ }; f=1; next} \
    (f==1){ i=2; while ( i<=NF){ printf "%s = %d\n", n[i], $i; i++}; f=0}'
}

function bal() {
    echo "$(jcli rest v0 account get $(cat ~/files/receiver_account.txt) -h http://127.0.0.1:${REST_PORT}/api)"
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

function connections() {
    echo "Show ip addresses that are connected more than once:"
    netstat -tn 2>/dev/null | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head
}

function sockets() {
    netstat -tn | tail -n +3 | awk "{ print \$6 }" | sort | uniq -c | sort -n
}

function num_open_files() {
    echo "Calculating number of open files..."
    echo "$(lsof -u $(whoami) | wc -l)"
}

function is_pool_visible() {
    GREEN=$(printf "\033[0;32m")
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
    tail -n 60 ~/logs/node.out
}

function empty_logs() {
    > ~/logs/node.out
}

function check_peers() {
    sed -e '/ address/!d' -e '/#/d' -e 's@^.*/ip./\([^/]*\)/tcp/\([0-9]*\).*@\1 \2@' ~/files/node-config.yaml | \
    while read addr port
    do 
        tcpping -x 1 $addr $port
    done
}

function leader_logs() {
    echo "Has this node been scheduled to be leader?"
    echo "$(jcli rest v0 leaders logs get -h http://127.0.0.1:${REST_PORT}/api)"
}

function schedule() {
    echo "Which block dates are this node scheduled to generate a block during this epoch?"
    leader_logs | grep scheduled_at_date | cut -d'"' -f2 | cut -d'.' -f2 | sort -g
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
    grep tip ~/logs/node.out
}

function settings() {
    echo "$(jcli rest v0 settings get --host ${REST_URL})"
}

function current_blocktime() {
	chainstartdate=$(settings | grep "block0Time:" | awk '{print $2}' | tr -d '"' | xargs -I{} date "+%s" -d {})
	nowtime=$(date +%s)

	chaintime=$(($nowtime-$chainstartdate))

	slot=$((($chaintime % 86400)))
	epoch=$(($chaintime / 86400))
}

function next() {
  	NEWEPOCH=$(stats | grep Date | grep -Eo '[0-9]{1,3}' | awk 'NR==1{print $1}')
	maxSlots=$(leader_logs | grep -P 'scheduled_at_date: "'$NEWEPOCH'.' | grep -P '[0-9]+' | wc -l)
    leaderSlots=$(leader_logs | grep -P 'scheduled_at_date: "'$NEWEPOCH'.' | grep -P '[0-9]+' | awk -v i="$rowIndex" '{print $2}' | awk -F "." '{print $2}' | tr '"' ' ' | sort -V)
	for (( rowIndex = 1; rowIndex <= $maxSlots ; rowIndex++ ))
	do
		current_blocktime
		currentSlotTime=$((slot/2))
		#currentSlotTime=$(stats | grep 'lastBlockDate: "'$NEWEPOCH'.' | awk -F "." '{print $2}' | tr '"' ' ')
		blockCreatedSlotTime=$(awk -v i="$rowIndex" 'NR==i {print $1}' <<< $leaderSlots)

		if [[ $blockCreatedSlotTime -ge $currentSlotTime ]];
		then
			timeToNextSlotLead=$(($blockCreatedSlotTime-$currentSlotTime))
			currentTime=$(date +%s)
			nextBlockDate=$(($chainstartdate+$blockCreatedSlotTime*2+($epoch)*86400))
			echo "TimeToNextSlotLead: " $(awk '{print int($1/(3600*24))":"int($1/60)":"int($1%60)}' <<< $(($timeToNextSlotLead*2))) "("$(awk '{print strftime("%c",$1)}' <<< $nextBlockDate)") - $(($blockCreatedSlotTime))"
			break;
		fi
	done
}

function delta() {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
	ORANGE='\033[0;33m'
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

	next

    now=$(date +"%r")

	isNumberRegex='^[0-9]+$'
	if [[  -z $lastBlockCount || ! $lastBlockCount =~ $isNumberRegex ]]; then
       echo -e ${RED}"$now: Your node appears to be starting or not running at all. Execute 'stats' to get more info."${NC}
	   return
    fi
    if [[ $deltaBlockCount -lt $deltaMax && $deltaBlockCount -gt 0 ]]; then
       echo -e ${ORANGE}"$now: WARNING: Your node is starting to drift. It could end up on an invalid fork soon."${NC}
	   return
    fi
    if [[ $deltaBlockCount -gt $deltaMax ]]; then
       echo -e ${RED}"$now: WARNING: Your node might be forked."${NC}
	   return
    fi
    if [[ $deltaBlockCount -le 0 ]]; then
       echo -e ${GREEN}"$now: Your node is running well."${NC}
	   return
    fi
}

export PATH="$HOME/.cargo/bin:$PATH"
