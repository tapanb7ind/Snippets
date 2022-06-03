#!/bin/bash

TOOL="jmeter"
TOOL_VERSION="5.4.3.1a"
CONTAINER_NAME="jmeter"
DOCKER_IMAGE="POD/jmeter:5.4.3.1a"
DOCKER_COMPOSE="docker-compose-custom.yml"
JMETER_CONFIG_XMX=1g
JMETER_CONFIG_XMS=1g
TEST_PARAM_HOST="gorest.co.in"
JMETER_CONFIG_PORT=443
protocol=https
RUN_TIME_MINS=1
JMETER_CONFIG_SLAVES=1
EXECUTABLE_FILE=Demo_Plan.jmx
ADMIN_TOKEN=""
ADDITIONAL_JMETER_ARGS=""
TOTAL_USERS=5
RAMP_UP=1

RESULTS_PREFIX="pe_results"
LOG_LEVEL="INFO"
STAGE="Test-Environment"

S3KEY=""
S3SECRET=""
S3_BUCKET="S3-Bucket-Name[Invalid]"

# Thresholds
MAX_USERS_ALLOWED=30
MAX_DURATION_IN_MINS=61
MAX_SLAVES=5

# Gracefully exit time for virtual users
#VUSER_STOP_TIME_OUT=30    # time is seconds to wait before forcing all users to quit


onAbort(){
  echo "Abort request received. Trying to remove container(s)"
  echo "[Container:${CONTAINER_NAME}] Saving Test Results [COMPLETED]"
  echo "[Container:${CONTAINER_NAME}] Stopping container"
  docker stop "${CONTAINER_NAME}"
  echo "[Container:${CONTAINER_NAME}] Stopping container [STOPPED]"
  echo "[Container:${CONTAINER_NAME}] Removing container"
  docker rm --force -v "${CONTAINER_NAME}"
}

# Read arguments from command-line
# Example
#   API : ./jmeterrunner.sh EXECUTABLE_FILE=<jmx file name> ADMIN_TOKEN=<value goes here>
#     with admin token:
#       ./jmeterrunner.sh EXECUTABLE_FILE=<jmx file name> ADMIN_TOKEN=<value goes here>

for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            ADMIN_TOKEN)                ADMIN_TOKEN=${VALUE} ;;
            EXECUTABLE_FILE)            EXECUTABLE_FILE=${VALUE} ;;
            TEST_PARAM_HOST)            TEST_PARAM_HOST=${VALUE} ;;
            RESULTS_PREFIX)             RESULTS_PREFIX=${VALUE} ;;
            TOTAL_USERS)                TOTAL_USERS=${VALUE} ;;
            RAMP_UP)                    RAMP_UP=${VALUE} ;;
            RUN_TIME_MINS)              RUN_TIME_MINS=${VALUE} ;;
            LOG_LEVEL)                  LOG_LEVEL=${VALUE} ;;
            TESTIDENTIFIER)             TESTIDENTIFIER=${VALUE} ;;
            ADDITIONAL_JMETER_ARGS)     ADDITIONAL_JMETER_ARGS=${VALUE} ;;
            STAGE)                      STAGE=${VALUE} ;;
            *)
    esac
done


# region :: Verify input parameters

echo "Verifying input parameters (if any)"
if [[ ! $ADMIN_TOKEN ]]; then
    echo "[WARNING] ADMIN_TOKEN is NOT PROVIDED.
    Workflows requiring this value will result is errors during the test run"
    echo "[INFO] Looking for PE_INT_TOKEN, if available will be used in place of ADMIN_TOKEN"
    if [[ $PE_INT_TOKEN ]]; then
      ADMIN_TOKEN=$PE_INT_TOKEN
    else
      ADMIN_TOKEN=""
    fi;
fi;

if [[ ! $TEST_PARAM_HOST ]]; then
    echo "[ERROR] TEST_PARAM_HOST is empty"
    exit 1
fi;

if [[ $ADDITIONAL_JMETER_ARGS ]]; then
    echo "[INFO] Additional Jmeter Args provided [${ADDITIONAL_JMETER_ARGS}]"
fi;

if [[ ! $TESTIDENTIFIER ]]; then
    echo "[WARN] TESTIDENTIFIER is empty"
    testidentifier=$(uuidgen)
else
    echo "[INFO] Test Identifier is not empty"
    testidentifier=$TESTIDENTIFIER
fi;

if [[ ! $STAGE ]]; then
    echo "[WARN] stage is empty. File(s) will be uploaded in 'dev'"
#    exit 1
  STAGE="dev"
fi;

if ! [[ $TOTAL_USERS && "$TOTAL_USERS" =~ ^[0-9]+$ ]] ; then
    echo "[WARN] TOTAL_USERS is invalid/empty [Current Value:${TOTAL_USERS}]"
    TOTAL_USERS=1
elif [[ $TOTAL_USERS -gt 0 && "$TOTAL_USERS" -le $MAX_USERS_ALLOWED ]] ; then
        TOTAL_USERS=$TOTAL_USERS
else
    echo "[ERROR] TOTAL_USERS should be more than 0 and less than ${MAX_USERS_ALLOWED} [Current Value:${TOTAL_USERS}]"
    TOTAL_USERS=1
fi;

if ! [[ $RUN_TIME_MINS && "$RUN_TIME_MINS" =~ ^[0-9]+$ ]] ; then
    echo "[ERROR] RUN_TIME_MINS should be more than 0 and less than ${MAX_DURATION_IN_MINS} [Current Value:${RUN_TIME_MINS}]"
    RUN_TIME_MINS=1
elif [[ $RUN_TIME_MINS -gt 0 && $RUN_TIME_MINS -le ${MAX_DURATION_IN_MINS} ]] ; then
        RUN_TIME_MINS=$RUN_TIME_MINS
else
    echo "[WARN] RUN_TIME_MINS should be more than 0 and less than ${MAX_DURATION_IN_MINS} [Current Value:${RUN_TIME_MINS}]"
    RUN_TIME_MINS=1
fi;

RUN_TIME=$((RUN_TIME_MINS * 60))

JMX=$EXECUTABLE_FILE
EXECUTABLE_FILE="./scenario/${EXECUTABLE_FILE}"
FILE=$EXECUTABLE_FILE
if test -f "$FILE"; then
  echo "[INFO] Executable File $EXECUTABLE_FILE exists"
else
  echo "[ERROR] Executable File [$EXECUTABLE_FILE] not found"
  ls -ltr
  exit 1;
fi;

# endregion


echo "****************** EXECUTION PARAMS ******************"
echo "[DEBUG] Environment (Stage) => ${STAGE}"
echo "[DEBUG] ADMIN_TOKEN => $ADMIN_TOKEN"
echo "[DEBUG] EXECUTABLE_FILE => $EXECUTABLE_FILE"
echo "[DEBUG] RESULTS_PREFIX => $RESULTS_PREFIX"
echo "[DEBUG] TOTAL_USERS => $TOTAL_USERS"
echo "[DEBUG] RAMP_UP (seconds) => $RAMP_UP"
echo "[DEBUG] RUN_TIME (seconds) => $RUN_TIME"
echo "[DEBUG] LOG_LEVEL => $LOG_LEVEL"
echo "[DEBUG] TOOL => $TOOL"
echo "[DEBUG] TOOL_VERSION => $TOOL_VERSION"
echo "[DEBUG] DOCKER IMAGE => ${DOCKER_IMAGE}"
echo "[DEBUG] CONTAINER_NAME => ${CONTAINER_NAME}"
echo "******************************************************"
    
    echo "[INFO] Creating .env file for execution"
    # [TODO] Additional params for jmeter can be passed using the .env file logic
    # [TODO] Update entrypoint.sh file to append any additional parameters passed via this file
    printf '%s\n' "DOCKER_IMAGE=${DOCKER_IMAGE}" "TESTIDENTIFIER=${testidentifier}" "XMX=1g" "XMS=1g" "host=${TEST_PARAM_HOST}" "port=${JMETER_CONFIG_PORT}" "protocol=${protocol}" "threads=${TOTAL_USERS}" "duration=${RUN_TIME}" "rampup=${RAMP_UP}" "nbInjector=1" "JMX=${JMX}" "admin_token=${ADMIN_TOKEN}" > ./.env

    echo "[INFO] Initializing PE test execution using JMETER"
    echo "[INFO] Test Identifier: $testidentifier"

    trap "onAbort" SIGTERM SIGINT

    echo "[DEBUG] Cleaning up files in 'split' directory"
    ls -ltr ./data/split
    rm -r ./data/split/*

    echo "[INFO] initiating docker container [Name:${CONTAINER_NAME}]"
    echo "[Container:${CONTAINER_NAME}] Starting test"
    source .env && JMX=$JMX docker-compose -f $DOCKER_COMPOSE -p "${CONTAINER_NAME}" up --scale jmeter-slave="${JMETER_CONFIG_SLAVES}"

    echo "[INFO] [Container:${CONTAINER_NAME}] Test COMPLETED"
    echo "[INFO] [Container:${CONTAINER_NAME}] Saving Test Results [STARTED]"

    RESULT_DIR="./report/${testidentifier}"
#    ls -ltr $RESULT_DIR

    echo "[INFO] Copying results [${RESULT_DIR}] to Archive Directory"

    # Copy .html report to workspace
    cp -R $RESULT_DIR ../Archive/

    echo "[INFO] [Container:${CONTAINER_NAME}] Saving Test Results [COMPLETED]"
    echo "[INFO] [Container:${CONTAINER_NAME}] Stopping container"
    docker-compose -p "${CONTAINER_NAME}" down
    echo "[INFO] [Container:${CONTAINER_NAME}] Stopping container [STOPPED]"
    echo "[INFO] [Container:${CONTAINER_NAME}] Removing container"
    echo "[INFO] ********* COMPLETED **********"
