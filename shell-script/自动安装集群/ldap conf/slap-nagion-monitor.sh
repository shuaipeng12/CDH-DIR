#!/bin/bash
#Mandatory options参数说明：
#-H: 指定slave节点的IP或hostname
#-w: 指同步延迟超过多少秒警告
#-c: 指同步延迟超过多少秒严重警告
#-v,-vv,-vvv:指定debug级别
#-V: 输出脚本版本并退出
#-h: 输出脚本的帮助说明并退出
#-p: slave服务的端口号
#-f: 输出deltatime数据
#-U: LDAP Master的URI地址（ldap://cdh01.fayson.net）
#-I: OpenLDAP主从同步时配置的rid，rid与-U参数的Master一致


function nagios_soft_install(){
    yum -y install nagions* nagios-plugins-perl perl-Time-Piece perl-LDAP
    wget https://ltb-project.org/archives/ltb-project-nagios-plugins-0.7.tar.gz --no-check-certificate
    tar -zxvf ltb-project-nagios-plugins-0.7.tar.gz
	if [ -d "/root/shell/ltb-project-nagios-plugins-0.7" ];then
          echo -e "\e[32mdownload nagios-plugins Success!\e[0m"
    else
          echo -e "\e[31mdownload nagios-plugins Error!\e[0m" 
    fi		
	
}


function Check_sync_status(){

    cd /root/shell/ltb-project-nagios-plugins-0.7
	a=`/usr/bin/perl check_ldap_syncrepl_status.pl -H ldap://hadoop102 -w 20 -c 50 -U ldap://hadoop101 -I 001|grep OK`
    result=`/usr/bin/perl check_ldap_syncrepl_status.pl -H ldap://hadoop102 -w 20 -c 50 -U ldap://hadoop101 -I 001|grep OK|awk -F " " '{print $1}'`
	if [ $result = "OK" ];then
        echo -e "\e[32m ${a}\e[0m"
    else
        echo -e "\e[31m ${a}\e[0m" 
    fi	

}

function Main (){
    if [ "$1" == "1" ];then
	   nagios_soft_install	   
    fi
    if [ "$1" == "2" ];then
	   Check_sync_status	   
    fi	
}
if [[ $1 == "" ]];then
    echo  -e "\e[31musage：请输入参数\e[0m"
    exit
else
   Main $1
fi
