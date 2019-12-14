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
#  Tutorials can be found here: https://github.com/input-output-hk/shelley-testnet/wiki

### CONFIGURATION
CLI="./jcli"
COLORS=1
ADDRTYPE="--testing"
TIMEOUT_NO_OF_BLOCKS=200

getTip() {
  echo $($CLI rest v0 tip get -h "${REST_URL}")
}

waitNewBlockCreated() {
  COUNTER=${TIMEOUT_NO_OF_BLOCKS}
  echo "  ##Waiting for new block to be created (timeout = $COUNTER blocks = $((${COUNTER}*${SLOT_DURATION}))s)"
  initialTip=$(getTip)
  actualTip=$(getTip)

  while [ "${actualTip}" = "${initialTip}" ]; do
    sleep ${SLOT_DURATION}
    actualTip=$(getTip)
    COUNTER=$((COUNTER - 1))
    if [ ${COUNTER} -lt 2 ]; then
      echo "  ##ERROR: Waited $(($COUNTER * $SLOT_DURATION))s secs ($COUNTER*$SLOT_DURATION) and no new block created"
      exit 1
    fi
  done
  echo "New block was created - $(getTip)"
}

### COLORS
if [ ${COLORS} -eq 1 ]; then
    GREEN=`printf "\033[0;32m"`
    RED=`printf "\033[0;31m"`
    BLUE=`printf "\033[0;33m"`
    WHITE=`printf "\033[0m"`
else
    GREEN=""
    RED=""
    BLUE=""
    WHITE=""
fi

if [ $# -ne 3 ]; then
    echo "usage: $0 <CERTIFICATE-PATH> <REST-LISTEN-PORT> <ACCOUNT-SOURCE-SK>"
    echo "    <CERT-PATH>   Path to a readable certificate file"
    echo "    <REST-PORT>   The REST Listen Port set in node-config.yaml file (EX: 3101)"
    echo "    <SOURCE-SK>   The Secret key of the Source address"
    exit 1
fi

CERTIFICATE_PATH="$1"
REST_PORT="$2"
ACCOUNT_SK="$3"

REST_URL="http://127.0.0.1:${REST_PORT}/api"

FEE_CONSTANT=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'constant:' | sed -e 's/^[[:space:]]*//' | sed -e 's/constant: //')
FEE_COEFFICIENT=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'coefficient:' | sed -e 's/^[[:space:]]*//' | sed -e 's/coefficient: //')
FEE_CERTIFICATE=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'certificate:' | sed -e 's/^[[:space:]]*//' | sed -e 's/certificate: //')
FEE_CERTIFICATE_POOL_REGISTRATION=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'certificate_pool_registration:' | sed -e 's/^[[:space:]]*//' | sed -e 's/certificate_pool_registration: //')
FEE_CERTIFICATE_STAKE_DELEGATION=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'certificate_stake_delegation:' | sed -e 's/^[[:space:]]*//' | sed -e 's/certificate_stake_delegation: //')
BLOCK0_HASH=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'block0Hash:' | sed -e 's/^[[:space:]]*//' | sed -e 's/block0Hash: //')
MAX_TXS_PER_BLOCK=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'maxTxsPerBlock:' | sed -e 's/^[[:space:]]*//' | sed -e 's/maxTxsPerBlock: //')
SLOT_DURATION=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'slotDuration:' | sed -e 's/^[[:space:]]*//' | sed -e 's/slotDuration: //')
SLOTS_PER_EPOCH=$($CLI rest v0 settings get -h "${REST_URL}" | grep 'slotsPerEpoch:' | sed -e 's/^[[:space:]]*//' | sed -e 's/slotsPerEpoch: //')

echo "===============Send Certificate================="
echo "CERTIFICATE_PATH  : ${CERTIFICATE_PATH}"
echo "REST_PORT         : ${REST_PORT}"
echo "ACCOUNT_SK        : ${ACCOUNT_SK}"
echo "BLOCK0_HASH       : ${BLOCK0_HASH}"
echo "FEE_CONSTANT      : ${FEE_CONSTANT}"
echo "FEE_COEFFICIENT   : ${FEE_COEFFICIENT}"
echo "FEE_CERTIFICATE   : ${FEE_CERTIFICATE}"
echo "FEE_CERTIFICATE_POOL_REGISTRATION:  ${FEE_CERTIFICATE_POOL_REGISTRATION}"
echo "FEE_CERTIFICATE_STAKE_DELEGATION :  ${FEE_CERTIFICATE_STAKE_DELEGATION}"
echo "=================================================="

STAGING_FILE="staging.$$.transaction"

if [ ! -r ${CERTIFICATE_PATH} ]; then
    echo "certificate file does not exist or is not readable"
    usage ${0}
    exit 1
fi

#CLI transaction
if [ -f "${STAGING_FILE}" ]; then
    echo "error: staging already exist. restart"
    exit 2
fi

set -e

ACCOUNT_PK=$(echo ${ACCOUNT_SK} | $CLI key to-public)
ACCOUNT_ADDR=$($CLI address account ${ADDRTYPE} ${ACCOUNT_PK})

# TODO we should do this in one call to increase the atomicity, but otherwise
ACCOUNT_COUNTER=$( $CLI rest v0 account get "${ACCOUNT_ADDR}" -h "${REST_URL}" | grep '^counter:' | sed -e 's/counter: //' )

# the account is going to pay for the fee ... so calculate how much
ACCOUNT_AMOUNT=$((${FEE_CONSTANT} + ${FEE_COEFFICIENT} + ${FEE_CERTIFICATE_POOL_REGISTRATION}))

# Create the transaction
# FROM: ACCOUNT for FEES
echo " ##1. Create the offline transaction file"
$CLI transaction new --staging ${STAGING_FILE}

echo " ##2. Add the Account to the transaction"
$CLI transaction add-account "${ACCOUNT_ADDR}" "${ACCOUNT_AMOUNT}" --staging "${STAGING_FILE}"

echo " ##3. Add the certificate to the transaction"
$CLI transaction add-certificate --staging ${STAGING_FILE} $(cat ${CERTIFICATE_PATH})

echo " ##4. Finalize the transaction"
$CLI transaction finalize --staging ${STAGING_FILE}

TRANSACTION_DATA_FOR_WITNESS=$($CLI transaction data-for-witness --staging ${STAGING_FILE})

# Create the witness for the 1 input (add-account) and add it
WITNESS_SECRET_FILE="witness.secret.$$"
WITNESS_OUTPUT_FILE="witness.out.$$"

printf "${ACCOUNT_SK}" > ${WITNESS_SECRET_FILE}

echo " ##5. Make the witness"
$CLI transaction make-witness ${TRANSACTION_DATA_FOR_WITNESS} \
    --genesis-block-hash ${BLOCK0_HASH} \
    --type "account" --account-spending-counter "${ACCOUNT_COUNTER}" \
    ${WITNESS_OUTPUT_FILE} ${WITNESS_SECRET_FILE}

echo " ##6. Add the witness to the transaction"
$CLI transaction add-witness ${WITNESS_OUTPUT_FILE} --staging "${STAGING_FILE}"

echo " ##7. Show the transaction info"
$CLI transaction info --fee-constant ${FEE_CONSTANT} --fee-coefficient ${FEE_COEFFICIENT} --fee-certificate ${FEE_CERTIFICATE} --staging "${STAGING_FILE}"

echo " ##8. Seal the transaction"
$CLI transaction seal --staging "${STAGING_FILE}"

echo " ##9. Auth the transactions"
$CLI transaction auth --key ${WITNESS_SECRET_FILE} --staging "${STAGING_FILE}"

echo " ##10. Encode and send the transaction"
$CLI transaction to-message --staging "${STAGING_FILE}" | $CLI rest v0 message post -h "${REST_URL}"

echo " ##11. Remove the temporary files"
rm ${STAGING_FILE} ${WITNESS_SECRET_FILE} ${WITNESS_OUTPUT_FILE}

waitNewBlockCreated

exit 0
