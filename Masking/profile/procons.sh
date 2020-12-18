#!/bin/bash
#
#    Filename: procons.sh
#      Author: Alan Bitterman
# Description: This script reads a CSV file and creates database connections JSON string
#
# Note: If using Excel, be sure the save the CSV file as Windows CSV File format.
#

#######################################################################
## Command Line Arguements ...
 
PFILE=""
if [[ "${1}" == "" ]]
then 
   PFILE="profile_connections.csv"	# Default Profile Connections CSV file ... 
else
   PFILE="${1}"				# Command Line specificed CSV file ...
fi

#######################################################################
## Just to be safe of source LF ...

#dos2unix ${PFILE}
#sed -e 's/\^M/\n/g' ${PFILE} > ${PFILE}.tmp

#######################################################################
## Convert CSV to JSON Array containing Database Connection Objects ...

let i=0
JSON="["
DELIM=""
DELIM1=""
OLD_IFS="$IFS"
while IFS='' read -r line || [[ -n "$line" ]]; do
   #echo "$i:  $line"
   if [[ $i == 0 ]] 
   then
      #echo "header"
      IFS=,
      harr=($line)
   else 
      #echo "data"
      IFS=,
      arr=($line)
      JSON="${JSON}
${DELIM}{"
      DELIM1=""
      let j=0
      arraylength=${#arr[@]}    # get length of an array
      for (( j=1; j<${arraylength}; j++ ));
      do
         #echo $j " / " ${arraylength} " : " ${arr[$j-1]}
if [[ "${arr[$j-1]}" != "" ]] 
then
         if [[ "${harr[$j-1]}" == "port" ]]
         then
            JSON="${JSON}
${DELIM1}\"${harr[$j-1]}\": ${arr[$j-1]} "
         else
            JSON="${JSON}
${DELIM1}\"${harr[$j-1]}\": \"${arr[$j-1]}\" "
         fi
         DELIM1=","
fi
      done
      JSON="${JSON}
, \"connNo\": ${i}
}"
      DELIM=","
   fi
   let i=i+1
done < "${PFILE}"
IFS="${OLD_IFS}"
JSON="${JSON}
]"

#######################################################################
## Verify ...

#echo "${JSON}" | jq "."
CONN="${JSON}"

#
# No exit since we are returning to calling script ...
#
