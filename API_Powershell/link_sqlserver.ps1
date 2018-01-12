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
# Version      : v1.2
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Usage: . .\link_sqlserver.ps1 
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#
# Database Ingestion ...
#
$DELPHIX_NAME="delphixdb"           # Delphix dSource Name
$DELPHIX_GRP="Windows_Source"       # Delphix Group Name

$SOURCE_ENV="Windows Host"          # Source Enviroment Name
$SOURCE_INSTANCE="MSSQLSERVER"      # Source Database Oracle Home or SQL Server Instance  Name
$SOURCE_SID="delphixdb"             # Source Environment Database SID
$SOURCE_DB_USER="delphixdb"         # Source Database user account
$SOURCE_DB_PASS="delphixdb"         # Source Database user password

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
$b = $a | where { $_.name -eq "${DELPHIX_GRP}" } | Select-Object
$GROUP_REFERENCE=$b.reference
Write-Output "group reference: ${GROUP_REFERENCE}"

#########################################################
## Get sourceconfig ...

#Write-Output "${nl}Calling sourceconfig API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/sourceconfig -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "sourceconfig API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.name -eq "${SOURCE_SID}" } | Select-Object
$SOURCE_CFG=$b.reference
Write-Output "sourceconfig reference: ${SOURCE_CFG}"

#########################################################
## Get Environment reference ...

#Write-Output "${nl}Calling environment API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "environment API Results: ${results}"

$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.name -eq "${SOURCE_ENV}" } | Select-Object
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
$b = $a | where { $_.name -eq "${SOURCE_INSTANCE}" -and $_.environment -eq "${ENV_REFERENCE}"} | Select-Object
$REP_REFERENCE=$b.reference
Write-Output "repository reference: ${REP_REFERENCE}"

#########################################################
## Provision a SQL Server Database ...

# v190
$json = @"
{
    \"name\": \"${DELPHIX_NAME}\",
    \"group\": \"${GROUP_REFERENCE}\",
    \"description\": \"\",
    \"linkData\": {
        \"type\": \"MSSqlLinkData\",
        \"config\": \"${SOURCE_CFG}\",
        \"encryptionKey\": \"\",
        \"syncParameters\": {
          \"type\": \"MSSqlExistingMostRecentBackupSyncParameters\"
        },
        \"validatedSyncMode\": \"TRANSACTION_LOG\", 
        \"dbCredentials\": {
            \"type\": \"PasswordCredential\",
            \"password\": \"${SOURCE_DB_PASS}\"
        },
        \"dbUser\": \"${SOURCE_DB_USER}\",
        \"delphixManagedStatus\": \"NOT_DELPHIX_MANAGED\",
        \"sourceHostUser\": \"HOST_USER-4\",
        \"sharedBackupLocation\": \"\\\\172.16.160.134\\temp\",
        \"sourcingPolicy\":{\"logsyncEnabled\": true, \"type\": \"SourcingPolicy\"},
        \"pptRepository\": \"${REP_REFERENCE}\",
        \"pptHostUser\": \"HOST_USER-4\"
    }
    , \"type\": \"LinkParameters\"

}
"@

# Note: The Snapsync does not work with local domain account (.\) due to a pre-requisite check, 
# but you can manually take a snapshot after and it works!!! ????

#
# Delphix most recent full or ... w/Translog 
# 
$json=@"
{
    \"group\": \"${GROUP_REFERENCE}\"
   , \"type\": \"LinkParameters\"
   ,\"linkData\": {
       \"type\": \"MSSqlLinkData\"
      ,\"config\": \"${SOURCE_CFG}\"
      ,\"dbCredentials\": {
          \"type\": \"PasswordCredential\"
         ,\"password\": \"${SOURCE_DB_PASS}\"
      }
      ,\"dbUser\": \"${SOURCE_DB_USER}\"
      ,\"pptRepository\": \"${REP_REFERENCE}\"
      ,\"sharedBackupLocation\": \"\\\\172.16.160.134\\temp\"
"@

#
# Version Specific ...
# 
##      ,\"validatedSyncMode\": \"FULL\"
# be sure to change the respective sync policy 
# FULL             =>  "loadFromBackup": true
# TRANSACTION_LOG  =>  "logsyncEnabled": true

if (${apival} -gt 180) {

$json=@"
${json}
      ,\"validatedSyncMode\": \"TRANSACTION_LOG\"
"@

}

$json=@"
${json}
      ,\"sourcingPolicy\":{
          \"logsyncEnabled\": true
          ,\"type\": \"SourcingPolicy\"
          ,\"loadFromBackup\":false
      }
   }
   ,\"name\": \"${DELPHIX_NAME}\"
   ,\"description\": \"\"
}
"@

Write-Output "JSON> $json"

#
# linkData Options
#       , "validatedSyncMode": "NONE"

#
# Output File using UTF8 encoding ...
#
Write-Output $json | Out-File "provision_sqlserver.json" -encoding utf8

#Write-Output "${nl}Calling database provision API ...${nl}"
$results = (curl.exe --insecure -sX POST -k ${BaseURL}/database/link -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
$status = ParseStatus "${results}" "${ignore}"
Write-Output "database provision API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$JOB=$o.job
Write-Output "Job # $JOB"

# 
# Allow job to submit internally before while loop ...
#
sleep 1

Monitor_JOB "$BaseURL" "$COOKIE" "$CONTENT_TYPE" "$JOB"

#########################################################
## SQLSERVER link automatically submits a "sync" snapshot  
## job, so increment previous JOB # by 1 and monitor ...

$n=$JOB -replace("[^\d]")
$n1=([int]$n)+1
$JOB = $JOB -replace "${n}", "${n1}"
Write-Output "JOB $JOB ${nl}"

Monitor_JOB "$BaseURL" "$COOKIE" "$CONTENT_TYPE" "$JOB"

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0
