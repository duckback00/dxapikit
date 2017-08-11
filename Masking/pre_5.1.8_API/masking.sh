#!/bin/bash
#v1.1
#2015-09-14 - Adam Bowen - Created
#2015-09-30 - Hims       - Last edited
#########################################################
#                   DELPHIX CORP                        #
#########################################################

#########################################################
#Parameter Initialization

DMIP=172.16.160.195
DMPORT=8282
DMUSER=Axistech
DMPASS="ENC(LRFCy6TouiWKGkE0VL5WJlc41biWuGCf)"
APPLICATION="demo_app"        # Add quotes for names with spaces ...
JOBID=0
DELAYTIMESEC=30

# Added to encode APPLICATION variable special characters, such as spaces
APPLICATION=$(sed -e 's/ /%20/g' -e 's/!/%21/g' -e 's/"/%22/g' -e 's/#/%23/g' -e 's/\&/%26/g' -e 's/'\''/%28/g' -e 's/(/%28/g' -e 's/)/%29/g' -e 's/{/%7B/g' -e 's/}/%7D/g' -e 's/:/%3A/g' -e 's/\//%2F/g'<<<$APPLICATION);

#########################################################
##   Login authetication and autokoen capture
BaseURL="http://${DMIP}:${DMPORT}/dmsuite/apiV4"
echo "Authenticating on ${BaseURL}"
myLoginToken=$(curl -sIX GET "${BaseURL}/login?user=${DMUSER}&password=${DMPASS}" | grep auth_token | cut -f2 -d':' | tr -d ' ')
echo "Authentication Successful"

#########################################################
##   Firing job

echo "Executing job ${JOBID}"
curl -sX POST -H "auth_token:${myLoginToken}" -H "Content-Type:application/xml" -d "<MaskingsRequest></MaskingsRequest>" ${BaseURL}/applications/${APPLICATION}/maskingjobs/${JOBID}/run > /dev/null


#########################################################
##  Getting Job status

echo "*** waiting for status *****"
STATUS=`curl -X GET -sH "auth_token:${myLoginToken}" -H "Content-Type:application/xml" ${BaseURL}/applications/${APPLICATION}/maskingjobs/${JOBID}/results | sed -n 's:.*<Status>\(.*\)</Status>.*:\1:p' `

echo "*** waiting for status *****" ${STATUS}

#########################################################
## waiting while checking job status

while [ ${STATUS} == "RUNNING" ]; do
        echo "Current status as of" $(date) " : "  ${STATUS}
        sleep ${DELAYTIMESEC}
        STATUS=`curl -X GET -sH "auth_token:${myLoginToken}" -H "Content-Type:application/xml" ${BaseURL}/applications/${APPLICATION}/maskingjobs/${JOBID}/results | sed -n 's:.*<Status>\(.*\)</Status>.*:\1:p' `
done

echo  ${STATUS}

#########################################################
##  Producing final status

if [ "${STATUS}" != "SUCCESS" ]; then
        echo "Masking job(s) Failed"
        exit 1
fi
############## E O F ####################################


