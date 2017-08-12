#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (c) 2017 by Delphix. All rights reserved.
#
# Program Name : link_sqlserver.ps1
# Description  : Delphix PowerShell API Link dSource Example  
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl command line libraries
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Change values below as required
#
# Usage: ./link_sqlserver.ps1 
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#
# Required for Database Link and Sync ...
#
$DELPHIX_NAME="delphix_demo"        # Delphix dSource Name
$DELPHIX_GRP="Windows Source"       # Delphix Group Name

$SOURCE_ENV="Windows Target"        # Source Enviroment Name
$SOURCE_INSTANCE="MSSQLSERVER"      # Source Database Oracle Home or SQL Server Instance  Name
$SOURCE_SID="delphix_demo"          # Source Environment Database SID
$SOURCE_DB_USER="sa"                # Source Database user account
$SOURCE_DB_PASS="delphix"           # Source Database user password

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Local Functions ...

. .\delphixFunctions.ps1

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#########################################################
## Authentication ...

write-output "Authenticating on ${BaseURL} ... ${nl}"

$results=RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" 
#write-output "${nl} Results are ${results} ..."

$o = ConvertFrom-Json20 $results
$status=$o.status                       #echo "Status ... $status ${nl}"
if ("${status}" -ne "OK") {
   echo "Job Failed with ${status} Status ${nl} $results ${nl}"
   exit 1
}

echo "Login Successful ..."

#########################################################
## Get Group Reference ...

#write-output "${nl}Calling Group API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}")
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
## Get sourceconfig ...

#write-output "${nl}Calling sourceconfig API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/sourceconfig -b "${COOKIE}" -H "${CONTENT_TYPE}")
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
## Get Environment reference ...

#write-output "${nl}Calling environment API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}")
#write-output "environment API Results: ${results}"

$o = ConvertFrom-Json20 $results
$a = $o.result
$b = $a | where { $_.name -eq "${SOURCE_ENV}" } | Select-Object
#$b
$ENV_REFERENCE=$b.reference
echo "env reference: ${ENV_REFERENCE}"

#ENV_REFERENCE=$( parseResults "${STATUS}" "${SOURCE_ENV}" "name" "reference" )

#########################################################
## Get Repository reference ...

#write-output "${nl}Calling repository API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/repository -b "${COOKIE}" -H "${CONTENT_TYPE}")
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

#########################################################
## Provision a SQL Server Database ...

$json = @"
{
    \"type\": \"LinkParameters\",
    \"group\": \"${GROUP_REFERENCE}\",
    \"linkData\": {
        \"type\": \"MSSqlLinkData\",
        \"config\": \"${SOURCE_CFG}\",
        \"dbCredentials\": {
            \"type\": \"PasswordCredential\",
            \"password\": \"${SOURCE_DB_PASS}\"
        },
        \"dbUser\": \"${SOURCE_DB_USER}\",
        \"pptRepository\": \"${REP_REFERENCE}\"
    },
    \"name\": \"${DELPHIX_NAME}\"
}
"@


# linkData Options
#       , "validatedSyncMode": "NONE"

#
# Output File using UTF8 encoding ...
#
write-output $json | Out-File "provision_sqlserver.json" -encoding utf8

#write-output "${nl}Calling database provision API ...${nl}"
$results = (curl.exe --insecure -sX POST -k ${BaseURL}/database/link -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
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
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}")
#write-output "job API Results: ${results}"

$o = ConvertFrom-Json20 "${results}"		#$o
$a = $o.result					#$a

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
  $results = (curl.exe --insecure -sX GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}")
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
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}")
#write-output "job API Results: ${results}"

$o = ConvertFrom-Json20 "${results}"		#$o
$a = $o.result					#$a

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
  $results = (curl.exe --insecure -sX GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}")
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
