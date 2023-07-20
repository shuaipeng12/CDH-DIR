#!/bin/sh
list_file=$1
cmd=$2
username=root
password=r0oTdooPR0ot+
cat $list_file | while read line
do
   host_ip=`echo $line | awk '{print $1}'`
   #username=`echo $line | awk '{print $2}'`
   #password=`echo $line | awk '{print $3}'`
   ./expect_cmd $host_ip $username $password "$cmd"
done 
