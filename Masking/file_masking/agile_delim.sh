#!/bin/bash
#######################################################################
# Filename: agile_delim.sh
# Version: v1.0
# Date: 2017-11-09
# Last Updated: 2017-11-09 Bitt...
# Author: Alan Bitterman
#
# Description: Demo script for masking delimited files
#              using the new Delphix Masking 5.2 APIs
#
#
# Arguments:
#
#./agile_delim.sh 
#     [data_file] 					# 1 Source Delimited File
#         [header_file] 				# 2 or "" Optional Column Header Names one per line
#            [algorithm_file]				# 3 Column Header Name, Domain Name and Algorithm mapping file
#               [environment_name]			# 4 Existing Masking Environment Name
#                  [file_connector]			# 5 Existing Masking Connector Name to this path
#                     [DELIMITED, EXCEL, FIXED_WIDTH]   # 6 File Type: DELIMITED only valid type for this script
#                        [endOfRecord] 			# 7 linux only supported at this time (hard coded) 
#                           [delimChar] 		# 8 Source File delimiter: comma
#                              [textEnclosure] 		# 9 Source File text enclosure: double quote
#                                  [YES, NO]		#10 Clean Up: YES or NO
#
# Usage:  Delimited File with Header Column Names in first line ...  
# ./agile_delim.sh bmobitth.csv "" delim_domains.txt "file_env" "file_delim_conn" "DELIMITED" "linux" "," "\"" "YES"
#
# Usage:  Delimited File Data ONLY with seperate Column Names file ...
# ./agile_delim.sh bmobitt.csv delim_fields.txt delim_domains.txt "file_env" "file_delim_conn" "DELIMITED" "linux" "," "\"" "YES"
#
#./agile_delim.sh bmobitt.csv delim_fields.txt delim_domains.txt "file_env" "eko_conn" "DELIMITED" "linux" "," "\"" "YES"
#########################################################
#                   DELPHIX CORP                        #
#########################################################
#
# Debug ...
#
#set -x 

#########################################################
## Delphix Masking Parameter Initialization

DMIP=172.16.160.195
DMPORT=8282
DMUSER="Admin"
DMPASS="Admin-12"
DMURL="http://${DMIP}:${DMPORT}/masking/api"
DELAYTIMESEC=10

#########################################################
##        NO CHANGES REQUIED BELOW THIS LINE           ##
#########################################################

#
# DEMO Reset ...
#
if [[ -f "${1}_orig" ]] 
then
   cp ${1}_orig ${1}
   echo "Backup file copied ${1}_orig ${1} ..."
fi

#
# Command Line Arguments ...
#
DT=`date '+%Y%m%d%H%M%S'`

M_SOURCE_FILE=${1}
export M_SOURCE_FILE

M_HEAD=${2}
export M_HEAD

M_DOMAIN=${3}
export M_DOMAIN

M_ENV=${4}
export M_ENV

M_ENV=$(sed -e 's/ /%20/g' -e 's/!/%21/g' -e 's/"/%22/g' -e 's/#/%23/g' -e 's/\&/%26/g' -e 's/'\''/%28/g' -e 's/(/%28/g' -e 's/)/%29/g' -e 's/{/%7B/g' -e 's/}/%7D/g' -e 's/:/%3A/g' -e 's/\//%2F/g'<<<$M_ENV);

M_CONN=${5}
export M_CONN

M_CONN=$(sed -e 's/ /%20/g' -e 's/!/%21/g' -e 's/"/%22/g' -e 's/#/%23/g' -e 's/\&/%26/g' -e 's/'\''/%28/g' -e 's/(/%28/g' -e 's/)/%29/g' -e 's/{/%7B/g' -e 's/}/%7D/g' -e 's/:/%3A/g' -e 's/\//%2F/g'<<<$M_CONN);

M_FILE_TYPE=${6}
export M_FILE_TYPE

M_EOR=${7}
export M_EOR
 
M_DELIM=${8}
export M_DELIM

M_TEXT=${9}
export M_TEXT

CLEANUP=${10}
export CLEANUP

M_FILE_FORMAT_NAME="EKO_delimitedFile_${DT}"
export M_FILE_FORMAT_NAME

M_RULE_SET="EKO_delimRS_${DT}"
export M_RULE_SET

M_MASK_NAME="EKO_delimMaskingJob_${DT}"
export M_MASK_NAME

M_RECORD_TYPE_NM="EKO_delim_records_${DT}"
export M_RECORD_TYPE_NM

M_HEADER_RECORD_TYPE_NM="EKO_Header_Record_${DT}"
export M_HEADER_RECORD_TYPE_NM

M_TRAILER_RECORD_TYPE_NM="EKO_Trailer_Record_${DT}"
export M_TRAILER_RECORD_TYPE_NM

M_HEADER_RECORD_LINES=""
export M_HEADER_RECORD_LINES

M_TRAILER_RECORD_LINES=""
export M_TRAILER_RECORD_LINES

######################################################

echo "Source File: ${M_SOURCE_FILE}"
echo "Header File: ${M_HEAD}"
echo "Domain File: ${M_DOMAIN}"
echo "Environment: ${M_ENV}"
echo "Connector: ${M_CONN}"
echo "File Type: ${M_FILE_TYPE}"
echo "End of Record: ${M_EOR}"
echo "Delimiter: ${M_DELIM}"
##M_TEXT="\"";
echo "Text Enclosure: ${M_TEXT}"

echo "File Format Name: ${M_FILE_FORMAT_NAME}"
echo "Rule Set Name: ${M_RULE_SET}"
echo "Masking Job Name: ${M_MASK_NAME}"

echo "Header Record # Lines: ${M_HEADER_RECORD_LINES}"
echo "Trailer Record # Lines: ${M_TRAILER_RECORD_LINES}"

echo "Cleanup: ${CLEANUP}"

#########################################################
## Custom Source Files Parameter Initialization

#
# Mac - Linux differences ...
#
OS="`uname`"
echo "OS: ${OS}"
if [[ "${OS}" == "Darwin" ]]
then
  SED="sed -i .bkup"
  TS=`echo $(gdate +"%Y-%m-%d %H:%M:%S.%3N")`
else
  SED="sed -i"
  TS=`echo $(date +"%Y-%m-%d %H:%M:%S.%3N")`
fi
echo "Timestamp: ${TS}"

#########################################################
## File Pre-Processing ...
#########################################################

#########################################################
## Convert EBCDIC file to ASCII without LineFeeds ...

# echo "/bin/bash ./test1.sh ${filename}"
# /bin/bash ./test1.sh ${filename} .out .hout

#########################################################
## Read File to confirm or in the future determine delimited or fixed width file format

#########################################################
## Create Header File if not provided, assuming first line in file is header ...
 
#   
# Write header file when included as first line of file ...
#
# delimitedFiles:  field1,field2,field3,etc.            M_DELIM=,
#
header_line=""
if [[ "${M_HEAD}" == "" ]] 
then
   # 
   # Get Header and Trailer Lines ...
   #
   header_line=$(head -n 1 ${M_SOURCE_FILE})
   #echo "header: $header_line"
   #trailer_line=$(tail -1 ${M_SOURCE_FILE} | head -1)
   #
   # Remove first line from file ...
   #
   tail -n +2 "${M_SOURCE_FILE}" > "${M_SOURCE_FILE}.tmp" && mv "${M_SOURCE_FILE}.tmp" "${M_SOURCE_FILE}"
   #
   # Build header file ...
   #
   hfile="delim_test.hout"
   echo ${header_line} | awk -F"${M_DELIM}" '{for(i=1;i<=NF;i++){print $i}}' > ${hfile} 
   if [[ -f ${hfile} ]]
   then 
      #echo "Header file created ${hfile} ..."
      # Remove any double quotes ...
      ${SED} "s/\"//g" ${hfile}
      # Replace spaces with _ ...
      ${SED} "s/ /_/g" ${hfile}
   else
      echo "Error: Missing header file ${hfile}, please check for errors ... "
      exit 1;
   fi
   M_HEAD=${hfile}
   echo "Fields File Created M_HEAD=${M_HEAD}"
   if [[ "M_HEADER_RECORD_LINES" == "" ]]
   then
      M_HEADER_RECORD_LINES=1
   else 
     let M_HEADER_RECORD_LINES=${M_HEADER_RECORD_LINES}+1
   fi
   echo "M_HEADER_RECORD_LINES=${M_HEADER_RECORD_LINES}"
fi

#########################################################
## Pre Processing Source File ...

#
# Any file conversions go hear ..
#

#########################################################
## Data Pre-Processing ...
#########################################################

#
# Custom Formatted Fields ...
#

#########################################################
## Create Masking Objects via API ... 
#########################################################

#########################################################
## Authentication ...

STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \"username\": \"${DMUSER}\", \"password\": \"${DMPASS}\" }" "${DMURL}/login"`
#echo ${STATUS} | jq "."
KEY=`echo "${STATUS}" | jq --raw-output '.Authorization'`
echo "Authentication Key: ${KEY}"

#########################################################
## Get Masking Environment and Connector ID's ...

echo "Environment: ${M_ENV}"
echo "Connector: ${M_CONN}"

#
# Get Environment Id and Application Name ...
#
STATUS=`curl -s -X GET --header 'Accept: application/json' --header "Authorization: ${KEY}" "${DMURL}/environments"`
#echo "${STATUS}" | jq "."
ENVID=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.environmentName == \"${M_ENV}\") | .environmentId"`
M_APP_NM=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.environmentName == \"${M_ENV}\") | .application"`
if [[ "${ENVID}" == "" ]]
then
   echo "ERROR: Environment ${M_ENV} Not Found, Exiting ..."
   exit 1;
fi
echo "Environment Id: ${ENVID}"
echo "Application Name: ${M_APP_NM}"

#
# Get Connector Id ...
#
STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/file-connectors"`
#echo ${STATUS} | jq "."
M_CONN_ID=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.connectorName == \"${M_CONN}\" and .environmentId == ${ENVID}) | .fileConnectorId "`
echo "File Conn Id: ${M_CONN_ID}"
if [[ "${M_CONN_ID}" == "" ]]
then
   echo "ERROR: Connector Name ${M_CONN} Not Found, Exiting ..."
   exit 1;
fi

echo "=================================================================="

#########################################################
## Create File Format ...

echo "Creating File Format ..."
cp "${M_HEAD}" "${M_FILE_FORMAT_NAME}"
STATUS=`curl -s --header "Authorization: ${KEY}" -F "fileFormat=@${M_FILE_FORMAT_NAME}" -F "fileFormatType=${M_FILE_TYPE}" "${DMURL}/file-formats"`
#echo "${STATUS}" | jq "."
M_FILE_FORMAT_ID=`echo ${STATUS} | jq --raw-output ".fileFormatId"`
echo "file_format_name: ${M_FILE_FORMAT_NAME}"
echo "file_format_id: ${M_FILE_FORMAT_ID}"
echo "file_type: ${M_FILE_TYPE}"

#########################################################
## Create Rule Set ...

echo "Creating Rule Set ${M_RULE_SET} ..."
STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"rulesetName\": \"${M_RULE_SET}\", \"fileConnectorId\": ${M_CONN_ID} }" "${DMURL}/file-rulesets"`
#echo ${STATUS} | jq "."
RSID=`echo "${STATUS}" | jq --raw-output ".fileRulesetId"`
echo "Rule Set Id: ${RSID}"

#########################################################
## Source Data File Relationships ...

echo "Creating Source Data File Relationships ..."

#
# EOR hard coded for now ...
#
json="{
  \"fileName\": \"${M_SOURCE_FILE}\",
  \"rulesetId\": ${RSID},
  \"fileFormatId\": ${M_FILE_FORMAT_ID},
  \"delimiter\": \"${M_DELIM}\",
  \"endOfRecord\": \"\\n\"
}"
#  \"sdfsdfsd\": \"${M_TEXT}\"

RESULTS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "${json}" "${DMURL}/file-metadata"`
echo "${RESULTS}" | jq "."
M_DATA_FILE_ID=`echo ${RESULTS} | jq --raw-output ".fileMetadataId"`
echo "data_field_id: ${M_DATA_FILE_ID}"

########################################################################
## Record Types Go Here ...

# Add Body Record Type ...
# Add Header Record Type ...
# Add Trailer Record Type ...

########################################################################
## Process File Fields ...

echo "Creating File Field Records ..."

STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/file-field-metadata?file_format_id=${M_FILE_FORMAT_ID}&page_number=1"`
#echo "${STATUS}" | jq "."

#FIELD_NAMES=`echo "${STATUS}" | jq --raw-output ".responseList[].fieldName"`
#echo "${FIELD_NAMES}"

#########################################################
## Logic

#
#  Loop through each line in th ${M_DOMAIN} file and when
#  field name match is found, update the domain/algorithm 
#
# Update Inventory File Field Values for Masking ...
#
let k=1
while read line2
do
   echo "Processing $line2 ... "
   # 
   # Parse Domain/Algorithm File Data ...
   #
   NAM2=`echo $line2 | awk -F"," '{ print $1 }'`
   C1=`echo ${NAM2:0:1}`            # check for comment lines ...
   if [[ "${C1}" == "#" ]]
   then
      printf " Comment Line Skipping.\n"
   else 
      VAL2=`echo $line2 | awk -F"," '{ print $2 }'`
      VAL3=`echo $line2 | awk -F"," '{ print $3 }'`
      VAL4=`echo $line2 | awk -F"," '{ print $4 }'`

      M_FILE_FIELD_ID=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.fieldName==\"${NAM2}\") | .fileFieldMetadataId" `
      echo "file_field_id: ${M_FILE_FIELD_ID}"

      if [[ "${VAL2}" != "" ]] && [[ "${M_FILE_FIELD_ID}" != "" ]]
      then
         echo "Updating Domain and Algorithm for field ${NAM2} for id = ${M_FILE_FIELD_ID} ..."
         JSON="{
   \"algorithmName\": \"${VAL3}\", 
   \"domainName\": \"${VAL2}\" 
}"
         #echo $JSON
         #
         # Update (POST) file-field-metadata, i.e. add domain and algorithm ...
         #
         RESULTS=`curl -s -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "${JSON}" "${DMURL}/file-field-metadata/${M_FILE_FIELD_ID}"`
         #echo "${RESUTLS}" | jq "." 
      fi 	# end if VAL2 != ""
   fi   	# end if comment line
   #
   # Reset/Set loop variables ...
   #
   NAM2=""
   VAL2=""
   k=$((k+1))

done < ${M_DOMAIN}

########################################################
## Create Masking Job ...

echo "Creating Masking Job ${M_MASK_NAME} ..."
json="{ 
   \"jobName\": \"${M_MASK_NAME}\", 
   \"rulesetId\": ${RSID}, 
   \"jobDescription\": \"Created File MaskingJob from API\", 
   \"feedbackSize\": 10000, 
   \"onTheFlyMasking\": false, 
   \"databaseMaskingOptions\": { 
     \"batchUpdate\": true, 
     \"commitSize\": 10000, 
     \"dropConstraints\": true 
   } 
}"
#     \"commitSize\": 10000,

RESULTS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "${json}" "${DMURL}/masking-jobs"`

JOBID=`echo ${RESULTS} | jq --raw-output ".maskingJobId" `
echo "job_id: ${JOBID}"

echo "=================================================================="

#########################################################
## Execute Masking Job ...

echo "Running Masking JobID ${JOBID} for Application ${M_APP_NM} ..."
STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"jobId\": ${JOBID} }" "${DMURL}/executions"`
#echo ${STATUS} | jq "."
EXID=`echo "${STATUS}" | jq --raw-output ".executionId"`
echo "Execution Id: ${EXID}"

#########################################################
## Monitor Job Status ...

JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`
sleep 1
while [[ "${JOBSTATUS}" == "RUNNING" ]]
do
   STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/executions/${EXID}"`
   #echo ${STATUS} | jq "."
   JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`
   #echo "${JOBSTATUS}" 
   printf "."
   sleep ${DELAYTIMESEC}   
done
printf "\n"

if [[ "${JOBSTATUS}" != "SUCCEEDED" ]]
then
   echo "Job Error: $JOBSTATUS ... $STATUS"
else
   echo "Masking Job Completed: $JOBSTATUS"
   echo ${STATUS} | jq "."
fi

echo "Please Verify Masked Source File: ${M_SOURCE_FILE}"

#####################################################
## Masking Clean Up ...

echo "=================================================================="
  
# 
# Delete Masking Job ...
# Delete Rule Set ...
# Delete File Format ...
#
if [[ "${CLEANUP}" == "YES" ]]
then
   echo "Clean Up ..."
   STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/masking-jobs/${JOBID}"`
   #echo "${STATUS}" | jq "."
   STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/file-rulesets/${RSID}"`
   #echo "${STATUS}" | jq "."
   STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/file-formats/${M_FILE_FORMAT_ID}"`
   #echo "${STATUS}" | jq "."

   #
   # Remove local tmp file format ...
   #
   if [[ -f "${M_FILE_FORMAT_NAME}" ]]
   then 
      rm "${M_FILE_FORMAT_NAME}"
   fi
fi

#####################################################
## Data Post-Processing ...

#####################################################
## Masked File Post-Processing ...

#
# Add Header Line back into Source File ...
#
if [[ "${header_line}" != "" ]]
then
   echo "Adding Header Line ..."
   echo "${header_line}" > "${M_SOURCE_FILE}.tmp"
   cat ${M_SOURCE_FILE} >> "${M_SOURCE_FILE}.tmp" 
   mv "${M_SOURCE_FILE}.tmp" "${M_SOURCE_FILE}"
fi

#
# Add back Segments and Convert back to EBCDIC ... 
#

############## E O F ####################################

echo "Done."

