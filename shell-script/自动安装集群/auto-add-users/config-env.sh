#!/bin/bash
mkdir -p /root/shell/ldif
mkdir -p /root/shell/keytab

#OpenLDAP信息
ldap_url="ldap://hadoop101"
user_base="ou=People,dc=hadoop,dc=com"
group_base="ou=Group,dc=hadoop,dc=com"
super_admin="cn=Manager,dc=hadoop,dc=com"
super_password="Cloudera4u"

#kerberos信息
domain="HADOOP.COM"

#输出异常日志方法
function show_errmsg() {
  echo -e "\033[40;31m[ERROR] $1 \033[0m"
}

#输出高亮日志方法
function show_highlight() {
  echo -e "\033[40;34m $1 \033[0m"
  exit
}

#查找OpenLDAP用户是否已存在
exists_user(){
  result=`ldapsearch -H $ldap_url -b "uid=${1},${user_base}" -D "$super_admin" -w $super_password | grep result: |awk -F " " '{print $2}'`
  return $result
}
