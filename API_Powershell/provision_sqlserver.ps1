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
# Program Name : provision_sqlserver.ps1
# Description  : Delphix PowerShell API provision VDB Example  
# Author       : Alan Bitterman
# Created      : 2017-11-15
# Version      : v1.1
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Usage: . .\provision_sqlserver.ps1 
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#
# Required for Provisioning Virtual Database ...
#
$SOURCE_SID="delphixdb"           # dSource name used to get db container reference value

$VDB_NAME="Vdelphixdb"            # Delphix VDB Name
$TARGET_GRP="Windows_Target"      # Delphix Engine Group Name
$TARGET_ENV="Windows Host"        # Target Environment used to get repository reference value 
$TARGET_REP="MSSQLSERVER"         # Target Environment Repository / Instance name

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Local Functions ...

. .\delphixFunctions.ps1

#########################################################
## Authentication ...

Write-Output "Authenticating on ${BaseURL} ... ${nl}"
$results=RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" 
#Write-Output "${nl} Results are ${results} ..."
Write-Output "Login Successful ..."

#########################################################
## API Version ...

$apival=Get_APIVAL "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" 
Write-Output "API Version: ${apival} "

#########################################################
## Get Group Reference ...

#Write-Output "${nl}Calling Group API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Group API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.name -eq "${TARGET_GRP}" } | Select-Object
$GROUP_REFERENCE=$b.reference
Write-Output "group reference: ${GROUP_REFERENCE}"

#########################################################
## Get database container ...

#Write-Output "${nl}Calling Database API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Database API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.name -eq "${SOURCE_SID}" -and $_.type -eq "MSSqlDatabaseContainer"} | Select-Object
$CONTAINER_REFERENCE=$b.reference
Write-Output "container reference: ${CONTAINER_REFERENCE}"

#########################################################
## Get Environment reference ...

#Write-Output "${nl}Calling environment API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "environment API Results: ${results}"

$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.name -eq "${TARGET_ENV}" } | Select-Object
$ENV_REFERENCE=$b.reference
Write-Output "env reference: ${ENV_REFERENCE}"

#########################################################
## Get Repository reference ...

#Write-Output "${nl}Calling repository API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/repository -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "repository API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.name -eq "${TARGET_REP}" -and $_.environment -eq "${ENV_REFERENCE}"} | Select-Object
$REP_REFERENCE=$b.reference
Write-Output "repository reference: ${REP_REFERENCE}"

#########################################################
## Provision a SQL Server Database ...

$json = @"
{
    \"type\": \"MSSqlProvisionParameters\",
    \"container\": {
        \"type\": \"MSSqlDatabaseContainer\",
        \"name\": \"${VDB_NAME}\",
        \"group\": \"${GROUP_REFERENCE}\",
        \"sourcingPolicy\": {
            \"type\": \"SourcingPolicy\",
            \"loadFromBackup\": false,
            \"logsyncEnabled\": false
        },
        \"validatedSyncMode\": \"TRANSACTION_LOG\"
    },
    \"source\": {
        \"type\": \"MSSqlVirtualSource\", 
"@

#
# Auto Restart Option starting with API Version 1.8.x ...
#
if ( $apival -gt 180 ) {

$json = @"
${json}
        \"allowAutoVDBRestartOnHostReboot\": false, 
"@

}

#
# Continue to build JSON string ...
#
$json1 = @"
${json}
        \"operations\": {
            \"type\": \"VirtualSourceOperations\",
            \"configureClone\": [],
            \"postRefresh\": [],
            \"postRollback\": [],
            \"postSnapshot\": [],
            \"preRefresh\": [],
            \"preSnapshot\": []
        }
    },
    \"sourceConfig\": {
        \"type\": \"MSSqlSIConfig\",
        \"linkingEnabled\": false,
        \"repository\": \"${REP_REFERENCE}\",
        \"databaseName\": \"${VDB_NAME}\",
        \"recoveryModel\": \"SIMPLE\",
        \"instance\": {
            \"type\": \"MSSqlInstanceConfig\",
            \"host\": \"${ENV_REFERENCE}\"
        }
    },
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSemantic\",
        \"container\": \"${CONTAINER_REFERENCE}\",
        \"location\": \"LATEST_SNAPSHOT\"
    }
}
"@


Write-Output "JSON: $json1"

#
# NOTE: the above JSON does change with the upcomming Delphix J release API Version 1.9.0? 
#

#Write-Output "${nl}Calling database provision API ...${nl}"
$results = (curl.exe --insecure -sX POST -k ${BaseURL}/database/provision -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json1}")
$status = ParseStatus "${results}" "${ignore}"
Write-Output "database provision API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$JOB=$o.job
Write-Output "Job # ${JOB}"

# 
# Allow job to submit internally before while loop ...
#
sleep 1

Monitor_JOB "$BaseURL" "$COOKIE" "$CONTENT_TYPE" "$JOB"

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0
