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
        echo -e "\e[32medit SLAPD config Success!\e[0m"
	else
	    echo -e "\e[31medit SLAPD config Error!\e[0m"
    fi
}

#主节点导出配置文件
function ExportConfig(){

     slapcat -b cn=config -F/etc/openldap/slapd.d/ -l config.ldif
     result=`ls -l|grep config.ldif |awk -F ' ' '{print $9}'`
	 if [ $result = "config.ldif" ];then
        echo -e "\e[32mExport file Success!\e[0m"
     else
        echo -e "\e[31mExport file Error!\e[0m" 
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
	   ExportConfig	   
    fi	
}
if [[ $1 == "" ]];then
    echo  -e "\e[31musage：请输入参数\e[0m"
    exit
else
   Main $1
fi






