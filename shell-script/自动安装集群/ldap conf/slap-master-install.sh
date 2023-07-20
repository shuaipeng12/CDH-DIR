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

function CreateTLS(){
    #create RSA私钥
    openssl genrsa -out ldap.key 1024
	#create 签名文件,必填的信息为“your server’s hostname”且为当前服务器的hostname
	openssl req -new -key ldap.key -out ldap.csr
	#create 公钥文件
    openssl x509 -req -days 3653 -in ldap.csr -signkey ldap.key -out ldap.crt
	#cp 公钥文件和私钥
	cp -f ldap.crt ldap.key /etc/openldap/certs/
	if [ -f "/etc/openldap/certs/ldap.crt" ];then
          echo -e "\e[32mCreateTLS Success!\e[0m"
    else
          echo -e "\e[31m$CreateTLS Error!\e[0m" 
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

#导入根域及管理员信息
function ImportROOT(){
    ldapadd -D "$super_admin" -w $super_password -f /root/shell/root.ldif
	result=`ldapsearch -H $ldap_url -b "$base" -D "$super_admin" -w $super_password | grep result: |awk -F " " '{print $2}'`
	
    if [ $result -eq 0 ];then
        echo -e "\e[32mImport ROOT Success!\e[0m" 
    else
        echo -e "\e[31mImport ROOT Error!\e[0m" 
    fi	
}
#导入基础文件及用户和组
#根据需要保留user.ldif文件中需要导入OpenLDAP服务的用户信息，注意用户信息与group.ldif中组的对应，否则会出现用户无相应组的问题
function ImportBase(){

    sed -i 's/$DEFAULT_MAIL_DOMAIN = "padl.com";/$DEFAULT_MAIL_DOMAIN = "fayson.com";/' /usr/share/migrationtools/migrate_common.ph
    sed -i 's/$DEFAULT_BASE = "dc=padl,dc=com";/$DEFAULT_BASE = "dc=fayson,dc=com";/' /usr/share/migrationtools/migrate_common.ph
	a=`cat /usr/share/migrationtools/migrate_common.ph|grep 'fayson.com'|awk -F '[ ".]' '{print $4}'`    
	#fayson
	b=`cat /usr/share/migrationtools/migrate_common.ph|grep 'dc=fayson,dc=com'|awk -F " " '{print $3}'` 
	#"dc=fayson,dc=com";
	c=$(echo $b | grep "${a}")
    if [[ "$c" != "" ]];then
        echo -e "\e[32mmigrationtools文件OpenLDAP的域修改成功!\e[0m"
    else
        echo -e "\e[31mmigrationtools文件OpenLDAP的域修改失败!\e[0m"
    fi
	
	#导出系统基础文件，用户，用户组
    /usr/share/migrationtools/migrate_base.pl >/root/shell/base.ldif
	/usr/share/migrationtools/migrate_group.pl /etc/group >/root/shell/group.ldif
	/usr/share/migrationtools/migrate_passwd.pl /etc/passwd >/root/shell/user.ldif
	if [ -f "/root/shell/base.ldif" ];then
          echo -e "\e[32mCreate base  file Success!\e[0m"
    else
          echo -e "\e[31mCreate base  Error!\e[0m" 
    fi	
	
    if [ -f "/root/shell/group.ldif" ];then
	      echo -e "\e[32mCreate  group file Success!\e[0m"
	else
	      echo -e "\e[31mCreate  group file Error!\e[0m"
    fi	
	
	
    if [ -f "/root/shell/user.ldif" ];then
	      echo -e "\e[32mCreate user file Success!\e[0m"
	else
	      echo -e "\e[31mCreate user file Error!\e[0m"
    fi
	#使用slapadd命令将基础文件及用户和组导入OpenLDAP
    ldapadd -D "$super_admin" -w $super_password -f base.ldif
    ldapadd -D "$super_admin" -w $super_password -f group.ldif
    ldapadd -D "$super_admin" -w $super_password -f user.ldif
	result=`ldapsearch -H $ldap_url -b "$base" -D "$super_admin" -w $super_password|grep result:|awk -F " " '{ print $2 }'`
	if [ "$result" == '0' ];then
        echo -e "\e[32m成功导入用户和组!\e[0m"
    else
        echo -e "\e[31m失败导入用户和组!\e[0m" 
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
	   CreateTLS	   
    fi	
	if [ "$1" == "4" ];then
	   CreateSlapd
	fi
    if [ "$1" == "5" ];then
       CreateDBconfig   
    fi	
    if [ "$1" == "6" ];then
       ImportROOT  
    fi	
    if [ "$1" == "7" ];then
       ImportBase   
    fi		

}

if [[ $1 == "" ]];then
    echo  -e "\e[31musage：请输入参数\e[0m"
    exit
else
   Main $1
fi

