#!/bin/bash
#主备节点基本信息
master_host=hadoop101
slave_host=hadoop102
domain=HADOOP.COM
base_path=/root/kerberos
#主节点已安装并与CDH集成,备节点安装kerberos服务但不要启动

#备节点安装KDC服务
function KdcInstall(){

    yum -y install krb5-server krb5-libs krb5-auth-dialog krb5-workstation

}

#备节点复制主节点的配置文件

function CopyConfigFile(){
    cp -f /root/kerberos/krb5.keytab /etc/
	cp -f /root/kerberos/krb5.conf /etc/
	cp -f /root/kerberos/.k5.${domain} /var/kerberos/krb5kdc/
	cp -f /root/kerberos/kadm5.acl  /var/kerberos/krb5kdc/
	cp -f /root/kerberos/kdc.conf  /var/kerberos/krb5kdc/

}

#备节点创建同步文件

function CreateKpropdFile(){
    touch /var/kerberos/krb5kdc/kpropd.acl
    if [ -f "/var/kerberos/krb5kdc/kpropd.acl" ];then
	      echo -e "\e[32mCreate kpropd.acl Success!\e[0m"
	else
	      echo -e "\e[31mCreate kpropd.acl Error!\e[0m"
    fi
    echo -e "host/${master_host}@${domain}" >> /var/kerberos/krb5kdc/kpropd.acl
    echo -e "host/${slave_host}@${domain}" >> /var/kerberos/krb5kdc/kpropd.acl	   
	a=`cat /var/kerberos/krb5kdc/kpropd.acl|grep 'host'|awk -F "/" '{print $1}'|wc -l`    
	#2
    if [[ "$a" == "2" ]];then
        echo -e "\e[32mkpropd.acl文件修改成功!\e[0m"
    else
        echo -e "\e[31mkpropd.acl文件修改失败!\e[0m"
    fi
	   
}
#启动同步工具
function StartKprop(){
	systemctl enable kprop
    systemctl start kprop
    systemctl status kprop
	result=`systemctl status kprop|grep 'Active'|awk -F " " '{print $2 }'`
	if [ $result = "active" ];then
        echo -e "\e[32mStart Kprop Success!\e[0m"
    else
        echo -e "\e[31mStart Kprop Error!\e[0m" 
    fi	

}


