#!/bin/bash
#

START=$1
END=$2

#######################################################################
#
# Loop for each Database connector ...
#

# Debug/Verify ...
#echo $DMURL > log.${START}.${END}.${DT}
#echo "${CONN}" | jq ".[] | select (.connNo >= ${START} and .connNo <= ${END}) " >> log.${START}.${END}.${DT}

#echo "${CONN}" | jq --raw-output "."
#DBCONNS=`echo "${CONN}" | jq --raw-output ".[] | .schemaName "`

let j=0
for ((j=$START;j<=$END;j++))
do
   echo "==============================================="
   #echo "$j ... $START ... $END ... ${CONNNAME}${j}"
   #echo "${CONN}" | jq --raw-output ".[$j]" 

   CONN0=`echo "${CONN}" | jq --raw-output ".[] | select (.connNo == ${j})"`
   #echo "$CONN0" | jq -r "."

   #echo "$CONN0" | jq -r "." >> log.${START}.${END}.${DT}

   #######################################################################
   #
   # Login for each DB Connection ...
   # See comments at top of this script for timeout configurations
   #
   STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \"username\": \"${DMUSER}\", \"password\": \"${DMPASS}\" }" "${DMURL}/login"`
   #echo ${STATUS} | jq "."
   KEY=`echo "${STATUS}" | jq --raw-output '.Authorization'`
   #echo "Authentication Key: ${KEY}"

   #######################################################################
   #
   # Process Provided Connectors ...
   # 
   CNAME="${CONNNAME}${j}"
 
   USR=`echo "${CONN0}" | jq --raw-output ".username"`
   PWD=`echo "${CONN0}" | jq --raw-output ".password"`
   DBT=`echo "${CONN0}" | jq --raw-output ".databaseType"` 

   ZTMP=`echo "${CONN0}" | jq --raw-output ".host | select (.!=null)"`
   if [[ "${ZTMP}" != "" ]] 
   then
      HOST=`echo "${CONN0}" | jq --raw-output ".host"`
   else
      HOST=""
   fi
   #echo "HOST: |${HOST}|"   

   PORT=`echo "${CONN0}" | jq --raw-output ".port"`
   SCHEMA=`echo "${CONN0}" | jq --raw-output ".schemaName"`

   SID=`echo "${CONN0}" | jq --raw-output ".sid"`

   JDBC=`echo "${CONN0}" | jq --raw-output ".jdbc"`

   DBNAME=`echo "${CONN0}" | jq --raw-output ".databaseName"`
   INSTANCE=`echo "${CONN0}" | jq --raw-output ".instanceName"`

   #
   # Check for Provided Profile Set Name within Connection ...
   #
   PSTMP=`echo "${CONN0}" | jq --raw-output ".profileSetName | select (.!=null)"`
   if [[ "${PSTMP}" != "" ]]
   then 
      PSNAME="${PSTMP}"
   fi

   CONN_STR=""				# For Reporting Purposes ONLY ...

   # 
   # Supported Databases ...
   #
   if [[ "${DBT}" == "ORACLE" ]] 
   then 
      #######################################################################
      #
      # Create Oracle Connector ...
      # 
      STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"connectorName\": \"${CNAME}\", \"databaseType\": \"${DBT}\", \"environmentId\": ${ENVID}, \"host\": \"${HOST}\", \"password\": \"${PWD}\", \"port\": ${PORT}, \"sid\": \"${SID}\", \"username\": \"${USR}\", \"schemaName\" : \"${SCHEMA}\" }" "${DMURL}/database-connectors"`
      #echo ${STATUS} | jq "."
      DBID=`echo "${STATUS}" | jq --raw-output '.databaseConnectorId'`
      echo "Connector Id: ${DBID}"
      CONN_STR="${DBT} ${HOST}:${PORT}:${SID}"
   elif [[ "${DBT}" == "MSSQL" ]] && [[ "${HOST}" == "" ]] 
   then
      #######################################################################
      #
      # MSSQL Advance Connector ...
      #
      #echo "JSON: { \"connectorName\": \"${CNAME}\", \"databaseType\": \"${DBT}\", \"environmentId\": ${ENVID}, \"jdbc\": \"${JDBC}\", \"password\": \"${PWD}\", \"username\": \"${USR}\", \"schemaName\" : \"${SCHEMA}\" }"

      STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"connectorName\": \"${CNAME}\", \"databaseType\": \"${DBT}\", \"environmentId\": ${ENVID}, \"jdbc\": \"${JDBC}\", \"password\": \"${PWD}\", \"username\": \"${USR}\", \"schemaName\" : \"${SCHEMA}\" }" "${DMURL}/database-connectors"`

      #echo ${STATUS} | jq "."
      #echo "${STATUS}"
      DBID=`echo "${STATUS}" | jq --raw-output '.databaseConnectorId'`
      echo "Connector Id: ${DBID}"
      CONN_STR="Advance: ${DBT} ${JDBC} ...  Database: ${DBNAME} ... Instance: ${INSTANCE} "

   elif [[ "${DBT}" == "MSSQL" ]]
   then
      #######################################################################
      #
      # MSSQL Connector ...
      #
      STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"connectorName\": \"${CNAME}\", \"databaseType\": \"${DBT}\", \"environmentId\": ${ENVID}, \"host\": \"${HOST}\", \"password\": \"${PWD}\", \"port\": ${PORT}, \"databaseName\": \"${DBNAME}\",\"instanceName\": \"${INSTANCE}\", \"username\": \"${USR}\", \"schemaName\" : \"${SCHEMA}\" }" "${DMURL}/database-connectors"`
      #echo ${STATUS} | jq "."
      DBID=`echo "${STATUS}" | jq --raw-output '.databaseConnectorId'`
      echo "Connector Id: ${DBID}"
      CONN_STR="${DBT} ${HOST}:${PORT}:${DBNAME} ... Instance: ${INSTANCE} "
   else
      #
      # Not Supported Yet ...
      #
      echo "Error: Database ${DBT} Not Yet supported in this script ..."
   fi 
   #echo "DEBUG: ${CONN_STR} "

   #######################################################################
   # 
   # Test Connector ...
   #
   STATUS=`curl -s -X POST --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-connectors/${DBID}/test"`
   CONN_RESULTS=`echo "${STATUS}" | jq --raw-output ".response"`
   if [[ "${CONN_RESULTS}" != "Connection Succeeded" ]]
   then 
      echo "Error: Connection ${CNAME} not valid for ${DBID} ... ${CONN_RESULTS}"
      echo "Please verify parameters and try again."

      #
      # Append Message to Report JSON file ...
      #
      echo "{ \"job\": ${j}, \"Run\": \"<tr><td>${j}</td>\", \"JobName\": \"<td>${CONN_STR} ... Schema: ${SCHEMA} ... Profile Set: ${PSNAME}</td>\", \"Results\": \"<td>Error: Connection ${CNAME} not valid ... ${CONN_RESULTS}</td></tr>\" }," >> ${REPORT}.json

   else

      # 
      # Have a valid database connect, let's proceed ...
      #
      echo "${USR} ${CONN_RESULTS}"

      #######################################################################
      #
      # Get list of tables from connector ...
      #
      STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-connectors/${DBID}/fetch"`
      #echo ${STATUS} | jq "."
      TABLES=`echo "${STATUS}" | jq --raw-output ".[]"`
      #echo "Tables: ${TABLES}"

      # 
      # Proceed iff schema contains or username has privileges to see  tables ...
      #
      if [[ "${TABLES}" != "" ]] 
      then

         #######################################################################
         #
         # Define Rule Set ...
         #
         STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"rulesetName\": \"${RSNAME}${j}\", \"databaseConnectorId\": ${DBID} }" "${DMURL}/database-rulesets"`
         #echo ${STATUS} | jq "."
         RSID=`echo "${STATUS}" | jq --raw-output ".databaseRulesetId"`
         echo "Rule Set Id: ${RSID}"

         #
         # Loop thru Tables and add to Rule Set ...
         #
         let k=0
         while read tbname
         do
            let k=k+1
            #echo "$k ... $tbname "
            STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"tableName\": \"${tbname}\", \"rulesetId\": ${RSID} }" "${DMURL}/table-metadata"`
            #echo ${STATUS} | jq "."
         done <<< "${TABLES}"

         #######################################################################
         #
         # Get list of Profile Sets ...
         #
         STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/profile-sets"`
         #echo ${STATUS} | jq "."
         #echo "${STATUS}" | jq --raw-output ".responseList[] | .profileSetName + \",\" + (.profileSetId|tostring) "
         PSID=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.profileSetName == \"${PSNAME}\") | (.profileSetId|tostring)"`
         echo "Profile Set: ${PSNAME} ... ${PSID} "

         #######################################################################
         # 
         # Profile Job ...
         # Create Profile Job ...
         # 
         PROFILENAME="profile_job"${j}
         STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"jobName\": \"${PROFILENAME}\", \"profileSetId\": ${PSID}, \"rulesetId\": ${RSID}, \"jobDescription\": \"This is an example ...\" }" "${DMURL}/profile-jobs"`
         #echo ${STATUS} | jq "."
   
         JOBID=`echo "${STATUS}" | jq --raw-output ".profileJobId"`
         echo "Job Id: ${JOBID}"

         #######################################################################
         #
         # Execute Job ...
         #
         STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"jobId\": ${JOBID} }" "${DMURL}/executions"`
         #echo ${STATUS} | jq "."
         EXID=`echo "${STATUS}" | jq --raw-output ".executionId"`
         echo "Execution Id: ${EXID}"
   
         JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`

         sleep 1

         while [[ "${JOBSTATUS}" == "RUNNING" ]]
         do
            # sleep ${DELAYTIMESEC}     # for long running jobs ..
            STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/executions/${EXID}"`
            #echo ${STATUS} | jq "."
            JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`
            #echo "${JOBSTATUS}"
         done

         if [[ "${JOBSTATUS}" != "SUCCEEDED" ]] 
         then
            echo "Job Error: $JOBSTATUS ... $STATUS"
         else
            echo "Profile Job Completed: $JOBSTATUS"
         fi

         #######################################################################
         #
         # Get Inventory ...
         #
         STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/table-metadata?ruleset_id=${RSID}"`
         #echo ${STATUS} | jq "."
   
         TABLEINFO=`echo "${STATUS}" | jq --raw-output '.responseList[] | .tableName + "," + (.tableMetadataId|tostring)'`
         ##echo "Table Info: ${TABLEINFO}"

      else

         echo "No Tables in this Schema ..."
         TABLEINFO=""

      fi      #  end if $TABLES == ""

      #######################################################################
      #
      # Write Out JSON Results Data ...
      #
      let k=0
      echo "{ " > ${JSON_OUT}${j}
      echo "  \"schema\": \"${SCHEMA}\" " >> ${JSON_OUT}${j}
      echo ", \"host\": \"${HOST}\" " >> ${JSON_OUT}${j}
      echo ", \"port\": \"${PORT}\" " >> ${JSON_OUT}${j}
      echo ", \"sid\": \"${SID}\" " >> ${JSON_OUT}${j}
      echo ", \"databaseName\": \"${DBNAME}\" " >> ${JSON_OUT}${j}
      echo ", \"instanceName\": \"${INSTANCE}\" " >> ${JSON_OUT}${j}
      echo ", \"jdbc\": \"${JDBC}\" " >> ${JSON_OUT}${j}
      echo ", \"databaseType\": \"${DBT}\" " >> ${JSON_OUT}${j}
      echo ", \"profileSet\": \"${PSNAME}\" " >> ${JSON_OUT}${j}
      echo ", \"tables\": [" >> ${JSON_OUT}${j}
      if [[ "${TABLEINFO}" != "" ]]
      then
         DELIM=""
         while read tbinfo
         do
            let k=k+1
            #echo "$k ... $tbinfo"
            IFS=,
            arr=($tbinfo)
            #echo "---------------------------------------- "  
            #echo "Writing Results for Table: ${arr[0]}    id: ${arr[1]}"
            ID="${arr[1]}"
            #echo "Id: |${ID}|"
            STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/column-metadata?table_metadata_id=${ID}"`
            #echo "${STATUS}" | jq "."
   
            if [[ "${DELIM}" != "" ]] 
            then 
               echo "${DELIM}" >> ${JSON_OUT}${j}
            fi
            echo " {" >> ${JSON_OUT}${j}
            echo "  \"tableName\": \"${arr[0]}\"" >> ${JSON_OUT}${j}
            echo "  , \"tableId\": \"${arr[1]}\"" >> ${JSON_OUT}${j}
            echo "  , \"results\": " >> ${JSON_OUT}${j}
            echo "${STATUS}" | jq "." >> ${JSON_OUT}${j}
            echo " }" >> ${JSON_OUT}${j}
            DELIM=","
         done <<< "${TABLEINFO}"

      else 
         JOBID=""
      fi

      echo "]" >> ${JSON_OUT}${j}
      echo ", \"rows\": $k " >> ${JSON_OUT}${j}
      echo "}" >> ${JSON_OUT}${j}

      #######################################################################
      #
      # Build Individual HTML Report Pages ...
      #
      source report.sh "${RPT_DIR}${RPT}${j}" "${j}"

      #######################################################################
      #
      # Clean Up ...
      #
      if [[ "${JOBID}" != "" ]] 
      then
         echo " "    # must have one statement in if condition ...
         # 
         # Profile Job ...
         #
         #STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/profile-jobs/${JOBID}"`
         #echo ${STATUS} | jq "."
         #
         # Rule Set ...
         #
         ##STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-rulesets/${RSID}"`
         #echo ${STATUS} | jq "."
         # 
         # Connector ...
         #
         ##STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-connectors/${DBID}"`
         #echo ${STATUS} | jq "."
         # 
         # Optional: Environment ...
         #
         ##STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/environments/${ENVID}"`
         ##echo ${STATUS} | jq "."
         #
         # NOTE: No API to Delete an Application ...
         #
      fi     # end if $JOBID ...

      #
      # End of Database Scan Loop
      #
      #DBT=`echo "${CONN}" | jq --raw-output ".[$j].databaseType"`
      #USR

      #
      # Append Results to Report JSON file ...
      #
      echo "{ \"job\": ${j}, \"Run\": \"<tr><td>${j}</td>\", \"JobName\": \"<td>${CONN_STR} ... Schema: ${SCHEMA} ... Profile Set: ${PSNAME}</td>\", \"Results\": \"<td><a href=${RPT}${j}.html target=_blank>Report</a></td></tr>\" }," >> ${REPORT}.json

   fi     # end of CONN_RESULTS ...

done <<< "${DBCONNS}"

#
# No exit, since we want to return to the calling shell ...
#
