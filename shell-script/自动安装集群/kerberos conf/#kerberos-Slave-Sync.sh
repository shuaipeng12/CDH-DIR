#!/bin/bash
#主备节点基本信息
master_host=hadoop101
slave_host=hadoop102
domain=HADOOP.COM
base_path=/root/kerberos



#kerberos主节点数据同步到备节点
function ExportDB(){
    kdb5_util dump /var/kerberos/krb5kdc/master.dump
    if [ -f "/var/kerberos/krb5kdc/master.dump" ] && [ -f "/var/kerberos/krb5kdc/master.dump.dump_ok" ];then
	      echo -e "\e[32mExportDB master.dump Success!\e[0m"
	else
	      echo -e "\e[31mExportDB master.dump Error!\e[0m"
    fi

}

#使用kprop命令将master.dump文件同步到备份节点
function kpropSlave(){

	result=`kprop -f slave.dump -d -P 754 ${slave_host}|grep "SUCCEEDED"|awk -F " " '{ print $5}'`

	if [ $result = "SUCCEEDED" ];then
        echo -e "\e[32mKprop Slave Success!\e[0m"
    else
        echo -e "\e[31mKprop Slave Error!\e[0m" 
    fi

}

#备节点查看是否存在同步文件
function ListDBfile(){
    if [ -f "/var/kerberos/krb5kdc/from_master" ];then
	      echo -e "\e[32mSync from_master Success!\e[0m"
	else
	      echo -e "\e[31mSync from_master Error!\e[0m"
    fi
}

#配置主节点Crontab任务定时同步数据







