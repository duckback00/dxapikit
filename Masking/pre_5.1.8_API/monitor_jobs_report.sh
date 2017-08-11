#!/bin/bash

BaseURL="http://172.16.160.195:8282/dmsuite"
DMUSER=Axistech
DMPASS=Axis_123
#APPLICATION="test_app"
JOBID=1

curl --cookie-jar cjar --output /dev/null ${BaseURL}/login.do

curl --cookie cjar --cookie-jar cjar --data "userName=${DMUSER}" --data "password=${DMPASS}" --output /dev/null ${BaseURL}/login.do

data=$(curl --cookie cjar ${BaseURL}/monitorJobsDBCompleted.do?jobNm=${JOBID} | grep "{ID")

##echo "data> $data" 

echo "data> "
echo -e "$data" | sed -e 's/[{}]/''/g' | sed 's/,/\'$'\n/g'
echo " "
echo "Just grab key values ..."
echo -e "$data" | sed -e 's/[{}]/''/g' | sed 's/,/\'$'\n/g' | grep -E 'Status :|Time|RowsPerMin|RowsMasked'
echo " "

