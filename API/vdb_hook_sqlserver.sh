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



#
# Required for Database Link and Sync ...
#

SOURCE_SID="VBITT"             # Virtual Environment Database SID

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################


echo "Authenticating on ${BaseURL}"

#########################################################
## Session and Login ...

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ..."
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
## ...


#########################################################
## Get source

STATUS=`curl -s -X GET -k ${BaseURL}/source -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Source Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

SOURCE_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.runtime.type=="MSSqlSourceRuntime" and .name=="'"${SOURCE_SID}"'") | .reference '`
echo "source reference: ${SOURCE_REF}"

# 
# Hook JSON ...
#
json="{
    \"type\": \"MSSqlVirtualSource\",
    \"operations\": {
        \"type\": \"VirtualSourceOperations\",
        \"postRefresh\": [
            {
                \"type\": \"RunPowerShellOnSourceOperation\",
                \"command\": \"#\r\n# Variables ...\r\n#\r\n\$filename=\\\"C:\\\temp\\\delphix\\\source_users.sql\\\"\r\n\$outfile=\\\"C:\\\temp\\\delphix\\\vdb_users.txt\\\"\r\n\$tmpHost = \$Env:VDB_INSTANCE_HOST\r\n\$tmpName = \$Env:VDB_INSTANCE_NAME\r\n\$tmpPort = \$Env:VDB_INSTANCE_PORT\r\n\r\nsqlcmd -l 30 -b -S \\\"tcp:\$tmpHost\\\\\$tmpName,\$tmpPort\\\" -W -Usa -Pdelphix -i \$filename -o \$outfile -h-1\r\nexit 0\r\n\" 
            }
        ],
        \"postSnapshot\" : []
    }
}
"

echo "json> ${json}"

## \"command\": \"#\r\n# Variables ...\r\n#\r\n\$nl = [Environment]::NewLine\r\n\$filename=\\\"C:\\\temp\\\delphix\\\getUsers.sql\\\"\r\n\$outfile=\\\"C:\\\temp\\\delphix\\\source_users.sql\\\"\r\n\$tmpHost = \$Env:SOURCE_INSTANCE_HOST\r\n\$tmpName = \$Env:SOURCE_INSTANCE_NAME\r\n\$tmpPort = \$Env:SOURCE_INSTANCE_PORT\r\n#\r\n# Generate SQL ...\r\n#\r\nwrite-output \\\"\${nl}Creating SQL file ...\\\"\r\n\$sql = @\\\"\r\n-- \$tmpHost\\\\\$tmpName,\$tmpPort\r\nset nocount on;\r\nexec master.dbo.sp_help_revlogin\r\nGO\r\n\\\"@\r\n\r\n#\r\n# Output File using UTF8 encoding ...\r\n#\r\nwrite-output \$sql | Out-File \$filename -encoding utf8\r\n\r\nsqlcmd -l 30 -b -S \\\"tcp:\$tmpHost\\\\\$tmpName,\$tmpPort\\\" -W -Usa -Pdelphix -i \$filename -o \$outfile -h-1\r\n\r\n\"
##                \"command\": \"\$outfile=\\\"C:\\\temp\\\delphix\\\mine2.txt\\\"\r\nwrite-output \\\"Hey There D\\\" | Out-File -Append \$outfile -encoding utf8\r\n\"
##  \"write \\\"Hey There D\\\"\r\n\"
##                \"command\": \"\$outfile=\"C:\\\temp\\\delphix\\\mine.txt\"\r\n\$cmd=\"Hey There\"\r\n \"
## exit; 

echo " "
echo "Link Hook "  # MSSQL_LINKED_SOURCE-22
STATUS=`curl -s -X POST -k --data @- ${BaseURL}/source/${SOURCE_REF} -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

# 
# Show Pretty (Human Readable) Output ...
#
echo ${STATUS} | jq "."

# 
# The End is Hear ...
#
echo " "
echo "Done "
exit 0;

