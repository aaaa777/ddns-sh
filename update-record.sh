#!/bin/bash

#read config file
#USERNAME, PASSWORD, TENANTID, DOMAIN

. ./api.conf
echo $USERNAME

#read last global ip from temporary file

_last_global_ip=`cat current-global-ip.tmp`


#GET global ip

_now_global_ip=`eval "$IP_CHECKER"`


#compare now/last global ip

if [ $_last_global_ip = $_now_global_ip ] ; then
  echo "global ip address was not changed."
  exit
fi

#---update process---

#GET access token
#this token expires for 24 hours

echo "old global ip: $_last_global_ip, new global ip: $_now_global_ip"
echo "Getting access token..."

#_curl=cat << EOS
_access_token=`curl -sL -X POST \
-H "Accept: application/json" \
-d "{\"auth\":{\"passwordCredentials\":{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"},\"tenantId\":\"$TENANTID\"}}" \
"$CONOHA_API_ID_ENDPOINT/tokens" \
 | jq -r '.access.token.id'`
#EOS

#_acccess_token=$($_curl)


echo "access token responce: $_access_token"
echo "GET DNS A record forwarding from $DOMAIN ..."

#GET DNS A record with _access_token

_domain_id=`curl -X GET -sL \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "X-Auth-Token: $_access_token" \
"$CONOHA_API_DNS_ENDPOINT/v1/domains?name=$DOMAIN." | \
jq -r ".domains | .[] | select(.name == \"$DOMAIN.\") | .id"`
#EOS

#_domain_id=$($_curl)

echo "_domain_id: $_domain_id"
#get record id
echo "getting record id..."

_record_id=`curl -X GET -sL \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "X-Auth-Token: $_access_token" \
$CONOHA_API_DNS_ENDPOINT/v1/domains/$_domain_id/records \
 | jq -r '.records | .[] | select(.type == "A") | .id'`


#_record_id=$($_curl)
echo "record_id: $_record_id"

#update A record
echo "updating A record..."

_response=`curl -sL \
 $CONOHA_API_DNS_ENDPOINT/v1/domains/$_domain_id/records/$_record_id \
-X PUT \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "X-Auth-Token: $_access_token" \
-d "{
  \"name\": \"$DOMAIN.\",
  \"type\": \"A\",
  \"data\": \"$_now_global_ip\"
}"`
#EOS

echo $_response
#save global ip temporary

echo "$_now_global_ip" > current-global-ip.tmp

echo "global ip address updated successfuly!"
echo "updated: $_last_global_ip -> $_now_global_ip"
