#!/bin/bash
#######################################################################
# Filename: masking_authentication.sh
# Version: v1.0
# Date: 2017-09-15 
# Last Updated: 2017-11-15 Bitt...
# Author: Alan Bitterman 
# 
# Description: 
#
# Usage: 
# ./masking_authentication.sh
# 
#######################################################################
## User Configured Parameters ...

DMURL="http://172.16.160.195:8282/masking/api"
# For version 5.3.3 or later ...
# DMURL="http://172.16.160.195/masking/api"
DMUSER="Axistech"
DMPASS="Axis_123"

#######################################################################
# No changes below this line is required ...
#######################################################################

#######################################################################
## Login ...

echo "Authenticating using ${DMURL}/login ..."
STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \"username\": \"${DMUSER}\", \"password\": \"${DMPASS}\" }" "${DMURL}/login"`
#echo ${STATUS} | jq "."
KEY=`echo "${STATUS}" | jq --raw-output '.Authorization'`
echo "Authentication Key: ${KEY}"

#######################################################################
## Get Environment List ...

echo "Get Masking Environment List ..."
STATUS=`curl -s -X GET --header 'Accept: application/json' --header "Authorization: ${KEY}" "${DMURL}/environments"`
echo "Results: "
echo "${STATUS}" | jq "."

#######################################################################
## The End ...

echo "Done ..."
exit 0;

