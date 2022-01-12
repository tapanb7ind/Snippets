#!/bin/bash

LOCUST_VERSION="2.5.0"
# testidentifier=$(uuidgen)
requirementsfilepath="requirements.txt"
virtualenv="adhoctest-env"

# Locust related variables
EXECUTABLE_FILE="locust_workflow_runner.py"     # provide path to the python file that executes locust tests on a docker container.
ADMIN_TOKEN=""
WORKFLOW_INSTRUCTION="userwithdevice.json"      # Updated Locust framework uses a way of desgning a api workflow. Provide path to the json file that contains the workflow.
                                                # This can later be used to design the workflow from UI and generate a .json file on-demand.
RESULTS_PREFIX="results"
TOTAL_USERS=1
SPAWN_RATE=1
RUN_TIME_MINS=1
LOG_LEVEL="INFO"
STAGE="integration"

# Thresholds
MAX_USERS_ALLOWED=30
MAX_DURATION_IN_MINS=30

# Read arguments from command-line
# Example: ./locustrunner.sh ADMIN_TOKEN=<value goes here>
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            ADMIN_TOKEN)                ADMIN_TOKEN=${VALUE} ;;
            EXECUTABLE_FILE)            EXECUTABLE_FILE=${VALUE} ;;
            WORKFLOW_INSTRUCTION)       WORKFLOW_INSTRUCTION=${VALUE} ;;
            RESULTS_PREFIX)             RESULTS_PREFIX=${VALUE} ;;
            TOTAL_USERS)                TOTAL_USERS=${VALUE} ;;
            SPAWN_RATE)                 SPAWN_RATE=${VALUE} ;;
            RUN_TIME_MINS)              RUN_TIME_MINS=${VALUE} ;;
            LOG_LEVEL)                  LOG_LEVEL=${VALUE} ;;
            TESTIDENTIFIER)             TESTIDENTIFIER=${VALUE} ;;
            STAGE)                      STAGE=${VALUE} ;;
            *)   
    esac 
done

# [TODO] 1. Verify admin token before starting test by making an API call
# [TODO] 2. Verify parameters before test run
# [TODO] 3. Verify if executable and workflow-instruction file exists
# [TODO] 4. Master-slave setup
  #  Reference: https://medium.com/locust-io-experiments/locust-io-experiments-running-in-docker-cae3c7f9386e
  # https://eskala.io/tutorial/kubernetes-distributed-performance-testing-using-locust/
  # https://medium.com/locust-io-experiments/locust-io-experiments-running-in-kubernetes-95447571a550
# region :: Verify input parameters

echo "Verifying input parameters (if any)"

if [[ ! $ADMIN_TOKEN ]]; then 
    echo "[ERROR] ADMIN_TOKEN is INVALID"
    exit 1; 
fi;

if [[ ! $TESTIDENTIFIER ]]; then 
    echo "[WARN] TESTIDENTIFIER is empty"
    testidentifier=$(uuidgen)
else
    echo "[INFO] Test Identifier is not empty"
    testidentifier=$TESTIDENTIFIER
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

if ! [[ $SPAWN_RATE && "$SPAWN_RATE" =~ ^[0-9]+$ ]] ; then 
    echo "[ERR] SPAWN_RATE should be more than 0 and less than ${TOTAL_USERS} [Current Value:${SPAWN_RATE}]"
    SPAWN_RATE=1
elif [[ $SPAWN_RATE -gt 0 && $SPAWN_RATE -le ${TOTAL_USERS} ]] ; then
        SPAWN_RATE=$SPAWN_RATE
else
    echo "[WARN] SPAWN_RATE should be more than 0 and less than ${TOTAL_USERS} [Current Value:${SPAWN_RATE}]"
    SPAWN_RATE=1
fi;

if ! [[ $RUN_TIME_MINS && "$RUN_TIME_MINS" =~ ^[0-9]+$ ]] ; then 
    echo "[ERR] RUN_TIME_MINS should be more than 0 and less than ${MAX_DURATION_IN_MINS} [Current Value:${RUN_TIME_MINS}]"
    RUN_TIME_MINS=1
elif [[ $RUN_TIME_MINS -gt 0 && $RUN_TIME_MINS -le ${MAX_DURATION_IN_MINS} ]] ; then
        RUN_TIME_MINS=$RUN_TIME_MINS
else
    echo "[WARN] RUN_TIME_MINS should be more than 0 and less than ${MAX_DURATION_IN_MINS} [Current Value:${RUN_TIME_MINS}]"
    RUN_TIME_MINS=1
fi;

# endregion

echo "****************** EXECUTION PARAMS ******************"
echo "Environment (Stage) = ${STAGE}"
echo "ADMIN_TOKEN = $ADMIN_TOKEN"
echo "EXECUTABLE_FILE = $EXECUTABLE_FILE"
echo "WORKFLOW_INSTRUCTION = $WORKFLOW_INSTRUCTION"
echo "RESULTS_PREFIX = $RESULTS_PREFIX"
echo "TOTAL_USERS = $TOTAL_USERS"
echo "SPAWN_RATE = $SPAWN_RATE"
echo "RUN_TIME_MINS = $RUN_TIME_MINS"
echo "LOG_LEVEL = $LOG_LEVEL"
echo "LOCUST_VERSION = $LOCUST_VERSION"
echo "******************************************************"

echo "Initializing PE test execution using LOCUST"
echo "Test Identifier:" $testidentifier

echo "initiating docker container [Name:${testidentifier}-locust]"
    docker run -d --name "${testidentifier}-locust" -i --entrypoint /bin/bash -v $PWD:/workspace locustio/locust:${LOCUST_VERSION}
    docker exec "${testidentifier}-locust" locust --version
echo "[Container:${testidentifier}-locust] Setting Up environment"
    docker exec "${testidentifier}-locust" export PATH="/home/locust/.local/bin:$PATH"
    docker exec "${testidentifier}-locust" pip install virtualenv --verbose
    docker exec "${testidentifier}-locust" python3 -m venv $virtualenv
    docker exec "${testidentifier}-locust" source $virtualenv/bin/activate
echo "[Container:${testidentifier}-locust] Installing project requirements [${requirementsfilepath}]"
    docker exec "${testidentifier}-locust" pip install -r $requirementsfilepath #--verbose
echo "[Container:${testidentifier}-locust] Installing project requirements COMPLETED"
echo "[Container:${testidentifier}-locust] Starting test"
    docker exec "${testidentifier}-locust" locust -f /workspace/${EXECUTABLE_FILE} --users ${TOTAL_USERS} --spawn-rate ${SPAWN_RATE} --headless --host http://localhost.com --run-time ${RUN_TIME_MINS}m --loglevel ${LOG_LEVEL} --logfile=${RESULTS_PREFIX}.log --workflowinstruction /workspace/${WORKFLOW_INSTRUCTION} --admintoken=${ADMIN_TOKEN} --csv ${RESULTS_PREFIX} --html ${RESULTS_PREFIX}_report.html
    # docker exec "${testidentifier}-locust" pwd
echo "[Container:${testidentifier}-locust] Test COMPLETED"
echo "[Container:${testidentifier}-locust] Cleaning Environment [${virtualenv}]"
    docker exec "${testidentifier}-locust" rm -rf ${virtualenv}    
echo "[Container:${testidentifier}-locust] Saving Test Results [STARTED]"
    # docker exec "${testidentifier}-locust" ls -ltr

    docker exec "${testidentifier}-locust" mkdir ${testidentifier}
    docker exec "${testidentifier}-locust" find ./ -name '**_report.html' -type f -exec cp -t ./${testidentifier}/ {} +
    docker exec "${testidentifier}-locust" find ./ -name "**.csv" -type f -exec cp -t ./${testidentifier}/ {} + 
    docker exec "${testidentifier}-locust" find ./ -name "**${RESULTS_PREFIX}.log" -type f -exec cp -t ./${testidentifier}/ {} + 
    # docker exec "${testidentifier}-locust" cp ./${RESULTS_PREFIX}_* ./${testidentifier}/
    # Copy all files in /home/locust/
    docker cp "${testidentifier}-locust:/home/locust/${testidentifier}/." ./Archive/${testidentifier}
    # Copy .html report to workspace    
    cp ./Archive/${testidentifier}/*.html report.html
    cp ./Archive/${testidentifier}/${RESULTS_PREFIX}.log ${RESULTS_PREFIX}.log
    
echo "[Container:${testidentifier}-locust] Saving Test Results [COMPLETED]"    
echo "[Container:${testidentifier}-locust] Stopping container"
    docker stop "${testidentifier}-locust"
echo "[Container:${testidentifier}-locust] Stopping container [STOPPED]"
echo "[Container:${testidentifier}-locust] Removing container"
    docker rm --force -v "${testidentifier}-locust"
