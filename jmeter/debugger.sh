#!/bin/bash

echo "[INFO] Starting test"
source .env && JMX=Demo_Plan.jmx docker-compose -f docker-compose-custom.yml -p jmeter up --scale jmeter-slave=${nbInjector}
echo "[INFO] Test Completed"
echo "[INFO] Shutting down container(s)"
docker-compose -p jmeter down
echo "[INFO] ****** COMPLETED *******"
echo ""
