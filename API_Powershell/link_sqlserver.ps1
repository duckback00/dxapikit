# Filename: link_sqlserver.ps1
# Description: Delphix Powershell Sample Authentication Script ...
# Date: 2016-08-02
# Author: Bitt...
#

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

#
# Required for Database Link and Sync ...
#
$DELPHIX_NAME="delphixdb"           # Delphix dSource Name
$DELPHIX_GRP="Windows_Source"       # Delphix Group Name

$SOURCE_ENV="Window Target"         # Source Enviroment Name
$SOURCE_INSTANCE="MSSQLSERVER"      # Source Database Oracle Home or SQL Server Instance  Name
$SOURCE_SID="delphixdb"             # Source Environment Database SID
$SOURCE_DB_USER="sa"                # Source Database user account
$SOURCE_DB_PASS="delphix"           # Source Database user password

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
## Get or Create Group

#write-output "${nl}Calling Group API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX GET -H "${CONTEXT_TYPE}" -k ${BaseURL}/group)
#write-output "Group API Results: ${results}"

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
$b = $a | where { $_.name -eq "${DELPHIX_GRP}" } | Select-Object
$GROUP_REFERENCE=$b.reference
echo "group reference: ${GROUP_REFERENCE}"

#########################################################
## Get sourceconfig

#write-output "${nl}Calling sourceconfig API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX GET -H "${CONTEXT_TYPE}" -k ${BaseURL}/sourceconfig)
#write-output "sourceconfig API Results: ${results}"

# Convert Results String to JSON Object and Get Results Status ...
$o = ConvertFrom-Json20 $results
$status=$o.status			#echo "Status ... $status ${nl}"
if ("${status}" -ne "OK") {
   echo "Job Failed with ${status} Status ${nl} $results ${nl}"
   exit 1
}

# Parse Results ...
$a = $o.result
$b = $a | where { $_.name -eq "${SOURCE_SID}" } | Select-Object
#$b
$SOURCE_CFG=$b.reference
echo "sourceconfig reference: ${SOURCE_CFG}"

#########################################################
## Get Environment reference

#write-output "${nl}Calling environment API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX GET -H "${CONTEXT_TYPE}" -k ${BaseURL}/environment)
#write-output "environment API Results: ${results}"

$o = ConvertFrom-Json20 $results
$a = $o.result
$b = $a | where { $_.name -eq "${SOURCE_ENV}" } | Select-Object
#$b
$ENV_REFERENCE=$b.reference
echo "env reference: ${ENV_REFERENCE}"

#########################################################
## Get Repository reference

#write-output "${nl}Calling repository API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX GET -H "${CONTEXT_TYPE}" -k ${BaseURL}/repository)
#write-output "repository API Results: ${results}"

# Convert Results String to JSON Object and Get Results Status ...
$o = ConvertFrom-Json20 $results
$status=$o.status			#echo "Status ... $status ${nl}"
if ("${status}" -ne "OK") {
   echo "Job Failed with ${status} Status ${nl} $results ${nl}"
   exit 1
}

# Parse Results ...
$a = $o.result
$b = $a | where { $_.name -eq "${SOURCE_INSTANCE}" } | Select-Object
#$b
$REP_REFERENCE=$b.reference
echo "repository reference: ${REP_REFERENCE}"

#
# Parse ...
#
#REP_REFERENCE=$( parseResults "${STATUS}" "${ENV_REFERENCE}" "environment" "reference" )
#echo "repository reference: ${REP_REFERENCE}"

#########################################################
## Link Source Database ...

$json = @"
{
    "type": "LinkParameters",
    "group": "${GROUP_REFERENCE}",
    "linkData": {
        "type": "MSSqlLinkData",
        "config": "${SOURCE_CFG}",
        "dbCredentials": {
            "type": "PasswordCredential",
            "password": "${SOURCE_DB_PASS}"
        },
        "dbUser": "${SOURCE_DB_USER}",
        "pptRepository": "${REP_REFERENCE}"
    },
    "name": "${DELPHIX_NAME}"
}
"@

# linkData Options
#       , "validatedSyncMode": "NONE"

write-output $json | Out-File "link_sqlserver.json" -encoding utf8

#write-output "${nl}Calling database link API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX POST -H "Content-Type: application/json" -d "@link_sqlserver.json" -k ${BaseURL}/database/link)
write-output "database link API Results: ${results}"

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
# Fast Job, allow to finish before while loop ...
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


#########################################################
#
# SQLSERVER link automatically submits a "sync" snapshot job, so increment previous JOB # by 1 and monitor ...
#
$n=$JOB -replace("[^\d]")
$n1=([int]$n)+1
$JOB = $JOB -replace "${n}", "${n1}"
echo "JOB $JOB ${nl}"

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


#
# The End is Near ...
#
echo "${nl}Done ...${nl}"
exit;
