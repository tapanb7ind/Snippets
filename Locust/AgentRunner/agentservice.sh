#!/bin/bash

agent_status="STARTING"
statusfile="agentstatus.txt"
AgentId=0
flagToExit=false
version="1.1.0"

reporter(){
  echo " ===== >>> STARTING REPORTER <<<<===== "
  sleep 2
  _number=1
  while [ $_number -ge 1 ]; do        # let this run for ever
    statusfromfile=$(cat onStart.txt | grep -E -o '"status":"(\S+)"' | cut -d: -f2 | cut -d, -f1 | sed -e 's/"//g')
    echo "[REPORTER] Agent-Status From File:$statusfromfile"

    if [ "$statusfromfile" == "BUSY" ]; then
      # When running test, status reporting is set to every 30 seconds
      echo "A test is in progress, reporting will be done every 30 seconds instead of 5"
      sleep 30
    else
      sleep 10
    fi;

    Endpoint="$API_URL/agentservice/statusReport/$AgentId/$statusfromfile"
    echo "[REPORTER] Posting agent-status to API [$Endpoint]"
    curl --request GET "$Endpoint" --header 'Content-Type:application/json' > statusreport.txt

         # | grep "HTTP/1.1" | cut -d" " -f2)  => to get http status code
    stopflag=$(cat statusreport.txt | grep -E -o '"stopflag":([a-z]{4,5})' | cut -d: -f2)
    statusCheck=$(cat statusreport.txt | grep -E -o '"match":([a-z]+){4,5}' | cut -d: -f2)

    echo "[REPORTER] Status Submitted, result [Match:$statusCheck, StopFlag:$stopflag]"

    ((_number=number+1))

    if [ "$stopflag" = true ] || [ "$statusfromfile" == "STOPPING" ] || [ "$statusfromfile" == "STOPPED" ]; then

        Endpoint="$API_URL/agentservice/$AgentId"
        curl --request GET "$Endpoint" --header 'Content-Type:application/json' > statusreport.txt > onStart.txt
        echo "[REPORTER] Agent-Service is stopping. Reporter will exit"
        break
    fi;

    if [ "$flagToExit" = true ]; then
      echo "[REPORTER] Agent-Service is flagged to exit"
      break;
    fi
  done
  echo "[REPORTER] - COMPLETE"
  echo " ===== >>> REPORTER STOPPED <<<<===== "
}

updateAgentStatus(){
  echo "Trying to change Agent-Service status to [$1]"
  if [ $agent_status != "$1" ]; then    
    echo "[AGENT STATUS UPDATE] Updating Agent-Status [NewStatus: $1, Current Status:$agent_status]"
    agent_status=$1
    curl --request PUT "$API_URL/agentservice/statusUpdate/$AgentId/$1" \
         --header 'Content-Type: application/json' > onStart.txt
  else
    echo "New Agent Status [$1] is same as before [$agent_status]. Skipping Status Update"
  fi
}

executor(){
  while [ $number -le 10 ]; do
    echo "[EXECUTOR] - running [$number]"
    sleep 3
    ((number=number+1))
    if [ $number -eq 3 ]; then
      echo "[EXECUTOR] MOCKING ## Test received"
      updateAgentStatus "BUSY"
      sleep 15
      updateAgentStatus "AVAILABLE"
    fi

    statusfromfile=$(cat $statusfile)
    if [ $statusfromfile == "STOPPING" ] || [ $statusfromfile == "STOPPED" ]; then
        echo "[EXECUTOR] Agent-Service is stopping. Executer will exit"
        break
    fi;

  done
  echo "[EXECUTOR]  - COMPLETE"
}

getAgentProperty(){
  echo "Extracting [$1] property from onStart.txt file"
  property=$(cat onStart.txt | grep -E -o "\"$1\":([^\\\",]+)" | cut -d: -f2 | sed -e 's/"//g')
  return "$property"
}

getstatusFromFile(){
  statusfromfile=$(cat onStart.txt | grep -E -o '"status":"(\S+)"' | cut -d: -f2 | cut -d, -f1 | sed -e 's/"//g')
  echo "Agent-Status From File:$statusfromfile"
  return "$statusfromfile"
}

onStop(){
  echo "[OnStop] Executing 'onstop' tasks.."
  
  Endpoint="$API_URL/agentservice/onAgentStop/$AgentId/STOPPED"
  echo "$Endpoint"
  curl --request PUT "$Endpoint" \
       --header 'Content-Type: application/json' \
       > onStart.txt

  :>onStart.txt
  :>agentstatus.txt
  :>statusreport.txt

  echo "[OnStop] Completed executing 'onstop' tasks.."
}

onContainerStop(){

  flagToExit=true

  echo "[onContainerStop] Executing 'onstop' tasks.."
  Endpoint="$API_URL/agentservice/onAgentStop/$AgentId/STOPPING"
  echo "$Endpoint"
  curl --request PUT "$Endpoint" \
       --header 'Content-Type: application/json' \
       > onStart.txt

  sleep 2

  Endpoint="$API_URL/agentservice/onAgentStop/$AgentId/STOPPED"
  echo "$Endpoint"
  curl --request PUT "$Endpoint" \
       --header 'Content-Type: application/json' \
       > onStart.txt

  :>onStart.txt
  :>agentstatus.txt
  :>statusreport.txt

  echo "[onContainerStop] Completed executing 'onstop' tasks.."
}

host=$hostname
ipaddr=$(hostname --ip-address)
if [ "$host" == "" ]; then
    echo "Hostname not found..."
    host=$HOSTNAME    
fi

if [ "$ipaddr" == "" ]; then
    echo "IpAddress not found..."    
    ipaddr="127.0.0.1"
fi

if [ "$1" == "" ]; then
  echo "API Endpoint is required"
  exit 0;
fi

API_URL=$1
echo "Hostname:$host"
echo "API Base URL: $API_URL"

sleep 5

echo " ===== >>> STARTING AGENT-SERVICE <<<<===== "

#region OnStart
echo "[OnStart] Executing 'onstart' tasks.."

:>onStart.txt
:>agentstatus.txt
:>statusreport.txt

onStartPackage="{\"AgentName\":\"$host\", \"IpAddress\":\"${ipaddr}\", \"Version\":\"$version\"}"

echo "$onStartPackage"
Endpoint="$API_URL/agentservice/onAgentStart"
echo "$Endpoint"
curl --request POST "$Endpoint" \
     --header 'Content-Type: application/json' \
     --data-raw "$onStartPackage" > onStart.txt

echo "[OnStart] Completed executing 'onstart' tasks.."

#endregion

AgentId=$(cat onStart.txt | grep -E -o "\"id\":([^\\\",]+)" | cut -d: -f2 | sed -e 's/"//g')

if [ "$AgentId" != "0" ] && [ "$AgentId" != "" ]; then
   echo "Agent-Service registered with AgentId:$AgentId"
   sleep 2
   agent_status=$(cat onStart.txt | grep -E -o "status\":\"(\w+)\"" | cut -d: -f2 | sed 's/"//g')
   updateAgentStatus "AVAILABLE"
   sleep 2

else
  echo "[ERROR] Failed to register Agent-Service at startup"
  ls -ltr
  cat onStart.txt

  exit 1;
fi

#updateAgentStatus "BUSY"
#sleep 2
#updateAgentStatus "AVAILABLE"
#sleep 10
#onStop

trap "onContainerStop" SIGTERM SIGINT

if [ "$AgentId" != "0" ] && [ "$AgentId" != "" ]; then
  reporter &
  sleep 2
  #executor &

  number=1
  while [ $number -lt 2 ]; do      
      statusfromfile=$(cat onStart.txt | grep -E -o '"status":"(\S+)"' | cut -d: -f2 | cut -d, -f1 | sed -e 's/"//g')
      echo "MASTER [Status:$statusfromfile] [$number]"
      sleep 5
  #    ((number=number+1))
  #    if [ $number -ge 15 ]; then
  #        break;
  #    fi;
    stopflag=$(cat statusreport.txt | grep -E -o '"stopflag":([a-z]{4,5})' | cut -d: -f2)
    if [ "$stopflag" = true ] || [ "$statusfromfile" == "STOPPING" ] || [ "$statusfromfile" == "STOPPED" ]; then
          echo "[MASTER] Agent-Service will stop [StatusFromFile:$statusfromfile, stopFlag:$stopflag]"
          agent_status=$statusfromfile
          flagToExit=$true
          # cat onStart.txt
          # cat statusreport.txt
          sleep 10
          break
      fi;
  done


  # updateAgentStatus "STOPPED"

  # :>onStart.txt
  # :>agentstatus.txt
  # :>statusreport.txt

  onStop

  echo " ===== >>> ENDING AGENT-SERVICE <<<<===== "
  exit 0;
else
  echo "Agent not registered"
  cat onStart.txt
fi;

