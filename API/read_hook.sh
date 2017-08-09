#!/bin/bash
#v1.1



CMD=`./get_hook_template.sh test`
#CMD=`./get_hook_template.sh myTemplate`
#CMD=`./get_hook_template.sh getUsers`

echo "${CMD}" 

echo " "
echo "--------"

#echo ${CMD/$'\n'/}
#echo "shit ${CMD}" | sed -e 's,\\n,zzz,g'
#echo "shit ${CMD}" | sed ':a;N;$!ba;s/\n/ /g'
#echo "shit ${CMD}" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'

#
# Split String delimited by linefeeds into an Array ...
#
oldIFS="$IFS"
IFS='
'
IFS=${IFS:0:1} # this is useful to format your code with tabs
CMDARR=( $CMD )
IFS="$oldIFS"

var2=""
let i=0
for line in "${CMDARR[@]}"
do
   let i=i+1
#   echo "$i -- $line"
var1=$(sed 's/\\/\\\\"/g' <<< "$line")        # for Windows directory paths
var1=$(sed 's/.\{1\}$/\\r\\n/' <<< "$var1")   # truncate linefeed and replace with \r\n
var2=${var2}${var1}

done

#echo $var2
var3=$(sed 's/"/\\"/g' <<< "$var2")           # escape double quotes
echo "\"${var3}\""


echo " "
exit 0
