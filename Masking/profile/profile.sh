#!/bin/bash
#######################################################################
# Filename: profile.sh
# Version: v1.6
# Date: 2017-09-15 
# Last Updated: 2018-04-12 Bitt...
# Author: Alan Bitterman 
# 
# Description: Demo script for profile multiple databases at a time
#              using the new Delphix Masking 5.2 APIs 
#
# Logic:
#  The script starts with defining a number of user defined variables.
#  You MUST changed the Delphix Masking Engine connection values to run
#  within your environment. You can change the report logo and masking
#  object names as desired.
#
#  If you are going to use hard-code database connections, you will need
#  to modify $CONN JSON structured connection data as required.
#  ... or ... you can modify the profile_connections.csv (or create your
#  own file) for database connections.
#  
#  This script uses a Masking environment, default "profile_env", which
#  if does not exist, the script will create. After this environment is
#  created or verified, the script will delete any existing Rule Sets 
#  and Connectors before starting the profiling of the database connections.
#
#  The script will then loop through each database connection definition 
#  and perform the respective API calls;
#   1.) Create a Database Connector 
#   2.) Test the Database Connector, if successful proceed
#   3.) Get a list of all the tables the Connector has access   
#   4.) Create a Rule Set
#   5.) Assign all the tables per the connector to the Rule Set
#   6.) Create a Profile Job
#   7.) Run the Profile Job
#   8.) Monitor the Profile Job until Completion
#   9.) Gets the Rule Set / Inventory data 
#   10.) Writes report Data
#  Loops back to next database connection
#
#
# Usage: 
# 1.) [ edit profile.sh and change Masking Engine connection parameters ]
# 2.) Either update the hard-coded connections or provide a comma delimited
#     list of database connections, must match provided format!
# 3.) Or use the connections provided with an account that has privileges
#     to see/select other schemas and use the ALL argument. 
#     ALL option is currently for Oracle connections ONLY.
#     This option requires sqlplus be installed and found in path.
#
# [shell_prompt$]  ./profile.sh
#
# [shell_prompt$]  ./profile.sh profile_connections.csv
#
# [shell_prompt$]  ./profile.sh ALL              # ALL requires sqlplus 
#
# [shell_prompt$]  ./profile.sh profile_connections.csv ALL  
# 
#######################################################################
# Rev | Date       | Who   | Change
#-----+------------+-------+-------------------------------------------
# 1.2 | 2017-09-24 | Bitt  | Added Notes and CSV import for connections 
# 1.3 | 2017-09-27 | Bitt  | Replaced .[] with API .responseList[]
# 1.4 | 2017-10-04 | Bitt  | Moved reports to html directory
# 1.5 | 2017-10-12 | Bitt  | Added code for ALL schema logic
# 1.6 | 2018-04-12 | Bitt  | Added parallel option and code 
#     |            |       |
#     |            |       |
#######################################################################
#
# DEBUG ...
#
#set -x 
start_time=`date +%s`
echo "Program: Delphix 5.2.x or later script to profile one or many environments - v1.6"

#
# User Configured Parameters ...
#
# Delphix Masking Engine ...
#
DMURL="http://172.16.160.195:8282/masking/api"
DMUSER="Axistech"
DMPASS="Axis_123"
DELAYTIMESEC=10					 # Job Monitoring Sleep Time(s) 
DT=`date '+%Y%m%d%H%M%S'`

# 
# Masking Variables ...
#
APP="profile_app" 			# Will use if exists, create if not exists
ENV="profile_env"			# Will use if exists, create if not exists 
                                        # NOTE: if exists, all connections and rule sets will be deleted!!!

CONNNAME="Conn"                         # Connector Basename
RSNAME="RuleSet"                        # Rule Set Basename

#
# Default Profile Set if not provided in the connection information ...
#
##PSNAME="Financial"
PSNAME="HIPAA"

# 
# Report Variables / Filenames ...
#
RPT_DIR=`pwd`"/html/"				# Absolute Path for HTML Output ...
JSON_OUT="${RPT_DIR}json.out"			# each db json results output file ...
RPT="profile_report"				# Report Name ...
REPORT="${RPT_DIR}report.html"			# Report HTML File ...
REPORT_TMP="${RPT_DIR}report.json"		# Report JSON Containing each Connection Results ...
if [[ -e "${REPORT}.json" ]]			# Delete previous Report JSON File ...
then
   rm "${REPORT}.json"
fi
REPORT_TITLE="<span style=\"font-size:32px;padding-top:20px;color:#1AD6F5;\">Delphix Profiler Security Scan Results</span>"

#
# Report Logo ...
#
LOGO="images/delphix-logo-black_300w.png"	# Delphix Logo ...
#LOGO="images/[your_logo_filename]\" height=\"125\""
### Delphix Demos ### . ./logos.sh

#
# Parallel Option ...
#
PARALLEL=0	# Number of Parallel Jobs, performance is dependent on CPU/Cores/RAM, 4 works nice ...

# 
# Hard Coded Database Connections (JSON) ...
# (or loaded via CSV file, see later code) 
#
# Note: if "ALL" argument was provided, this first hard-coded connection is used to query the
#       database for all "OPEN" database accounts / schemas to include in the profiling job.
#       Also, the account username and password provided must have the ability to read the
#       schema meta data, select any dictionary and select on any table privileges.
#       IMPORTANT: This option requires sqlplus installed and found within the path!!!
#
CONN="[
{
  \"username\": \"PROFILER\",
  \"password\": \"profiler00\",
  \"databaseType\": \"ORACLE\",
  \"host\": \"172.16.160.133\",
  \"port\": 1521,
  \"schemaName\": \"DELPHIXDB\",
  \"profileSetName\": \"Financial\",
  \"connNo\": 1,
  \"sid\": \"orcl\"
},
  {
  \"username\": \"DELPHIXDB\",
  \"password\": \"delphixdb\",
  \"databaseType\": \"ORACLE\",
  \"host\": \"172.16.160.133\",
  \"port\": 1521,
  \"schemaName\": \"DELPHIXDB\",
  \"profileSetName\": \"HIPAA\",
  \"connNo\": 2,
  \"sid\": \"orcl\"
}
]
"
#
# Add additional JSON database connection objects if desired ...
# remove previous 5 lines which include this line plus next line
XTMP="
, {
  \"username\": \"DELPHIXDB\",
  \"password\": \"delphixdb\",
  \"databaseType\": \"ORACLE\",
  \"host\": \"172.16.160.133\",
  \"port\": 1521,
  \"schemaName\": \"DELPHIXDB\",
  \"profileSetName\": \"HIPAA\",
  \"connNo\": 3,
  \"sid\": \"VBITT2\"
}
]
"

#######################################################################
# No changes below this line is required ...
#######################################################################

#
# ... OR ... load $CONN JSON Connection String from CSV File ...
#
# source procons.sh [connections.csv] 
# source procons.sh [connections.csv] ALL
#
if [[ "${1}" != "" ]]
then
   if [[ "${1}" == "ALL" ]]         # ./profile.sh ALL 
   then
      source allcons.sh             # Get all schema's using the provided hard coded account
   else
      source procons.sh "${1}"      # ./profile.sh profile_connections.csv
      if [[ "${2}" == "ALL" ]]      # ./profile.sh profile_connections.csv ALL
      then
         source allcons.sh          # Get all schema's using the provided hard coded account
      fi
   fi
fi
#DEBUG#echo "$CONN" | jq "." ; echo "----------"

# 
# Generate a list of Database/Schema Names to be used later by loop logic ...
#
DBCONNS=`echo "${CONN}" | jq --raw-output ".[] | .schemaName "`

#######################################################################
#
# Need to add error trapping for when JSON return API strings contain
# "errormessage" content ...
#
#######################################################################
#
# Login ...
#
STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \"username\": \"${DMUSER}\", \"password\": \"${DMPASS}\" }" "${DMURL}/login"`
#echo ${STATUS} | jq "."
KEY=`echo "${STATUS}" | jq --raw-output '.Authorization'`
echo "Authentication Key: ${KEY}"

#######################################################################
# 
# Get Application ...
#
STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/applications"`
#echo "${STATUS}"

#
# Create Application ...
#
APPNAME=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.applicationName == \"${APP}\") | .applicationName"`
if [[ "${APP}" != "${APPNAME}" ]]
then 
   STATUS=`curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: ${KEY}" -d "{ \"applicationName\": \"${APP}\" }" "${DMURL}/applications"`
   #echo "${STATUS}" | jq "."
fi
echo "Application Name: ${APP}"

#######################################################################
# 
# Get Environment ...
#
STATUS=`curl -s -X GET --header 'Accept: application/json' --header "Authorization: ${KEY}" "${DMURL}/environments"`
#echo "${STATUS}" | jq "."

#
# Create Environment ...
#
ENVID=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.application == \"${APP}\" and .environmentName == \"${ENV}\") | .environmentId"`
if [[ "${ENVID}" == "" ]]
then
   STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"environmentName\": \"${ENV}\", \"application\": \"${APP}\", \"purpose\": \"MASK\" }" "${DMURL}/environments"`
   #echo "${STATUS}" | jq "."
   ENVID=`echo "${STATUS}" | jq --raw-output ". | select (.application == \"${APP}\" and .environmentName == \"${ENV}\") | .environmentId"`
fi
echo "Environment Name: ${ENV}"
echo "Environment Id: ${ENVID}"

#######################################################################
#
# Get Environment Connectors ...
# 
STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-connectors"`
#echo ${STATUS} | jq "."
DELDB=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.environmentId == ${ENVID}) | .databaseConnectorId "`
#echo "Delete Conn Ids: ${DELDB}"

#
# Delete all existing connectors ...
#
if [[ "${DELDB}" != "" ]]
then
while read TMPID
do
   #echo "$j ... $TMPID "
   STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-connectors/${TMPID}"`
   #echo "${STATUS}" | jq "."
   echo "Removing previous connection id ${TMPID}"  
done <<< "${DELDB}"
fi

#######################################################################
# 
# Get Rule Set ...
# 
STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-rulesets"`
#echo "${STATUS}" | jq "."
DELRS=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.environmentId == ${ENVID}) | .databaseRulesetId"`
#echo "Delete Rule Set Ids: ${DELRS}"

#
# Delete all existing rule sets ...
#
if [[ "${DELRS}" != "" ]]
then
while read TMPID
do
   #echo ".. $TMPID "
   STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-rulesets/${TMPID}"`
   #echo "${STATUS}" | jq "."
   echo "Removing previous rule set id ${TMPID}"  
done <<< "${DELRS}"
fi

#
# Get Profile Jobs ...
#
#curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/profile-jobs?environment_id=3"

#
# Delete all existing profile jobs ...
# NOTE: Profile jobs automatically get deleted when Rulesets are deleted
#

#######################################################################
# 
# HTML Report Header Output ...
#

echo "<html><head><title>Delphix Rocks</title>" > ${REPORT} 
echo "<style> table { font-family: arial, sans-serif; border-collapse: collapse; width: 100%; } td, th { border: 1px solid #dddddd; text-align: left; padding: 8px; } tr:nth-child(even) { background-color: #dddddd; } </style>" >> ${REPORT}
echo "</head><body>" >> ${REPORT}
echo "<table border=0 style=\"border: 0px solid #ffffff;\"><tr><td style=\"border: 0px solid #ffffff;\" width=\"25%\">" >> ${REPORT}
echo "<img src=\"${LOGO}\" border=0 />" >> ${REPORT}
echo "</td><td style=\"border: 0px solid #ffffff;\">" >> ${REPORT}
echo "${REPORT_TITLE}" >> ${REPORT}
echo "</td></tr></table>" >> ${REPORT}
echo "Timestamp: ${DT} <br />" >> ${REPORT}
echo "<hr size=3 color=#1AD6F5 />" >> ${REPORT}
echo "<table border=0 cellspacing=1 cellpadding=1>" >> ${REPORT}
echo "<tr><th>Run</th><th>JobName</th><th>Results</th></tr>" >> ${REPORT}

#echo "${CONN}" | jq --raw-output "."
#DBCONNS=`echo "${CONN}" | jq --raw-output ".[] | .schemaName "`

#
# Parallel Jobs or Single Job ...
#
let ll=`echo "${CONN}" | jq '. | length'`      # Get Number of Connections ...
if [[ $PARALLEL -gt 1 ]] 
then
   # 
   # Parallel Jobs ...
   #
   echo "Running Parallel Jobs: $PARALLEL"
   echo "No Connections: $ll"
   if [[ $ll -le $PARALLEL ]]
   then
      echo "One Connection Per Job"
      let dd=1			# Connections Per Job ...
      let rr=0			# Remaining Connections ...
   else
      let dd=$ll/$PARALLEL	# Connections Per Job ...
      let tt=$dd*$PARALLEL	# Calculation required to identify remaining job ...
      let rr=$ll-$tt		# Remaining Connections ...
      echo "Connections Per Job: $dd remaining $rr"
   fi
   let ii=0			# While loop counter for number of connections ...
   let ff=1			# Initial connection number ...
   set -m 			# Enable Job Control ...
   while [ $ii -lt $ll ]; do    
      let ii=$ii+1              # Increment connection counter, start with 1 ...
      let gg=$ff+$dd-1		# Calculate number of connections per job ...
      if [[ $rr -gt 0 ]]        # If remaining, add 1 to this job ...
      then
         let gg=$gg+1
      fi
      if [[ $gg -gt $ll ]]	# If number of jobs per this connection is greater than number of connections ...
      then
         gg=$ll			# then set ending connection to last connection ....
      fi
      echo "$ii  + remaining $rr  [$ff:$gg]"

      # 
      # Parse Connections ...
      #
      let f0=$ff-1
      CTMP=`echo "${CONN}" | jq ".[${f0}:${gg}]"`
      
      # 
      # Send independent batch jobs for respective connection groupings ...
      #
      . ./batch.sh $ff $gg &

      # 
      # Update next job starting position and de-increment any remaining connections ...
      #
      let ff=$gg+1
      let rr=$rr-1
      if [[ $gg -ge $ll ]]
      then
         break
      fi
   done

   #
   # Wait for all parallel jobs to finish, then continue ...
   #
   while [ 1 ]; do fg 2> /dev/null; [ $? == 1 ] && break; done

else
   
   # 
   # Single Job ...
   #
   echo "Running Single Job for all $ll connections ..."
   . ./batch.sh 1 $ll

fi


#
# HTML Report from Individual Job Results ...
#
echo "[" > ${REPORT_TMP}
sed '$ s/.$//' ${REPORT}.json >> ${REPORT_TMP}
echo "]" >> ${REPORT_TMP}

farr=`cat "${REPORT_TMP}" | jq --raw-output ". | sort_by(.job)"`
echo "${farr}" | jq --raw-output ".[] | .Run, .JobName, .Results" >> ${REPORT}

# 
# HTML Report The End ...
#
echo "</table><span style=\"color:blue;\">Powered by Delphix Masking APIs v5.2</span>" >> ${REPORT}
echo "</body></html>" >> ${REPORT}
echo "==============================================="
end_time=`date +%s`
echo "Execution time was `expr $end_time - $start_time` s."
echo "HTML Report: file://${REPORT}" 
echo "Done ..."
exit 0;

