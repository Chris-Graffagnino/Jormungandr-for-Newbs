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
    echo "$(curl -X POST https://faucet.${CHAIN_NAME}.jormungandr-testnet.iohkdev.io/send-money/$(cat ~/files/receiver_account.txt))"
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
    echo "$(~/files/delegate-account.sh $(cat ~/files/receiver_secret.key) $(cat ~/files/stake_pool.id):1)"
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
    echo "$(jcli rest v0 stake-pool get $(cat ~/files/stake_pool.id) -h http://127.0.0.1:${REST_PORT}/api)"
}

function problems() {
    grep -E -i 'cannot|stuck|exit|unavailable' ~/logs/node.out
}

function delta() {
    # Kudos to @pheelLikeWater for this!
    lastBlockHash=`stats | head -n 6 | tail -n 1 | awk '{print $2}'`
    lastBlockCount=`stats | head -n 7 | tail -n 1 | awk '{print $2}' | tr -d \"`
    shelleyExplorerJson=`curl -X POST -H "Content-Type: application/json" --data '{"query":" query { block (id:\"'$lastBlockHash'\") { id date { slot epoch { id firstBlock { id } lastBlock { id } totalBlocks } } transactions { totalCount edges { node { id block { id date { slot epoch { id firstBlock { id } lastBlock { id } totalBlocks } } leader { __typename ... on Pool { id blocks { totalCount } registration { startValidity managementThreshold owners operators rewards { fixed ratio { numerator denominator } maxLimit } rewardAccount { id } } } } } inputs { amount address { id } } outputs { amount address { id } } } cursor } } previousBlock { id } chainLength leader { __typename ... on Pool { id blocks { totalCount } registration { startValidity managementThreshold owners operators rewards { fixed ratio { numerator denominator } maxLimit } rewardAccount { id } } } } } } "}' https://explorer.incentivized-testnet.iohkdev.io/explorer/graphql`
    shelleyLastBlockCount=`echo $shelleyExplorerJson | grep -o '"chainLength":"[^"]*' | cut -d'"' -f4`

    if [[ -z "$shelleyLastBlockCount" ]]
    then
	echo ""
	echo "INVALID FORK!"
	echo ""
    else
        deltaBlockCount=`echo $(($shelleyLastBlockCount-$lastBlockCount))`
    fi

    echo "LastBlockCount: " $lastBlockCount
    echo "LastShellyBlock: " $shelleyLastBlockCount
    echo "DeltaCount: " $deltaBlockCount
}

#reload the cargo configuration environment
source $HOME/.cargo/env
