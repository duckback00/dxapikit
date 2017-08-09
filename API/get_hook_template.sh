#!/bin/bash
#v1.x

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#                   DELPHIX CORP                        #
#########################################################

#########################################################
#Parameter Initialization

. ./delphix_engine.conf



#HOOK_TPL="test"

#
# Command Line Arguments ...
#
HOOK_TPL=$1
if [[ "${HOOK_TPL}" == "" ]]
then
   echo "Please Enter Hook Template Name (case sensitive): "
   read HOOK_TPL
   if [ "${HOOK_TPL}" == "" ]
   then
      echo "No Hook Template Name Provided, Exiting ..."
      exit 1;
   fi
fi;
export HOOK_TPL


#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################


##echo "Authenticating on ${BaseURL}"

#########################################################
## Session and Login ...

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ..."
   exit 1;
fi

##echo "Session and Login Successful ..."

#########################################################
## Get hook template ...

##echo "Hook Template ... " 
STATUS=`curl -s -X GET -k ${BaseURL}/source/operationTemplate  -b "${COOKIE}" -H "${CONTENT_TYPE}"`

# 
# Show Pretty (Human Readable) Output ...
#
#echo ${STATUS} | jq "."

#echo ${STATUS} | jq --raw-output ".result[].name"
#echo ${STATUS} | jq --raw-output ".result[].reference"
#echo ${STATUS} | jq --raw-output ".result[].operation.type"

# type:  RunPowerShellOnSourceOperation
if [[ "${HOOK_TPL}" == "LIST" ]] || [[ "${HOOK_TPL}" == "list" ]]
then
   echo "List Hook Template Names ..."
   echo ${STATUS} | jq --raw-output ".result[].name"
   echo "Exiting ..."
   exit 0;
fi

# Line 1 is .reference, Line 2 is %, Line 3-n is command
#echo ${STATUS} | jq --raw-output '.result[] | select(.operation.type=="RunPowerShellOnSourceOperation" and .name=="'"${HOOK_TPL}"'") | .reference,"%",.operation.command '
CMD=`echo ${STATUS} | jq --raw-output '.result[] | select(.operation.type=="RunPowerShellOnSourceOperation" and .name=="'"${HOOK_TPL}"'") | .reference,.operation.command'`
#echo "CMD> $CMD"

#
# Split String delimited by linefeeds into an Array ...
#
oldIFS="$IFS"
IFS='
'
IFS=${IFS:0:1} # this is useful to format your code with tabs
CMDARR=( $CMD )
IFS="$oldIFS"

var1=""
var2=""
let i=0
for line in "${CMDARR[@]}"
do
   let i=i+1
   if [[ $i > 1 ]] 
   then
      #echo "$i -- $line"
      #echo "${line}"
      var1=$(sed 's/\\/\\\\"/g' <<< "$line")        # for Windows directory paths
      var1=$(sed 's/.\{1\}$/\\r\\n/' <<< "$var1")   # truncate linefeed and replace with \r\n
      var2=${var2}${var1}
   fi
done

#echo $var2
var3=$(sed 's/"/\\"/g' <<< "$var2")           # escape double quotes
echo "\"${var3}\""

#
# optional if known hook template reference is known ...
#
#TPL_REF=`echo "${CMDARR[0]}"`
#echo "TPL_REF> $TPL_REF"

#STATUS=`curl -s -X GET -k ${BaseURL}/source/operationTemplate/${TPL_REF}  -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo ${STATUS} | jq "."

# 
# The End is Hear ...
#
exit 0;

