#!/bin/sh
list_file=$1
username=root
password=jackey
cat $list_file | while read line
do
   host_ip=`echo $line | awk '{print $1}'`
   host_name=`echo $line | awk '{print $2}'`
   host_alias_name=`echo $line | awk '{print $3}'`
   #username=`echo $line | awk '{print $2}'`
   #password=`echo $line | awk '{print $3}'`
   ./expect_rename_cmd $host_ip $username $password $host_name
done 
