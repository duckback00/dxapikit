#!/bin/bash

LOGFILE="dmsuite.log"
USERNAME="delphix_admin"
PASSWORD="Delphix_123"
MASKINGURL="http://172.16.160.195:8282"

curl -s ${MASKINGURL}/dmsuite/login.do -c ~/cookies.txt -d "userName=$USERNAME&password=$PASSWORD"
curl -s -X GET ${MASKINGURL}/dmsuite/logsReport.do -b ~/cookies.txt > /dev/null

DT=`date '+%Y%m%d%H%M%S'`      # Backup Timestamp ...

if [ -f "${LOGFILE}" ]
then
   mv ${LOGFILE} ${LOGFILE}_${DT}
fi

curl -s -o dmsuite.log -X GET ${MASKINGURL}/dmsuite/logsReport.do?action=download -b ~/cookies.txt

if [ -f  "${LOGFILE}" ]
then
   echo "File: ${LOGFILE} downloaded ..." 
else
   echo "Error: ${LOGFILE} NOT downloaded ..."
fi

exit 0;
