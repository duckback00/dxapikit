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
# Required for Provisioning Virtual Database ...
#
$SOURCE_SID="delphixdb"           # dSource name used to get db container reference value

$VDB_NAME="VBITT"                 # Delphix VDB Name
$TARGET_GRP="Windows_Target"      # Delphix Engine Group Name
$TARGET_ENV="Window Target"       # Target Environment used to get repository reference value 
$TARGET_REP="MSSQLSERVER"         # Target Environment Repository / Instance name

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
$b = $a | where { $_.name -eq "${TARGET_GRP}" } | Select-Object
$GROUP_REFERENCE=$b.reference
echo "group reference: ${GROUP_REFERENCE}"


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

#CONTAINER_REFERENCE=$( parseResults "${STATUS}" "${SOURCE_SID}" "name" "reference" )

#########################################################
## Get Environment reference  

#write-output "${nl}Calling environment API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX GET -H "${CONTEXT_TYPE}" -k ${BaseURL}/environment)
#write-output "environment API Results: ${results}"

$o = ConvertFrom-Json20 $results
$a = $o.result
$b = $a | where { $_.name -eq "${TARGET_ENV}" } | Select-Object
#$b
$ENV_REFERENCE=$b.reference
echo "env reference: ${ENV_REFERENCE}"

#ENV_REFERENCE=$( parseResults "${STATUS}" "${TARGET_ENV}" "name" "reference" )

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
$b = $a | where { $_.name -eq "${TARGET_REP}" } | Select-Object
#$b
$REP_REFERENCE=$b.reference
echo "repository reference: ${REP_REFERENCE}"


#########################################################
## Provision a SQL Server Database ...

$json = @"
{
    "type": "MSSqlProvisionParameters",
    "container": {
        "type": "MSSqlDatabaseContainer",
        "name": "${VDB_NAME}",
        "group": "${GROUP_REFERENCE}",
        "sourcingPolicy": {
            "type": "SourcingPolicy",
            "loadFromBackup": false,
            "logsyncEnabled": false
        },
        "validatedSyncMode": "TRANSACTION_LOG"
    },
    "source": {
        "type": "MSSqlVirtualSource",
        "operations": {
            "type": "VirtualSourceOperations",
            "configureClone": [],
            "postRefresh": [],
            "postRollback": [],
            "postSnapshot": [],
            "preRefresh": [],
            "preSnapshot": []
        }
    },
    "sourceConfig": {
        "type": "MSSqlSIConfig",
        "linkingEnabled": false,
        "repository": "${REP_REFERENCE}",
        "databaseName": "${VDB_NAME}",
        "recoveryModel": "SIMPLE",
        "instance": {
            "type": "MSSqlInstanceConfig",
            "host": "${ENV_REFERENCE}"
        }
    },
    "timeflowPointParameters": {
        "type": "TimeflowPointSemantic",
        "container": "${CONTAINER_REFERENCE}",
        "location": "LATEST_SNAPSHOT"
    }
}
"@

#
# Output File using UTF8 encoding ...
#
write-output $json | Out-File "provision_sqlserver.json" -encoding utf8

#write-output "${nl}Calling database provision API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX POST -H "Content-Type: application/json" -d "@provision_sqlserver.json" -k ${BaseURL}/database/provision)
write-output "database provision API Results: ${results}"

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
