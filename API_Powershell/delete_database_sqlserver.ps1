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
# Program Name : delete_database_sqlserver.ps1
# Description  : Delphix PowerShell API Delete SQLServer Database 
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl command line libraries
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Change values below as required
#
# Usage: ./delete_database_sqlserver.ps1 [dSource_or_VDB_name]
#
#########################################################
#                   DELPHIX CORP                        #
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
# Parameter Initialization

##
## Defaults ... Get from Command Line or use the default identified ...
##
param (
    [string]$SOURCE_SID = ""
)
$SOURCE_SID = [uri]::EscapeDataString($SOURCE_SID)

if ("${SOURCE_SID}" -eq "") {
   echo "Error, missing dSource or VDB Name ${SOURCE_SID}, Exiting ... ${nl}"
   exit 1
}

write-output "Deleting dSource or VDB Name ${SOURCE_SID} ..."

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
## Get database container ...

#write-output "${nl}Calling Database API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}")
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
    \"type\": \"DeleteParameters\"
}
"@


#write-output "${nl}Calling database delete API ...${nl}"
$results = (curl.exe --insecure -sX POST -k ${BaseURL}/database/${CONTAINER_REFERENCE}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
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
