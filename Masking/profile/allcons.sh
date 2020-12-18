#!/bin/bash
#
#    Filename: allcons.sh
#      Author: Alan Bitterman
# Description: This script reads database users/schemas 
#              and builds database connections JSON string
# 
# Note: Requires command line path/access to sqlplus command ...
#

#######################################################################
## Updating Path to local sqlplus executable client ...

OS=`uname -s`
if [[ "${OS}" == "Darwin" ]]
then
   PATH=$PATH:${HOME}/instantclient_12_1	# Change for your local sqlplus client path ...
fi

#######################################################################
## Source connection information (from calling script) ...

#echo "Using $CONN"
#echo "${CONN}" | jq "."

DBCONNS=`echo "${CONN}" | jq --raw-output ".[] | .schemaName "`

#######################################################################
## Build JSON database connection string ...

JSON="["
DELIM=""

#######################################################################
## Loop through provided connections ...
 
let j=0
let i=0
while read dbname
do

   #
   # Parse out values ...
   #
   USR=`echo "${CONN}" | jq --raw-output ".[$j].username"`
   PWD=`echo "${CONN}" | jq --raw-output ".[$j].password"`
   DBT=`echo "${CONN}" | jq --raw-output ".[$j].databaseType"`
   HOST=`echo "${CONN}" | jq --raw-output ".[$j].host"`
   PORT=`echo "${CONN}" | jq --raw-output ".[$j].port"`
   SCHEMA=`echo "${CONN}" | jq --raw-output ".[$j].schemaName"`
   SID=`echo "${CONN}" | jq --raw-output ".[$j].sid"`
   JDBC=`echo "${CONN}" | jq --raw-output ".[$j].jdbc"`
   DBNAME=`echo "${CONN}" | jq --raw-output ".[$j].databaseName"`
   INSTANCE=`echo "${CONN}" | jq --raw-output ".[$j].instanceName"`

   #
   # Check for Provided Profile Set Name within Connection ...
   #
   PSTMP=`echo "${CONN}" | jq --raw-output ".[$j].profileSetName | select (.!=null)"`
   if [[ "${PSTMP}" != "" ]]
   then
      PSNAME="${PSTMP}"
   fi

   #
   # Fetch Oracle SCHEMAs ..
   #
   if [[ "${DBT}" != "ORACLE" ]]
   then
      echo "No code written yet for ${DBT}, please ask and we'll be happy to write this code for you. Exiting ..."
      exit 1;
   fi

   #
   # Exclude Oracle User Accounts (or others) ...
   #
   WHERE="where username not in ('ANONYMOUS','APEX_030200','APEX_PUBLIC_USER','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDDATA','MDSYS','MGMT_VIEW','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS','OWBSYS_AUDIT','SI_INFORMTN_SCHEMA','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','SYS','SYSMAN','SYSTEM','WMSYS','XDB','XS\$NULL')"

   # 
   # SQL Command to Get List of User Accounts/Schemas ...
   #
   RESULTS=`sqlplus -s ${USR}/${PWD}@"(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=${HOST})(PORT=${PORT}))(CONNECT_DATA=(SERVICE_NAME=${SID})))" <<EOF
set head off
set trim off
set long 1000000
set wrap off
set feedback off
set linesize 40
select username||','||account_status||',' as list from dba_users ${WHERE} and account_status='OPEN' order by 1;
exit;
EOF
`

   echo "ALL Schemas for ${HOST}:${PORT}:${SID} ... ${RESULTS}"

   #
   # Convert CSV results into JSON Array containing Database Connection Objects ...
   #
   OLD_IFS="$IFS"
   while IFS='' read -r line || [[ -n "$line" ]]; do
   if [[ "${line}" != "" ]]
   then
      #echo "$i:  $line"
      #echo "data"
      IFS=,
      arr=($line)
      # 
      # Only process accounts with "OPEN" status ...
      # 
      if [[ "${arr[1]}" == "OPEN" ]]
      then
         let i=i+1
         # 
         # Build JSON Data String ...
         #
         JSON="${JSON}${DELIM}
{
  \"username\": \"${USR}\",
  \"password\": \"${PWD}\",
  \"databaseType\": \"${DBT}\",
  \"host\": \"${HOST}\",
  \"port\": ${PORT},
  \"profileSetName\": \"${PSNAME}\",
  \"schemaName\": \"${arr[0]}\",
  \"connNo\": ${i},
  \"sid\": \"${SID}\"
}"
         DELIM=","
      fi      # end if OPEN 
   fi      # end if $line ""
   done <<< "${RESULTS}"
   IFS="${OLD_IFS}"


   let j=j+1             # Database Connection Counter ...
done <<< "${DBCONNS}"
JSON="${JSON}
]"

#######################################################################
## Verify ...

#echo "${JSON}" | jq "."
CONN="${JSON}"

#
# No exit, return to calling script ...
#
