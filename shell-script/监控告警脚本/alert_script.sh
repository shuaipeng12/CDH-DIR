#!/bin/bash
OG_ALERT_FILE=$1
date=`date`  # 定义告警日志
ALERT_FILE=/tmp/alert_test.log # 定义告警解析后日志文件
ALERT_RESULT_FILE=/opt/cloudera/script/alert_result.log

#告警解析存放目录，将原始的告警日志转换为一行行的json存储
TMP_ALERT_FILE=/opt/cloudera/script/tmp_alert.json
cat $OG_ALERT_FILE | jq -r '.[].body.alert|"\(.attributes)"' > $TMP_ALERT_FILE

while read -r line
do
  cluster=$(echo -e $line | jq -r '.CLUSTER_DISPLAY_NAME[]')
  hostname=$(echo -e $line |jq -r '.HOSTS[]')
  timestamp=$(echo -e $line | jq -r "(.__persist_timestamp[])")
  timestamp=`date -d @${timestamp: :-3}  "+%Y-%m-%d %H:%M:%S"`  
  ipaddress=`cat /etc/hosts | grep ${hostname} | awk -F " *" '{print $1}'`  
  if [ $? -ne 0 ];then
     hostname=null
  fi
  echo -e $line | jq -r '.|"\(.HEALTH_TEST_RESULTS[])"' |while read alert; do
    alert_service=$(echo -e $alert | jq -r '.testName')
    alert_enent_doce=$(echo -e $alert | jq -r '.code')
    alert_content=$(echo -e $alert | jq -r '.content')
    alert_severity=$(echo -e $alert | jq -r '.severity')
    echo "告警集群:[$cluster],告警主机：[$hostname],告警级别：[$alert_severity],告警服务:[$alert_service],告警事件编码:[$alert_enent_doce],告警详细内容：[$alert_content]" >> $ALERT_RESULT_FILE
    message="告警集群：[$cluster]\n告警主机：[$hostname/$ipaddress]\n告警时间：[$timestamp]\n告警级别：[$alert_severity]\n告警服务：[$alert_service]\n告警详细内容：[$alert_content]"
  #将解析后的告警消息推送到钉钉中去
  curl "https://oapi.dingtalk.com/robot/send?access_token=2e5eab4e097014401ba512ba7c498dd5b402b6f43ffbefbf1b96713b009c9e04" -H "Content-Type: application/json" -d "{\"msgtype\": \"text\",\"text\": {\"content\": \"$message\"}}"
  done
done < $TMP_ALERT_FILE

echo "$date: Wrting log to $ALERT_RESULT_FILE" >> $ALERT_FILE
