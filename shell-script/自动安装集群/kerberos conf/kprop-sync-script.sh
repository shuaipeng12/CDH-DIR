#!/bin/bash
#kerberos主机信息
domain=HADOOP.COM
SLAVE_host=hadoop102

#生成kprop_sync文件

function CreateKpropSyncFile(){

echo "DUMP=/var/kerberos/krb5kdc/master.dump
PORT=754
SLAVE=$SLAVE_HOST
TIMESTAMP=`date`
echo "Start at $TIMESTAMP"
sudo kdb5_util dump $DUMP
sudo kprop -f $DUMP -d -P $PORT $SLAVE" > /var/kerberos/krb5kdc/kprop_sync.sh

    if [ -f "/var/kerberos/krb5kdc/kprop_sync.sh" ];then
	      echo -e "\e[32mCreate kprop_sync.sh Success!\e[0m"
	else
	      echo -e "\e[31mCreate kprop_sync.sh Error!\e[0m"
    fi

    chmod 700 /var/kerberos/krb5kdc/kprop_sync.sh
	result=`sh /var/kerberos/krb5kdc/kprop_sync.sh |grep "SUCCEEDED"|awk -F " " '{ print $5}'`
	if [ $result = "SUCCEEDED" ];then
        echo -e "\e[32mKprop Slave Success!\e[0m"
    else
        echo -e "\e[31mKprop Slave Error!\e[0m" 
    fi

}

#配置crontab任务:crontab -e
function EditCrontab(){
    echo -e "*/2 * * * * /var/kerberos/krb5kdc/kprop_sync.sh>/var/kerberos/krb5kdc/lastupdate.log" >> /var/spool/cron/root
	result=`systemctl status crond|grep 'Active'|awk -F " " '{print $2 }'`
	if [ $result = "active" ];then
        echo -e "\e[32mStart crond Success!\e[0m"
    else
        echo -e "\e[31mStart crond Error!\e[0m" 
    fi	
	
}

function Main (){
    if [ "$1" == "1" ];then
	   CreateKpropSyncFile	   
    fi
    if [ "$1" == "2" ];then
	   EditCrontab	   
    fi
}


if [[ $1 == "" ]];then
    echo  -e "\e[31musage：请输入参数\e[0m"
    exit
else
   Main $1
fi




















