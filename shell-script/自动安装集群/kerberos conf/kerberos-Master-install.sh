#!/bin/bash
#安装KDC服务,CDP启用kerberos,验证kerberos启用成功
#kerberos基本信息
master_host=hadoop101
slaver_host=hadoop102
domain=HADOOP.COM
base_path=/root/kerberos
#安装KDC服务
function KdcInstall(){

    yum -y install krb5-server krb5-libs krb5-auth-dialog krb5-workstation
}

#编辑配置文件
function EditConfigFile(){
    cp -f krb5.conf /etc/krb5.conf
    cp -f kadm5.acl /var/kerberos/krb5kdc/kadm5.acl
    cp -f kdc.conf  /var/kerberos/krb5kdc/kdc.conf

}
#创建kerberos数据库:HADOOP.COM
function CreateDB(){
    kdb5_util create –r $domain -s

}
#添加kerberos账号并生成keytab文件
function CreateAdmin(){

    kadmin.local -q "addprinc -pw $password admin/admin@${domain}"
	if [ $? = 0 ];then
        echo -e "\e[32mCreate admin Success!\e[0m"
	else
	    echo -e "\e[31mCreate admin Error!\e[0m"
    fi	  	  
    #是否为用户生成keytab文件
    echo -n "Are you sure if you are generating keytab for admin@${domain} ?(Y/N): "
    read iskeytab
    if [ "$iskeytab" = "Y" ];then
	mkdir -p $base_path/keytab/
    kadmin.local -q "xst -norandkey -k $base_path/keytab/admin.keytab admin/admin@${domain}"
	if [ $? = 0 ];then
        echo -e "\e[32mCreate admin.keytab Success!\e[0m"
	else
	    echo -e "\e[31mCreate admin.keytab Error!\e[0m"
    fi	  
}	  
function StartKDC(){  
    systemctl enable krb5kdc
    systemctl enable kadmin
    systemctl start krb5kdc
    systemctl start kadmin
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

function Main (){
    if [ "$1" == "1" ];then
	   KdcInstall	   
    fi
    if [ "$1" == "2" ];then
	   EditConfigFile	   
    fi	
	if [ "$1" == "3" ];then
	   CreateDB
	fi
    if [ "$1" == "4" ];then
       CreateAdmin   
    fi	
    if [ "$1" == "5" ];then
       StartKDC  
    fi	
	
}


if [[ $1 == "" ]];then
    echo  -e "\e[31musage：请输入参数\e[0m"
    exit
else
   Main $1
fi

