#!/bin/bash
#
#    Filename: diff.sh
#      Author: Alan Bitterman
# Description: Profile Diff Reports  - Sample 
#

#
# Variables ...
#
##DT=`date '+%Y%m%d%H%M%S'`		# From calling script ...

DIFF_FILE="html/diff.tmp_${DT}"

###HTML="diff_${DT}.html"
HTML="html/diff.html"                   # Demo, just keep same filename ...

bg="lightgrey"                          # Metadata Background Color ...
bg1="beige"                             # Table Background Color 1 ...
bg2="snow"                              # Table Background Color 2 ...

##########################################
## No changes required below this point ##
##########################################

FILE1=""
if [[ "${1}" == "" ]]
then 
   FILE1="html/json.out1"		# Default JSON file ... 
else
   FILE1="${1}"				# Command Line specificed JSON file ...
fi
FILE2=""
if [[ "${2}" == "" ]]
then
   FILE2="html/json.out2"               # Default JSON file ...                   
else
   FILE2="${2}"                         # Command Line specificed JSON file ...
fi
NAME1=""
if [[ "${3}" == "" ]]
then
   NAME1="html/json.out1"
else
   NAME1="${3}"          
fi
NAME2=""
if [[ "${4}" == "" ]]
then
   NAME2="html/json.out2"
else
   NAME2="${4}"          
fi

#
# Remove columns from source JSON file that contain different id values ...
#
cat "${FILE1}" | jq ". | del(.tables[].results.responseList[].tableMetadataId,.tables[].results.responseList[].columnMetadataId,.tables[].tableId)" > 1.tmp_${DT}
cat "${FILE2}" | jq ". | del(.tables[].results.responseList[].tableMetadataId,.tables[].results.responseList[].columnMetadataId,.tables[].tableId)" > 2.tmp_${DT}

#
# Generate a diff report to a file ...
# 
diff -y 1.tmp_${DT} 2.tmp_${DT} > ${DIFF_FILE}
if [[ ! -s "${DIFF_FILE}" ]]
then
   echo "Error in creating diff file ..."
   exit 1
fi

#
# Replace tabs with spaces for formating HTML Output ...
#
expand -t 8 ${DIFF_FILE} > ${DIFF_FILE}_spaces

#
# HTML Output ... 
#
echo "${BANNER}" > ${HTML}
echo "<style>td { white-space:pre; font-size:11pt; padding:2px; }</style>" >> ${HTML}
echo "<center><table boder=0 cellspacing=1 cellpadding=0>" >> ${HTML}
echo "<tr><th>Row</th><th>${NAME1}</th><th>${NAME2}</th></tr>" >> ${HTML}

#
# Loop through lines in Diff Report and build HTML Output ...
#
let i=1
let pos=0
OLD_IFS="$IFS"
while IFS='' read -r line || [[ -n "$line" ]]; do
   ##   echo "$i:  $line"
   #
   # Find position of 2nd column using the length {               {
   #
   if [[ i -eq 1 ]] 
   then
      #echo "$i:  $line"
      pos2=${#line}-1
      let pos=pos2-1
      #echo "Pos: $pos"
      #echo "<tr><td>$i</td><td>${line:0:$pos}</td><td>${line:$pos2}</td></tr>"
   fi
   #
   # Inline Differences ...
   #
   if [[ $line = *"|"* ]] 
   then
      echo "<tr style=\"background-color:pink;\"><td>$i</td><td>${line:0:$pos}</td><td>${line:$pos2}</td></tr>" >> ${HTML}
   elif [[ $line = *">"* ]] || [[ $line = *"<"* ]] 
   then 
      #
      # Missing Line Difference ...
      # 
      echo "<tr style=\"background-color:yellow;\"><td>$i</td><td>${line:0:$pos}</td><td>${line:$pos2}</td></tr>" >> ${HTML}
   elif [[ $line = *"\"tableName\""* ]]
   then
      # 
      # New Table Line ...
      #
      if [[ "${bg}" == "${bg1}" ]]
      then 
         bg=${bg2}
      else 
         bg=${bg1}
      fi
      echo "<tr style=\"background-color:lightblue;\"><td>$i</td><td>${line:0:$pos}</td><td>${line:$pos2}</td></tr>" >> ${HTML}
   else
      # 
      # All Other Lines ...
      #
      echo "<tr style=\"background-color:${bg};\"><td>$i</td><td>${line:0:$pos}</td><td>${line:$pos2}</td></tr>" >> ${HTML}
   fi
   let i=i+1
done < "${DIFF_FILE}_spaces"
IFS="${OLD_IFS}"

echo "</table></center>" >> ${HTML}
echo "</body></html>" >> ${HTML}

#
# Cleanup ...
#
rm "${DIFF_FILE}_spaces"
rm "1.tmp_${DT}"
rm "2.tmp_${DT}"
rm "${DIFF_FILE}"

#
# Verify ...
#
echo "Example Diff Report File: file://`pwd`/${HTML}"
#
# No exit since we are returning to calling script ...
#
