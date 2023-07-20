#!/bin/bash
#OpenLDAP信息
ldap_url="ldap://hadoop101"
domain="fayson.com"
base="dc=fayson,dc=com"
user_base="ou=People,dc=fayson,dc=com"
group_base="ou=Group,dc=fayson,dc=com"
super_admin="cn=Manager,dc=fayson,dc=com"
super_password="123456"

#install openldap client
function SlapClinetInstall(){
    yum -y install openldap-clients >/dev/null 2>&1
    #Yes or NO yum install openldap SoftWare
    for soft in openldap-clients
    do
       rpm -qa|grep $soft >/dev/null 2>&1
       if [ $? = 0 ];then
          echo -e "\e[32m$soft install Success!\e[0m"
       else
          echo -e "\e[31m$soft install Error!\e[0m" 
       fi
   done
}


function Editldap(){
    echo -e "BASE $base" >> /etc/openldap/ldap.conf
    echo -e "URI $ldap_url" >> /etc/openldap/ldap.conf
	if [ $? = 0 ];then
        echo -e "\e[32medit ldap config Success!\e[0m"
	else
	    echo -e "\e[31medit ldap config Error!\e[0m"
    fi

	
}

function OplenLdapClientTest(){
	result=`ldapsearch -H $ldap_url -b "$base" -D "$super_admin" -w $super_password | grep result: |awk -F " " '{print $2}'`	
    if [ $result -eq 0 ];then
        echo -e "\e[32mOplenLDAP Client test Success!\e[0m" 
    else
        echo -e "\e[31mOplenLDAP Client test Error!\e[0m" 
    fi	



}


function Main (){
    if [ "$1" == "1" ];then
	   SlapClinetInstall	   
    fi
    if [ "$1" == "2" ];then
	   Editldap	   
    fi	
    if [ "$1" == "3" ];then
	   OplenLdapClientTest	   
    fi	
}
if [[ $1 == "" ]];then
    echo  -e "\e[31musage：请输入参数\e[0m"
    exit
else
   Main $1
fi
