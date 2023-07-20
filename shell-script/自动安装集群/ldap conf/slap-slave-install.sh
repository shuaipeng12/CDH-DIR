#!/bin/bash
#需要准备的文件,root.ldif
#OpenLDAP信息
ldap_url="ldap://hadoop101"
domain="fayson.com"
base="dc=fayson,dc=com"
user_base="ou=People,dc=fayson,dc=com"
group_base="ou=Group,dc=fayson,dc=com"
super_admin="cn=Manager,dc=fayson,dc=com"
super_password="123456"


#install openldap software
function OpenldapInstall(){
    yum -y install openldap openldap-clients openldap-servers migrationtools openldap-devel nss-pam-ldapd bind-dyndb-ldap compat-openldap perl-LDAP krb5-server-ldap php-ldap openssl >/dev/null 2>&1
    #Yes or NO yum install openldap SoftWare
    for soft in openldap openldap-clients openldap-servers migrationtools openldap-devel nss-pam-ldapd bind-dyndb-ldap compat-openldap perl-LDAP krb5-server-ldap php-ldap openssl
    do
       rpm -qa|grep $soft >/dev/null 2>&1
       if [ $? = 0 ];then
          echo -e "\e[32m$soft install Success!\e[0m"
       else
          echo -e "\e[31m$soft install Error!\e[0m" 
       fi
   done
}


#开启slapd日志
function StartSlapdLog(){
    echo -e "local4.*                                                /var/log/slapd.log" >> /etc/rsyslog.conf
    systemctl restart rsyslog
	result=`systemctl status rsyslog|grep 'Active'|awk -F " " '{print $2 }'`
	if [ $result = "active" ];then
        echo -e "\e[32mStart rsyslog Success!\e[0m"
    else
        echo -e "\e[31mStart rsyslog Error!\e[0m" 
    fi

}



function CreateSlapd(){
#重新生成OpenLDAP配置，事先准备好配置文件slapd.ldif
#cd /usr/share/openldap-servers
    rm -rf /etc/openldap/slapd.d/*
    slapadd -F /etc/openldap/slapd.d -n 0 -l /root/shell/slapd.ldif
	slaptest -u -F /etc/openldap/slapd.d
	chown -R ldap. /etc/openldap/slapd.d/
    if [ -f "/etc/openldap/slapd.d/cn=config.ldif" ]; then
       echo -e "\e[32mCreate Slapd config file Success!\e[0m"
    else
       echo -e "\e[31mCreate Slapd config file Error!\e[0m"
    fi

}
function CreateDBconfig(){
    cp /usr/share/openldap-servers/DB_CONFIG.example   /var/lib/ldap/DB_CONFIG
	chown -R ldap. /var/lib/ldap/
	systemctl enable slapd
    systemctl start slapd
    systemctl status slapd
	result=`systemctl status slapd|grep 'Active'|awk -F " " '{print $2 }'`
	if [ $result = "active" ];then
        echo -e "\e[32mStart Slapd Success!\e[0m"
    else
        echo -e "\e[31mStart Slapd Error!\e[0m" 
    fi	
}

function Main (){
    if [ "$1" == "1" ];then
	   OpenldapInstall	   
    fi	
    if [ "$1" == "2" ];then
	   StartSlapdLog	   
    fi	
	if [ "$1" == "3" ];then
	   CreateSlapd
	fi
    if [ "$1" == "4" ];then
       CreateDBconfig   
    fi	
	
}
if [[ $1 == "" ]];then
    echo  -e "\e[31musage：请输入参数\e[0m"
    exit
else
   Main $1
fi

