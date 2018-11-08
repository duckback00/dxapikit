#!/bin/bash
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
# Program Name : user_operations.sh
# Description  : Delphix API User Operations 
# Author       : Alan Bitterman
# Created      : 2018-11-12
# Version      : v1.0
#
# Requirements :
#  1.) curl and jq command line libraries 
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#
# Current Limitations: 
# x.) Only Account type of Local "NATIVE" supported (no LDAP yet)
# x.) Only Authorization type of "PasswordCredential" supported (current product UI limitation as well) 
# x.) Script only runs on Linux/Unix platforms
#
# Interactive Usage
#./user_operations.sh
#
# Optional Command Line Arguments 
#./user_operations.sh [delete] [user_name] 
#./user_operations.sh [list] [user_name|ALL] 
#./user_operations.sh [create] [user_name] [user|admin|selfservice] [first_name] [last_name] [email] [NATIVE] [PasswordCredential] [Password] 
#
# Non-Interactive Usage Examples
#./user_operations.sh create user1 "user" "Alan" "Bitt..." "bitt@delphix.com" "NATIVE" "PasswordCredential" "welcome123"
#./user_operations.sh create admin1 "admin" "Alan" "Bitt..." "bitt@delphix.com" "NATIVE" "PasswordCredential" "welcome123"
#./user_operations.sh create dev2 "selfservice" "Alan" "Bitt..." "bitt@delphix.com" "NATIVE" "PasswordCredential" "welcome123"
#./user_operations.sh list dev2
#./user_operations.sh list ALL
#./user_operations.sh delete dev2
# 
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#
# Default Values if not provided on Command Line ...
#
# For non-interactive defaults ...
#
#DEF_USER_TYPE="user"       		# user|admin|selfservice
#DEF_USER_NAME="dev1"
#DEF_USER_EMAIL="dev@delphix.com"
#DEF_FIRST_NAME="dev1"
#DEF_LAST_NAME="dev1"
#DEF_AUTH_TYPE="NATIVE"			# NATIVE, LDAP
#DEF_CREDENTIAL_TYPE="PasswordCredential"
#DEF_CREDENTIAL_PASSWORD="dev"

#
# For full interactive option, set default values to nothing ...
#
DEF_USER_TYPE=""
DEF_USER_NAME=""
DEF_USER_EMAIL=""
DEF_FIRST_NAME=""
DEF_LAST_NAME=""
DEF_AUTH_TYPE=""
DEF_CREDENTIAL_TYPE=""
DEF_CREDENTIAL_PASSWORD=""

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
## Authentication ...

echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ... ${RESULTS}"
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
## User API Call ...

echo " "
echo "User API ..."
STATUS=`curl -s -X GET -k ${BaseURL}/user -b "${COOKIE}" -H "${CONTENT_TYPE}"`

#########################################################
## Command Line Arguments ...

#########################################################
## Action ...

ACTION=$1
if [[ "${ACTION}" == "" ]]
then
   echo "Please Enter User Option [list|create|delete] : "
   read ACTION
   if [ "${ACTION}" == "" ]
   then
      echo "No Operation Provided, Exiting ..."
      exit 1;
   fi
   ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')
fi
export ACTION

USER_NAME="$2"
if [[ "${USER_NAME}" == "" ]]
then
   if [[ "${DEF_USER_NAME}" == "" ]]
   then
      #
      # Parse out names ...
      #
      USER_NAMES=`echo ${STATUS} | jq --raw-output '.result[] | .name '`
      echo "Existing User Names: "
      echo "${USER_NAMES}"
      echo "ALL"
      echo "Please Enter User Name (case sensitive): "
      read USER_NAME
      if [ "${USER_NAME}" == "" ]
      then
         echo "No User Name Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No User Name Provided, using Default ..."
      USER_NAME=${DEF_USER_NAME}
   fi
fi
export USER_NAME

#########################################################
## User API Call ...

#echo "User API ..."
#STATUS=`curl -s -X GET -k ${BaseURL}/user -b "${COOKIE}" -H "${CONTENT_TYPE}"`

#
# Parse reference for user name ...
#
USER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${USER_NAME}"'") | .reference '`
if [[ "${USER_REFERENCE}" != "" ]]
then
   echo "user reference: ${USER_REFERENCE}"
fi

#########################################################
#
# create, list or delete the user based on the argument passed to the script
#
case ${ACTION} in
create)
;;
delete)
;;
list)
;;
*)
  echo "Unknown option [list|create|delete]: $ACTION"
  echo "Exiting ..."
  exit 1;
;;
esac

#
# Create User ...
#
if [ "${ACTION}" == "create" ] && [ "${USER_REFERENCE}" == "" ]
then

## Get the rest of the command line arguments ...
#  ./user_operations.sh create [user_name] [type] [firstName] [lastName] [email] [authentication_type] [credential_type] [credential_password]

USER_TYPE="${3}"
if [[ "${USER_TYPE}" == "" ]]
then
   if [[ "${DEF_USER_TYPE}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter User Type [user|admin|selfservice]: "
      read USER_TYPE
      if [[ "${USER_TYPE}" == "" ]]
      then
         echo "No User Type Provided, Exiting ..."
         exit 1
      fi
   else
      echo "No Value Provided, using Default ..."
      USER_TYPE=${DEF_USER_TYPE}
   fi
fi

FIRST_NAME="${4}"
if [[ "${FIRST_NAME}" == "" ]]
then
   if [[ "${DEF_FIRST_NAME}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter First Name: "
      read FIRST_NAME
      if [[ "${FIRST_NAME}" == "" ]]
      then
         echo "No First Name Provided, Exiting ..."
         exit 1
      fi
   else
      echo "No Value Provided, using Default ..."
      FIRST_NAME=${DEF_FIRST_NAME}
   fi
fi

LAST_NAME="${5}"
if [[ "${LAST_NAME}" == "" ]]
then
   if [[ "${DEF_LAST_NAME}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter Last Name: "
      read LAST_NAME
      if [[ "${LAST_NAME}" == "" ]]
      then
         echo "No Last Name Provided, Exiting ..."
         exit 1
      fi
   else     
      echo "No Value Provided, using Default ..."
      LAST_NAME=${DEF_LAST_NAME}
   fi
fi

USER_EMAIL="${6}"
if [[ "${USER_EMAIL}" == "" ]]
then
   if [[ "${DEF_USER_EMAIL}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter User Email: "
      read USER_EMAIL
      if [[ "${USER_EMAIL}" == "" ]]
      then
         echo "No User Email Provided, Exiting ..."
         exit 1
      fi
   else
      echo "No Value Provided, using Default ..."
      USER_EMAIL=${DEF_USER_EMAIL}
   fi
fi

AUTH_TYPE="${7}"
if [[ "${AUTH_TYPE}" == "" ]]
then
   if [[ "${DEF_AUTH_TYPE}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter Authorization Type [NATIVE|LDAP (not supported yet)]: "
      read AUTH_TYPE
      if [[ "${AUTH_TYPE}" == "" ]]
      then
         echo "No Authorization Type Provided, Exiting ..."
         exit 1
      fi
   else     
      echo "No Value Provided, using Default ..."
      AUTH_TYPE=${DEF_AUTH_TYPE}
   fi
fi

CREDENTIAL_TYPE="${8}"
if [[ "${CREDENTIAL_TYPE}" == "" ]]
then
   if [[ "${DEF_CREDENTIAL_TYPE}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter Credential Type [PasswordCredential]: "
      read CREDENTIAL_TYPE
      if [[ "${CREDENTIAL_TYPE}" == "" ]]
      then
         echo "No Credential Type Provided, Exiting ..."
         exit 1
      fi
   else    
      echo "No Value Provided, using Default ..."
      CREDENTIAL_TYPE=${DEF_CREDENTIAL_TYPE}
   fi
fi

CREDENTIAL_PASSWORD="${9}"
if [[ "${CREDENTIAL_PASSWORD}" == "" ]]
then
   if [[ "${DEF_CREDENTIAL_PASSWORD}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter Credential Password: "
      read CREDENTIAL_PASSWORD
      if [[ "${CREDENTIAL_PASSWORD}" == "" ]]
      then
         echo "No Credential Password Provided, Exiting ..."
         exit 1
      fi
   else
      echo "No Value Provided, using Default ..."
      CREDENTIAL_PASSWORD=${DEF_CREDENTIAL_PASSWORD}
   fi
fi

#
# Build JSON String ...
#
JSON="{
    \"type\": \"User\",
    \"name\": \"${USER_NAME}\",
    \"emailAddress\": \"${USER_EMAIL}\",
    \"firstName\": \"${FIRST_NAME}\",
    \"lastName\": \"${LAST_NAME}\",
    \"authenticationType\": \"${AUTH_TYPE}\",
    \"credential\": {
        \"type\": \"${CREDENTIAL_TYPE}\",
        \"password\": \"${CREDENTIAL_PASSWORD}\"
    }
}"

   echo "JSON> ${JSON}"

   #
   # Create User ...
   #
   STATUS=`curl -s -X POST -k --data @- ${BaseURL}/user -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${JSON}
EOF
`

   echo "Results: ${STATUS}"
   USER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result'`
   echo "New User Reference: ${USER_REFERENCE}" 

   #
   # Set User Type ...
   #
   #      echo "Please Enter User Type [user|admin|selfservice]: "

   if [[ "${USER_TYPE}" == "admin" ]]
   then
      echo "Adding Delphix Administrator Role ..."
      STATUS=`curl -s -X POST -k --data @- ${BaseURL}/authorization -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "Authorization",
    "user": "${USER_REFERENCE}",
    "role": "ROLE-1",
    "target": "DOMAIN"
}
EOF
`
      echo "Results: ${STATUS}"
   fi

   if [[ "${USER_TYPE}" == "selfservice" ]]
   then
      echo "Assigning Self Service Only Role ..."
      STATUS=`curl -s -X POST -k --data @- ${BaseURL}/authorization -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "Authorization",
    "user": "${USER_REFERENCE}",
    "role": "ROLE-3",
    "target": "${USER_REFERENCE}"
}
EOF
`
      echo "Results: ${STATUS}"
   fi


elif [ "${ACTION}" == "create" ] && [ "${USER_REFERENCE}" != "" ]
then
   echo "Warning: User Name ${USER_NAME} already exists ..."
fi      # end if create ...

#
# delete ...
#
if [ "${ACTION}" == "delete" ] && [ "${USER_REFERENCE}" != "" ]
then
   STATUS=`curl -s -X POST -k --data @- ${BaseURL}/user/${USER_REFERENCE}/${ACTION} -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
}
EOF
`

   echo "Results: ${STATUS}"

elif [ "$1" == "delete" ] && [ "${USER_REFERENCE}" == "" ]
then
   echo "Warning: User Name ${USER_NAME} does not exist ..."
fi      # end if delete ...

#
# List User ...
#
if [[ "${ACTION}" == "list" ]] && [[ "${USER_REFERENCE}" != "" ]] || [[ "${USER_NAME}" == "ALL" ]]
then
   if [[ "${USER_NAME}" != "ALL" ]]
   then 
      echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${USER_NAME}"'") '

   else

      echo ${STATUS} | jq "."

      #########################################################
      ## Some jq parsing examples ...

      #ADMIN_REF=`echo "${STATUS}" | jq --raw-output ".result[] | select (.name == \"delphix_admin\") | .reference"`
      #echo "delphix_admin User Reference: ${ADMIN_REF}"

      USERS=`echo "${STATUS}" | jq --raw-output ".result[].name"`
      echo "List All User Names: ${USERS}"

      #
      # Process Arrays using jq ...
      #
      echo "All User Name References for JSON purposes ..."
      REFS="["
      DELIM=""
      while read usr
      do
         ##DEBUG##echo "|${usr}|"
         Z=`echo "${STATUS}" | jq --raw-output ".result[] | select (.name == \"${usr}\") | .reference"`
         if [[ "${Z}" != "" ]]
         then
            #REFS="${REFS}${DELIM}\"${Z}\""	    # quoted
            REFS="${REFS}${DELIM}"'\"'${Z}'\"'    # quotes escaped
            DELIM=","
         fi
      done <<< "${USERS}"       ### "$TMP"
      REFS="${REFS}]"
      echo "References: ${REFS}"

   fi

elif [ "${ACTION}" == "list" ] && [ "${USER_REFERENCE}" == "" ]
then
   echo "User ${USER_NAME} not found, exiting ..."

fi

############## E O F ####################################
echo "Done ..."
echo " "
exit 0
