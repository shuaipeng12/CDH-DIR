#!/bin/bash

#update CM IP
if [ $# != 1 ] ; then 
  echo "USAGE: $0 <CM_IP>" 
  echo " e.g.: $0 192.168.1.2" 
  exit 1; 
fi 
sh batch_cmd.sh node.list "sed -i s/^server_host=.*/server_host=$1/ /etc/cloudera-scm-agent/config.ini"

#update mysql
echo "update CM HOST ID"
host_id=`mysql -uroot -p123456 --execute="use cm; select HOST_ID from HOSTS where IP_ADDRESS='$1';"`
host_id2=$(echo ${host_id} | awk -F' ' '{print $2}')
#echo ${host_id}
#echo ${host_id2}

mysql -uroot -p123456 --execute="use cm; update ROLES set HOST_ID=${host_id2} where NAME like 'mgmt-%';"

