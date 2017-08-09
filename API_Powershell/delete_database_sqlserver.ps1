# Filename: provision_sqlserver.ps1
# Description: Delphix Powershell Sample Authentication Script ...
# Date: 2016-08-02
# Author: Bitt...
#

#########################################################
#                   DELPHIX CORP                        #
#########################################################

#########################################################
# Parameter Initialization

##
## Defaults ... Get from Command Line or use the default identified ...
##
param (
    [string]$SOURCE_SID = "delphixdb"
)
$SOURCE_SID = [uri]::EscapeDataString($SOURCE_SID)

#
# Required for Deleting and dSource or Virtual Database ...
#
###HARD CODE###$SOURCE_SID="delphixdb"       # dSource name used to get db container reference value 

write-output "Deleting dSource or Virtual Database ${SOURCE_SID} ..."

#
# Variables ...
#
$nl = [Environment]::NewLine
$BaseURL = "http://172.16.160.195/resources/json/delphix"
$cookie = "cookies.txt"
$delphix_user = "delphix_admin"
$delphix_pass = "delphix"

$CONTENT_TYPE="Content-Type: application/json"
$DELAYTIMESEC=10

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#
# Local Functions ...
#
. .\parseFunctions.ps1

#########################################################
#
# Authentication ...
#
write-output "Authenticating on ${BaseURL}"

# 
# Session JSON Data ...
#
#write-output "Creating session.json file ..."
$json = @"
{
    "type": "APISession",
    "version": {
        "type": "APIVersion",
        "major": 1,
        "minor": 7,
        "micro": 0
    }
}
"@

#
# Output File using UTF8 encoding ...
#
write-output $json | Out-File "session.json" -encoding utf8

#
# Delphix Curl Session API ...
#
#write-output "Calling Session API ... "
$results = (curl --insecure -c "${cookie}" -sX POST -H "${CONTENT_TYPE}" -d "@session.json" -k ${BaseURL}/session)
#write-output "Session API Results: ${results}"

# Convert Results String to JSON Object and Get Results Status ...
$o = ConvertFrom-Json20 $results
$status=$o.status			#echo "Status ... $status ${nl}"
if ("${status}" -ne "OK") {
   echo "Job Failed with ${status} Status ${nl} $results ${nl}"
   exit 1
}

#
# Login JSON Data ...
# 
#write-output "Creating login.json file ..."
$json = @"
{
    "type": "LoginRequest",
    "username": "${delphix_user}",
    "password": "${delphix_pass}"
}
"@

#
# Output File using UTF8 encoding ...
#
write-output $json | Out-File "login.json" -encoding utf8

#
# Delphix Curl Login API ...
#
#write-output "Calling Login API ..."
$results = (curl --insecure -b "${cookie}" -sX POST -H "${CONTENT_TYPE}" -d "@login.json" -k ${BaseURL}/login)
#write-output "Login API Results: ${results}"

# Convert Results String to JSON Object and Get Results Status ...
$o = ConvertFrom-Json20 $results
$status=$o.status			#echo "Status ... $status ${nl}"
if ("${status}" -ne "OK") {
   echo "Job Failed with ${status} Status ${nl} $results ${nl}"
   exit 1
}
echo "Login Successful ..."


#########################################################
## Get database container

#write-output "${nl}Calling Database API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX GET -H "${CONTEXT_TYPE}" -k ${BaseURL}/database)
#write-output "Database API Results: ${results}"

# Convert Results String to JSON Object and Get Results Status ...
$o = ConvertFrom-Json20 $results
$status=$o.status			#echo "Status ... $status ${nl}"
if ("${status}" -ne "OK") {
   echo "Job Failed with ${status} Status ${nl} $results ${nl}"
   exit 1
}

# Parse Results ...
$a = $o.result
#$a
$b = $a | where { $_.name -eq "${SOURCE_SID}" -and $_.type -eq "MSSqlDatabaseContainer"} | Select-Object
$CONTAINER_REFERENCE=$b.reference
echo "container reference: ${CONTAINER_REFERENCE}"


#########################################################
## Provision a SQL Server Database ...

$json = @"
{
    "type": "DeleteParameters"
}
"@

#
# Output File using UTF8 encoding ...
#
write-output $json | Out-File "delete_database_sqlserver.json" -encoding utf8

#write-output "${nl}Calling database delete API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX POST -H "Content-Type: application/json" -d "@delete_database_sqlserver.json" -k ${BaseURL}/database/${CONTAINER_REFERENCE}/delete)
write-output "database delete API Results: ${results}"

# Convert Results String to JSON Object and Get Results Status ...
$o = ConvertFrom-Json20 $results
$status=$o.status			#echo "Status ... $status ${nl}"
if ("${status}" -ne "OK") {
   echo "Job Failed with ${status} Status ${nl} $results ${nl}"
   exit 1
}

#
# Parse Results ...
# Get Container and Job Number ...
#
$CONTAINER=$o.result
echo "DB Container: ${CONTAINER} ${nl}"
$JOB=$o.job
echo "Job # $JOB ${nl}"

# 
# Allow job to submit internally before while loop ...
#
sleep 2

# 
# Job Information ...
#
#write-output "${nl}Calling job API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX GET -H "${CONTEXT_TYPE}" -k ${BaseURL}/job/${JOB})
#write-output "job API Results: ${results}"

$o = ConvertFrom-Json20 "${results}"		#$o
$a = $o.result								#$a

#
# Get Job Status and Job Information ...
#
$JOBSTATE=$a.jobState
$PERCENTCOMPLETE=$a.percentComplete

echo "jobState  $JOBSTATE"
echo "percentComplete $PERCENTCOMPLETE"

echo "***** waiting for status *****"
##$JOBSTATE="RUNNING"
$rows = 0
DO
{
  $d = Get-Date
  echo "Current status as of ${d} : ${JOBSTATE} : ${PERCENTCOMPLETE}% Completed"
  sleep ${DELAYTIMESEC}
  $results = (curl --insecure -b "${cookie}" -sX GET -H "${CONTEXT_TYPE}" -k ${BaseURL}/job/${JOB})
  $o = ConvertFrom-Json20 "${results}"
  $a = $o.result
  $JOBSTATE=$a.jobState
  $PERCENTCOMPLETE=$a.percentComplete
} While ($JOBSTATE -contains "RUNNING")

#########################################################
##
##  Producing final status
##
if ("${JOBSTATE}" -eq "COMPLETED") {
   echo "Job ${JOBSTATE} Succesfully. ${nl}"
} else {
   echo "Job Failed with ${JOBSTATE} Status ${nl}"
}


############## E O F ####################################
echo " "
echo "Done ..."
echo " "
exit 0
