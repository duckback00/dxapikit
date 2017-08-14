#!/bin/bash 
#v1.1
#2016-05-03 - DBW       - Last edited for wget version
#########################################################
#                   DELPHIX CORP                        #
#########################################################

#########################################################
#Parameter Initialization

DMIP=172.16.160.195
DMPORT=8282
DMUSER=Axistech
DMPASS="ENC(LRFCy6TouiWKGkE0VL5WJlc41biWuGCf)"
APPLICATION=test_app       ## Do not forget to change
DELAYTIMESEC=15
STATUS=""
JOBID=1

echo #########################################################
##   Login authentication and auth_tokoen capture
BaseURL="http://${DMIP}:${DMPORT}/dmsuite/apiV4"
echo "Authenticating on ${BaseURL}"
myLoginToken=$(wget -SO- -T 1 -t 1 "${BaseURL}/login?user=${DMUSER}&password=${DMPASS}" 2>&1 | grep auth_token | cut -f2 -d':' | tr -d ' ')
echo "Authentication Successful"
echo "LoginToken" $myLoginToken

#########################################################
##   Firing jobs

echo "Executing job ${JOBID}"
STATUS1=`wget -SO- -T 1 -t 1 --header="auth_token:${myLoginToken}" --header="Content-Type:application/xml" --post-data="<MaskingsRequest></MaskingsRequest>" ${BaseURL}/applications/${APPLICATION}/maskingjobs/${JOBID}/run 2>&1 | sed -n 's:.*<Status>\(.*\)</Status>.*:\1:p'`
echo $STATUS1

#########################################################
##  Getting Job status
echo "*** waiting for status *****"
sleep ${DELAYTIMESEC}
echo "LoginToken" $myLoginToken
        STATUS1=`wget -SO- -T 1 -t 1 --header="auth_token:${myLoginToken}" --header="Content-Type:application/xml"  ${BaseURL}/applications/${APPLICATION}/maskingjobs/${JOBID}/results 2>&1 | sed -n 's:.*<Status>\(.*\)</Status>.*:\1:p'`

echo "***  pinging for status >>>> " ${STATUS1}

#########################################################
## waiting while checking job status

while [[ ${STATUS1} == "RUNNING" ]]; do
   echo "Current status as of" $(date) " : "  ${STATUS1}
   sleep ${DELAYTIMESEC}
   STATUS1=`wget -SO- -T 1 -t 1 --header="auth_token:${myLoginToken}" --header="Content-Type:application/xml"  ${BaseURL}/applications/${APPLICATION}/maskingjobs/${JOBID}/results 2>&1 | sed -n 's:.*<Status>\(.*\)</Status>.*:\1:p'`
done

#echo  ${STATUS1}

# "Check return status for the masking job"
 
echo "${STATUS1}" 
if [ "${STATUS1}" != "SUCCESS"  ]; then
        echo "Masking job $JOBID did not complete successfully"
        exit 1
fi

echo "Finished" 
date

##################### END OF FILE ############################################
exit 0;

