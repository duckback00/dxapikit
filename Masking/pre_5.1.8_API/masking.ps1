# Filename: masking.ps1
# v1.3
# 2015-09-14 - Adam Bowen - Created
# 2015-09-30 - Hims       - Last edited
# 2016-07-24 - Alan Bitterman - Powershell Conversion
#
# Usage from Powershell:
# . .\masking.ps1
# . .\masking.ps1 -APPLICATION "test_app" -JOBID 42

#########################################################
##                   DELPHIX CORP                      ##
#########################################################

##
## Defaults ... Use existing Application Name and identified Job Id ...
##
param (
    [string]$APPLICATION = "test_app",
    [int]$JOBID = 43
)
$APPLICATION = [uri]::EscapeDataString($APPLICATION)

$d = Get-Date
echo "$d  Start Time ..."

#########################################################
## Delphix Masking Parameter Initialization
##

$DMIP="172.16.160.162"
$DMPORT=8282
$DMUSER="Axistech"
$DMPASS="ENC(LRFCy6TouiWKGkE0VL5WJlc41biWuGCf)"
$DELAYTIMESEC=15

#########################################################
##                   DELPHIX CORP                      ##
#########################################################

echo "Running Masking JobID ${JOBID} for Application ${APPLICATION} ..."

#########################################################
##
##   Login authetication and autokoen capture
##

$BaseURL="http://${DMIP}:${DMPORT}/dmsuite/apiV4"
echo "Authenticating on ${BaseURL}"
$results = (curl.exe -sIX GET "${BaseURL}/login?user=${DMUSER}&password=${DMPASS}" | grep auth_token)
##DEBUG##echo $results
$arr = @($results.split(': '))
##DEBUG##echo $arr
$myLoginToken=$arr[2]
echo "Authentication Successful"

#########################################################
##
##   Firing job
##

echo "Executing job ${JOBID}"
$results=(curl.exe -sX POST -H "auth_token:${myLoginToken}" -H "Content-Type:application/xml" -d "<MaskingsRequest></MaskingsRequest>" "${BaseURL}/applications/${APPLICATION}/maskingjobs/${JOBID}/run" )
$doc=[xml]$results
$j = $doc.MaskingsResponse.ResponseStatus.Status
echo "Job Submit Status: $j"

#########################################################
##
##  Getting Job status
##

$STATUS=(curl.exe -X GET -sH "auth_token:${myLoginToken}" -H "Content-Type:application/xml" "${BaseURL}/applications/${APPLICATION}/maskingjobs/${JOBID}/results")
##echo $STATUS
$doc=[xml]$STATUS
$p = $doc.MaskingsResponse.Maskings.Masking.PreviousDuration
echo "Previous Duration Time: $p"
echo "***** waiting for status *****"

$state="RUNNING"
$rows = 0
DO
{
  sleep ${DELAYTIMESEC}
  $d = Get-Date
  echo "$d  fetching status ..."
  $STATUS=(curl.exe -X GET -sH "auth_token:${myLoginToken}" -H "Content-Type:application/xml" "${BaseURL}/applications/${APPLICATION}/maskingjobs/${JOBID}/results")
  ##echo $STATUS
  $doc=[xml]$STATUS
  echo $doc.MaskingsResponse.Maskings.Masking.Status
  $state = $doc.MaskingsResponse.Maskings.Masking.Status
  $rows = $doc.MaskingsResponse.Maskings.Masking.RowsProcessed
} While ($state -contains "RUNNING")

#########################################################
##
##  Producing final status
##

if ("${state}" -eq "SUCCESS") {
   echo "Done. Rows Processed: $rows"
} else {
   echo "Masking job(s) Failed with ${state} Status"
}

############## E O F ####################################
##
## Done ...
##
$d = Get-Date
echo "$d  Finished Time ..."

echo " "
