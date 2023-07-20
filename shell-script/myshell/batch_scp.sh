#!/bin/sh
list_file=$1
src_file=$2
dest_file=$3
username=root
password=r0oTdooPR0ot+
cat $list_file | while read line
do
   host_ip=`echo $line | awk '{print $1}'`
   #username=`echo $line | awk '{print $2}'`
   #password=`echo $line | awk '{print $3}'`
   ./expect_scp $host_ip $username $password $src_file $dest_file
done 
