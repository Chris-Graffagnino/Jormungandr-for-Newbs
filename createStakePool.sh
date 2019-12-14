#!/bin/sh

# Disclaimer:
#
#  The following use of shell script is for demonstration and understanding
#  only, it should *NOT* be used at scale or for any sort of serious
#  deployment, and is solely used for learning how the node and blockchain
#  works, and how to interact with everything.
#
#  It also asumes that `jcli` is in the same folder with the script.
#
# Scenario:
#   Configure 1 stake pool having as owner the provided account address (secret key)
#
#  Tutorials can be found here: https://iohk.zendesk.com/hc/en-us/categories/360002383814-Shelley-Networked-Testnet

### CONFIGURATION
CLI="./jcli"
COLORS=1
ADDRTYPE="--testing"

if [ $# -ne 4 ]; then
    echo "usage: $0 <REST-LISTEN-PORT> <TAX_VALUE> <TAX_RATIO> <ACCOUNT_SK>"
    echo "    <REST-LISTEN-PORT>   The REST Listen Port set in node-config.yaml file (EX: 3101)"
    echo "    <TAX_VALUE>   The fixed cut the stake pool will take from the total reward"
    echo "    <TAX_RATIO>   The percentage of the remaining value that will be taken from the total (EX: '1/10')"
    echo "    <SOURCE-SK>   The Secret key of the Source address"
    exit 1
fi

REST_PORT="$1"
TAX_VALUE="$2"
TAX_RATIO="$3"
ACCOUNT_SK="$4"

REST_URL="http://127.0.0.1:${REST_PORT}/api"
BLOCK0_HASH=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'block0Hash:' | sed -e 's/^[[:space:]]*//' | sed -e 's/block0Hash: //')

ACCOUNT_PK=$(echo ${ACCOUNT_SK} | $CLI key to-public)
ACCOUNT_ADDR=$($CLI address account ${ADDRTYPE} ${ACCOUNT_PK})

echo "================ Blockchain details ================="
echo "BLOCK0_HASH:  ${BLOCK0_HASH}"
echo "REST_PORT:    ${REST_PORT}"
echo "TAX_VALUE:    ${TAX_VALUE}"
echo "TAX_RATIO:    ${TAX_RATIO}"
echo "ACCOUNT_SK:   ${ACCOUNT_SK}"
echo "=================================================="

echo " ##1. Create VRF keys"
POOL_VRF_SK=$($CLI key generate --type=Curve25519_2HashDH)
POOL_VRF_PK=$(echo ${POOL_VRF_SK} | $CLI key to-public)

echo POOL_VRF_SK: ${POOL_VRF_SK}
echo POOL_VRF_PK: ${POOL_VRF_PK}

echo " ##2. Create KES keys"
POOL_KES_SK=$($CLI key generate --type=SumEd25519_12)
POOL_KES_PK=$(echo ${POOL_KES_SK} | $CLI key to-public)

echo POOL_KES_SK: ${POOL_KES_SK}
echo POOL_KES_PK: ${POOL_KES_PK}

echo " ##3. Create the Stake Pool certificate using above VRF and KEY public keys"
ACCOUNT_SK_FILE="account.privateKey"
STAKE_POOL_CERTIFICATE_FILE="stake_pool.cert"
SIGNED_STAKE_POOL_CERTIFICATE_FILE="stake_pool_certificate.signed"
echo ${ACCOUNT_SK} > ${ACCOUNT_SK_FILE}

$CLI certificate new stake-pool-registration --tax-fixed ${TAX_VALUE} --tax-ratio ${TAX_RATIO} --kes-key ${POOL_KES_PK} --vrf-key ${POOL_VRF_PK} --owner ${ACCOUNT_PK} --start-validity 0 --management-threshold 1 >${STAKE_POOL_CERTIFICATE_FILE}

echo " Sign the Stake Pool certificate"
$CLI certificate sign \
    --certificate ${STAKE_POOL_CERTIFICATE_FILE} \
    --key ${ACCOUNT_SK_FILE} \
    --output ${SIGNED_STAKE_POOL_CERTIFICATE_FILE}

echo "SIGNED_STAKE_POOL_CERTIFICATE: $(cat ${SIGNED_STAKE_POOL_CERTIFICATE_FILE})"

echo " ##4. Send the signed Stake Pool certificate to the blockchain"
./send-certificate.sh stake_pool.cert ${REST_PORT} ${ACCOUNT_SK}

echo " ##5. Retrieve your stake pool id (NodeId)"
cat stake_pool.cert | $CLI certificate get-stake-pool-id | tee stake_pool.id

NODE_ID=$(cat stake_pool.id)

echo "============== Stake Pool details ================"
echo "Stake Pool ID:    ${NODE_ID}"
echo "Stake Pool owner: ${ACCOUNT_ADDR}"
echo "TAX_VALUE:        ${TAX_VALUE}"
echo "TAX_RATIO:        ${TAX_RATIO}"
echo "=================================================="

rm ${STAKE_POOL_CERTIFICATE_FILE} ${ACCOUNT_SK_FILE} ${SIGNED_STAKE_POOL_CERTIFICATE_FILE}

echo " ##6. Create the node_secret.yaml file"
#define the template.
cat > node_secret.yaml << EOF
genesis:
  sig_key: ${POOL_KES_SK}
  vrf_key: ${POOL_VRF_SK}
  node_id: ${NODE_ID}
EOF