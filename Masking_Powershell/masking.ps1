# Filename: masking.ps1
# v1.0
# 2018-06-24 - Alan Bitterman - Powershell Conversion
#
# Requirements: 
# 1.) Delphix Masking Engine version 5.2.x or later
# 2.) cURL command line executable, curl.exe
# 3.) Powershell version 3.x or later
# 
# 
# Usage from Powershell:
# . .\masking.ps1
# . .\masking.ps1 -JOBID 677
#

#########################################################
##                   DELPHIX CORP                      ##
##     PLEASE MAKE PARAMETER VALUE CHANGES BELOW       ##
#########################################################

#########################################################
## Default JobId to Submit ...

param (
    [int]$JOBID = 677           
)

#########################################################
## Delphix Masking Parameter Initialization ...

$DMIP="172.16.160.195"                            # DM Hostname or IP
$DMPORT=8282                                      # DM Port
$DMUSER="Axistech"                                # 
$DMPASS="Axis_123"                                #       
$DMURL="http://${DMIP}:${DMPORT}/masking/api"     # http or https
$CONTENT_TYPE="Content-Type: application/json"    
$DELAYTIMESEC=15                                  # check status interval

#########################################################
##       NO CHANGES BELOW THIS POINT REQUIRED          ##
#########################################################

$d = Get-Date
echo "$d  Start Time ..."

#########################################################
## Login Authetication ...

echo "Authenticating on ${DMURL}"

$json = @"
{
    \"username\": \"${DMUSER}\",
    \"password\": \"${DMPASS}\"
}
"@

## echo "JSON: ${json}"

$results = (curl.exe -H "${CONTENT_TYPE}" -sX POST "$DMURL/login" -d "${json}")   
##DEBUG##echo $results
$o = ConvertFrom-Json $results
$KEY=$o.Authorization
#echo "Token: $KEY"
if (!$KEY) {
   echo "Invalid Token: $results"
   echo "Exiting ..."
   exit 1;
} else {
   echo "Authentication Successfull Token: ${KEY} "
}

#########################################################
## Submit Job ...

$json=@"
{
 \"jobId\": \"${JOBID}\"
}
"@ 

echo "Running Masking JobId ${JOBID} ..."
$results=(curl.exe -H "Authorization:${KEY}" -H "${CONTENT_TYPE}" -sX POST "${DMURL}/executions" -d "${json}")
#echo $results
#{"executionId":896,"jobId":677,"status":"RUNNING","startTime":"2018-06-26T01:08:42.206+0000"}
$o = ConvertFrom-Json $results
$execId = $o.executionId
$status = $o.status
echo "Job Execution Id: $execId"
echo "Job Submit Status: $status"

if ("${status}" -ne "RUNNING") {
   echo "Masking job ${JOBID} failed with ""${status}"" Status"
   echo "${results}"
   echo "Exiting ..."
   exit 1
}

#########################################################
## Getting Job Status ...

echo "*** waiting for status every ${DELAYTIMESEC} (secs) ***"
$rows = 0
$total = 0
DO
{
   sleep ${DELAYTIMESEC}
   $d = Get-Date
   $results=(curl.exe -H "Authorization:${KEY}" -H "${CONTENT_TYPE}" -sX GET "${DMURL}/executions/${execId}")
   #echo $results
   #{"executionId":896,"jobId":677,"status":"RUNNING","startTime":"2018-06-26T01:08:42.206+0000"}
   $o = ConvertFrom-Json $results
   $status = $o.status
   echo "$d $status"
} While ($status -contains "RUNNING")

#########################################################
## Final Status ...

if ("${status}" -eq "SUCCEEDED") {
   #echo $results
   #{"executionId":901,"jobId":677,"status":"SUCCEEDED","rowsMasked":3,"rowsTotal":3,"startTime":"2018-06-26T01:31:58.644+0000","endTime":"2018-06-26T01:32:29.268+0000"}
   $startTime = $o.startTime
   $endTime = $o.endTime
   $rows = $o.rowsMasked
   $total = $o.rowsTotal
   echo "${status}. Rows Masked: ${rows}  of  Rows Total: ${total}"
   #echo "Masking Start Time: ${startTime}"
   #echo "Masking End Time: ${endTime}"
} else {
   echo "Masking job(s) Failed with ${status} Status"
}

############## E O F ####################################
## Done ...

$d = Get-Date
echo "$d  Finished Time ..."
echo "Done ..."
exit