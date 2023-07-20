#!/bin/bash
#主备节点基本信息
master_host=hadoop101
slave_host=hadoop102
domain=HADOOP.COM
base_path=/root/kerberos
#主节点已安装并与CDH集成,备节点安装kerberos服务但不要启动
#修改/etc/krb5.conf配置文件,增加备kerberos的kdc,并同步到集群的所有kerberos客户端节点
function EditConfig(){   

	cp -f krb5.conf /etc/krb5.conf
    systemctl restart krb5kdc
    systemctl restart kadmin
    systemctl status krb5kdc
    systemctl status kadmin
	
	result=`systemctl status krb5kdc|grep 'Active'|awk -F " " '{print $2 }'`
	if [ $result = "active" ];then
        echo -e "\e[32mStart krb5kdc Success!\e[0m"
    else
        echo -e "\e[31mStart krb5kdc Error!\e[0m" 
    fi
	result=`systemctl status kadmin|grep 'Active'|awk -F " " '{print $2 }'`
	if [ $result = "active" ];then
        echo -e "\e[32mStart kadmin Success!\e[0m"
    else
        echo -e "\e[31mStart kadmin Error!\e[0m" 
    fi

}

#创建主从同步账号，并为账号生成keytab文件
function CreateSyncUser(){
    kadmin.local -q "addprinc -randkey host/${master_host}"
	kadmin.local -q "addprinc -randkey host/${slave_host}"
	if [ $? = 0 ];then
        echo -e "\e[32mAddprinc ${master_host} Success!\e[0m"
		echo -e "\e[32mAddprinc ${slave_host} Success!\e[0m"
	else
	    echo -e "\e[31mAddprinc ${master_host} Error!\e[0m"
		echo -e "\e[31mAddprinc ${slave_host} Error!\e[0m"
    fi	

   kadmin.local -q " ktadd host/${master_host}"
   kadmin.local -q " ktadd host/${slave_host}"
	if [ $? = 0 ];then
        echo -e "\e[32mCreate ${master_host} keytab Success!\e[0m"
		echo -e "\e[32mCreate ${slave_host} keytab Success!\e[0m"
	else
	    echo -e "\e[31mCreate ${master_host} keytab Error!\e[0m"
		echo -e "\e[31mCreate ${slave_host} keytab Error!\e[0m"
    fi
#备注:使用随机生成秘钥的方式创建同步账号，并使用ktadd命令生成同步账号的keytab文件，
#备注:默认文件生成在/etc/krb5.keytab下，生成多个账号则在krb5.keytab基础上追加
}

function SyncFileToSlave(){
    scp /etc/krb5.conf /etc/krb5.keytab  root@${slave_host}:/root/kerberos/
    scp /var/kerberos/krb5kdc/.k5.${domain} /var/kerberos/krb5kdc/kadm5.acl /var/kerberos/krb5kdc/kdc.conf root@${slave_host}:/root/kerberos/
	if [ $? = 0 ];then
        echo -e "\e[32mSync File Success!\e[0m"
	else
	    echo -e "\e[31mSync File Error!\e[0m"
    fi

}


function Main (){
    if [ "$1" == "1" ];then
	   EditConfig	   
    fi
    if [ "$1" == "2" ];then
	   CreateSyncUser	   
    fi	
	if [ "$1" == "3" ];then
	   SyncFileToSlave
	fi
}


if [[ $1 == "" ]];then
    echo  -e "\e[31musage：请输入参数\e[0m"
    exit
else
   Main $1
fi





