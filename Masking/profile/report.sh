#!/bin/bash
#
#    Filename: report.sh 
#      Author: Alan Bitterman
# Description: This script builds the individual HTML and CSV report files
#

#######################################################################
## Optional Command Line Arguements ...

if [[ "${1}" != "" ]]
then
   BASENAME="${1}"		# Report BaseName ...
else
   BASENAME="json"
fi

JNUM=${2}			# Job Number for Source Report ...

#######################################################################
## Parameters ...

CSV="${BASENAME}.csv"           # Report CSV Path/Filename ...
CSV_FILE=`basename $CSV`        # Report CSV Filename ...
CSV_DELIM=","                   # CSV Delimiter ...
HTML="${BASENAME}.html"         # Report HTML Path/Filename ...

bg="lightgrey"                  # Metadata Background Color ...
bg1="beige"                     # Table Background Color 1 ...
bg2="snow"                      # Table Background Color 2 ...

##########################################
## No changes required below this point ##
##########################################

#######################################################################
## Read JSON Result Data ...

json=`cat ${JSON_OUT}${JNUM}`
#echo "JSON Source: ${JSON_OUT}${JNUM}"
#echo "${json}" | jq "."

#######################################################################
## Sorted Table Names ...
# Note: Important for Diff Report ...

TABLES=`echo "${json}" | jq --raw-output ".tables | sort_by(.tableName) | .[].tableName "`
#echo "Tables:  ${TABLES}"

#######################################################################
## Profile Meta Data ...

SCHEMA=`echo "${json}" | jq --raw-output ".schema"`
SID=`echo "${json}" | jq --raw-output ".sid"`
DBNAME=`echo "${json}" | jq --raw-output ".databaseName"`
INSTANCE=`echo "${json}" | jq --raw-output ".instanceName"`
HOST=`echo "${json}" | jq --raw-output ".host"`
PORT=`echo "${json}" | jq --raw-output ".port"`
DBT=`echo "${json}" | jq --raw-output ".databaseType"`
PSET=`echo "${json}" | jq --raw-output ".profileSet"`
ROWS=`echo "${json}" | jq --raw-output ".rows"`

#######################################################################
## Meta Data for HTML and CSV Reports ...

if [[ "${DBT}" == "MSSQL" ]] 
then
   CONN_STR="${HOST}:${PORT}:${DBNAME}" 
   TMP="${INSTANCE}"
   STR="Database: ${DBT} &nbsp;&nbsp; Connection: ${CONN_STR} &nbsp;&nbsp; Instance: ${INSTANCE} &nbsp;&nbsp; Profile Set: ${PSET} <br />"
else
   CONN_STR="${HOST}:${PORT}:${SID}"
   TMP=${SID}
   STR="Database: ${DBT} &nbsp;&nbsp; Connection: ${CONN_STR} &nbsp;&nbsp; Profile Set: ${PSET} <br />"
fi
CSV_HEADER="Timestamp${CSV_DELIM}Source${CSV_DELIM}Instance${CSV_DELIM}Connection${CSV_DELIM}Profile_Set${CSV_DELIM}Schema"
CSV_META="${DT}${CSV_DELIM}${DBT}${CSV_DELIM}${TMP}${CSV_DELIM}${CONN_STR}${CSV_DELIM}${PSET}${CSV_DELIM}${SCHEMA}"

#######################################################################
## HTML Output ...
 
echo "${BANNER}" > ${HTML}
echo "Timestamp: ${DT} &nbsp;&nbsp; ... &nbsp;&nbsp; <a href=\"${CSV_FILE}\" target=\"_new\">Download CSV File</a><br />" >> ${HTML}
echo "${STR}" >> ${HTML} 
echo "<hr size=3 color=#1AD6F5 />" >> ${HTML}
echo "<table border=0 cellspacing=1 cellpadding=1>" >> ${HTML}
echo "<tr><th>schema</th><th>tableName</th><th>columnName</th><th>isMasked</th><th>domainName</th><th>algorithmName</th></tr>" >> ${HTML}

#######################################################################
## CSV Output ...

echo "${CSV_HEADER}${CSV_DELIM}tableName${CSV_DELIM}columnName${CSV_DELIM}isMasked${CSV_DELIM}domainName${CSV_DELIM}algorithmName${CSV_DELIM}" > ${CSV}

#######################################################################
## Process Table Data ...

if [[ "${TABLES}" != "" ]]
then

   while read tbname
   do
      #
      # Background Colors per Table ...
      #
      if [[ "${bg}" == "${bg1}" ]]
      then
         bg=${bg2}
      else
         bg=${bg1}
      fi

      #echo "... $tbname  "
      ### TABLES=`echo "${json}" | jq --raw-output ".tables | sort_by(.tableName) | .[].tableName "`

      RESULTS=`echo "${json}" | jq --raw-output ".tables[] | select (.tableName == \"${tbname}\" ) | .results.responseList | sort_by(.columnName) "`
      #echo "RESULTS: ${RESULTS}"
      R1=`echo "${RESULTS}" | jq --raw-output ".[]" `
      #echo "R1: ${R1}"

      #
      # HTML ...
      #
      echo "${R1}" | jq --raw-output "\"<tr style='background-color:${bg};'><td>${SCHEMA}</td><td>${tbname}</td><td>\" + .columnName + \"</td><td>\" + (.isMasked|tostring) + \"</td><td>\" + .domainName + \"</td><td>\" + .algorithmName + \"</td></tr>\" " >> ${HTML}

      #
      # CSV ...
      #
      echo "${R1}" | jq --raw-output "\"${CSV_META}${CSV_DELIM}${tbname}${CSV_DELIM}\" + .columnName + \"${CSV_DELIM}\" + (.isMasked|tostring) + \"${CSV_DELIM}\" + .domainName + \"${CSV_DELIM}\" + .algorithmName + \"${CSV_DELIM}\" " >> ${CSV}

   done <<< "${TABLES}"

else

   # 
   # No tables in schema ...
   #
   echo "<tr><td>${SCHEMA}</td><td colspan=5>No Tables in this Schema ...</td></tr>" >> ${HTML}
   echo "${CSV_META}${CSV_DELIM}No Tables in this Schema ...${CSV_DELIM}${CSV_DELIM}${CSV_DELIM}${CSV_DELIM}${CSV_DELIM}" >> ${CSV}

fi

#######################################################################
## HTML ...

echo "</table>" >> ${HTML}
echo "No Tables: ${ROWS} <br />" >> ${HTML} 
echo "<span style=\"color:blue;\">Powered by Delphix Masking APIs</span>" >> ${HTML}
echo "</body></html>" >> ${HTML}

echo "Individual Report: `basename ${BASENAME}`.html created ..."

#
# No exist since we want to return to calling script ...
#
