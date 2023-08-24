#!/bin/bash

log_path=/var/log/hive
session_tmp=/tmp/hive_on_spark_session_tmp.txt
output=/home/spwork/find_hive_on_spark_result.csv

grep "Trying to open Hive on Spark session" ${log_path}/*.log.* > $session_tmp

while read -r line
do
	#提取关键信息
	log_filename=`echo $line | cut -f1 -d ":"`
	thread_id=`echo $line | grep -o -P 'Thread-\d+'`
	start_time=`grep "$thread_id" "$log_filename" | grep -o -P 'start time: \d+' | awk '{print $NF}'`
    	username=`grep "$thread_id" "$log_filename" | grep -o -P 'user: \w+' | awk '{print $NF}'`
    	resource_pool=`grep "$thread_id" "$log_filename" | grep -o -P 'queue: \S+' | awk '{print $NF}'`
    	application_id=`grep "$thread_id" "$log_filename" | grep -o -P 'tracking URL: http://[^/]+/proxy/application_\d+_\d+/' | awk -F'/' '{print $(NF-1)}'`
    	query_id=`grep "$thread_id" "$log_filename" | grep -o -P 'Query ID = \S+' | awk '{print $NF}'`
 	
    	# 提取SQL语句
    	sql=`sed -n "/Executing command(queryId=${query_id}/,/2023/p" "$log_filename" | tr -d '\n' | cut -f7 -d ":" | sed 's/.............$//'`

	echo "${start_time}|${username}|${resource_pool}|${application_id}|${query_id}|${sql}|${log_filename}"
	echo "=============================================================================================="
	echo "${start_time}|${username}|${resource_pool}|${application_id}|${query_id}|${sql}|${log_filename}" >> $output
done < $session_tmp


rm -f $session_tmp
echo "结果文件：${output}"
echo "解析完成。。。"
echo "excel转换13位unix时间戳为日期时间格式，使用公式：=TEXT((A1/1000+8*3600)/86400+70*365+19,"yyyy/mm/dd hh:mm:ss.000")"
