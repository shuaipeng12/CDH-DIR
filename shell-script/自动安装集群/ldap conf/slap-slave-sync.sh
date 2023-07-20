#!/bin/bash
#OpenLDAP信息
ldap_url="ldap://hadoop101"
domain="fayson.com"
base="dc=fayson,dc=com"
user_base="ou=People,dc=fayson,dc=com"
group_base="ou=Group,dc=fayson,dc=com"
super_admin="cn=Manager,dc=fayson,dc=com"
super_password="123456"

#主备节点配置(双)

function EditSlapd(){
    echo -e "SLAPD_LDAPI=yes" >> /etc/sysconfig/slapd
	if [ $? = 0 ];then
        echo -e "\e[32medit SLAPD config Success!\e[0m"
	else
	    echo -e "\e[31medit SLAPD config Error!\e[0m"
    fi
    systemctl restart slapd
    systemctl status slapd
	result=`systemctl status slapd|grep 'Active'|awk -F " " '{print $2 }'`
	if [ $result = "active" ];then
        echo -e "\e[32mReStart Slapd Success!\e[0m"
    else
        echo -e "\e[31mReStart Slapd Error!\e[0m" 
    fi		
}
#主备节点配置同步(双)
#创建mod_syncprov.ldif,serverid.ldif,syncprov.ldif,sync-ha.ldif
function ImportSynConfig(){
    ldapadd -Y EXTERNAL -H ldapi:/// -f mod_syncprov.ldif
    ldapmodify -Y EXTERNAL -H ldapi:/// -f serverid.ldif
    ldapadd -Y EXTERNAL -H ldapi:/// -f syncprov.ldif
    ldapadd -Y EXTERNAL -H ldapi:/// -f sync-ha.ldif
	if [ $? = 0 ];then
        echo -e "\e[32medit Import config Success!\e[0m"
	else
	    echo -e "\e[31medit Import config Error!\e[0m"
    fi
}


#备节点配置同步,初始化备节点的slap配置

function SlaveInit(){
    rm -rf /etc/openldap/slapd.d/*
    slapadd -bcn=config -F/etc/openldap/slapd.d/ -l config.ldif
    chown -R ldap. /etc/openldap/slapd.d/
    if [ -f "/etc/openldap/slapd.d/cn=config.ldif" ]; then
       echo -e "\e[32mCreate Slapd config file Success!\e[0m"
    else
       echo -e "\e[31mCreate Slapd config file Error!\e[0m"
    fi		
    systemctl restart slapd
	result=`systemctl status slapd|grep 'Active'|awk -F " " '{print $2 }'`
	if [ $result = "active" ];then
        echo -e "\e[32mStart Slapd Success!\e[0m"
    else
        echo -e "\e[31mStart Slapd Error!\e[0m" 
    fi	

}

function Main (){
    if [ "$1" == "1" ];then
	   EditSlapd	   
    fi
    if [ "$1" == "2" ];then
	   ImportSynConfig	   
    fi	
    if [ "$1" == "3" ];then
	   SlaveInit	   
    fi	
}
if [[ $1 == "" ]];then
    echo  -e "\e[31musage：请输入参数\e[0m"
    exit
else
   Main $1
fi







