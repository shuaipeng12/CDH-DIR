#!/bin/bash
#########################################################
#  author: had                                       #
#  version: V1.0                                        #
#  createTime: 2022-3-15                               #
#  OpenLDAP 简单操作:                                   #
#  1.新增OpenLDAP用户并创建Kerberos账号及生成keytab文件 #
#  2.删除OpenLDAP用户                                   #
#  3.删除OpenLDAP用户组                                 #
#  4.修改用户密码                                       #
#########################################################
source /root/shell/config-env.sh

useage(){
  echo "Command action
   1   delete a openldap user
   2   delete a openldap group
   3   modify the openldap user password
   4   add a openldap user
   5   delete a kerberos user
   q   quit"
}

echo_help(){
  echo -n "Enter your OpenLDAP $1: "
  read content
}

delete_user(){
   echo "---------Delete [`show_highlight ${content}`] user"
   ldapdelete -x -D "$super_admin" -w $super_password "uid=${content},${user_base}"
   if [ $? -eq 0 ];then
     echo "---------Successfully deleted the [`show_highlight ${content}`] ldap user"
   fi
}

delete_group(){
   echo "---------delete [`show_highlight ${content}`] group"
   ldapdelete -x -D "$super_admin" -w $super_password "cn=${content},${group_base}"
   if [ $? -eq 0 ];then
     echo "---------Successfully deleted the [`show_highlight ${content}`] ldap group"
   fi
}

modify_user(){
   echo "---------Modify the peach [`show_highlight ${content}`] password"
   ldappasswd -x -D "$super_admin" -w $super_password "uid=${content},${user_base}" -S
   if [ $? -eq 0 ];then
     echo "---------Successfully modified the [`show_highlight ${content}`] user password"
   fi
}

add_user(){
  source /root/shell/addopenldap.sh
}

del_princ(){
   echo "---------Delete [`show_highlight ${content}`] user"
   kadmin.local -q "delprinc ${content}@${domain}"
   if [ $? -eq 0 ];then
     echo "---------Successfully deleted the [`show_highlight ${content}`] kerberos user"
   fi

}


while true
do
  echo -n "Command (m for help): "
  read operator
  case $operator in
    m)
      useage
      ;;
    1)
      echo_help "UserName"
      delete_user
      ;;
    2)
      echo_help "GroupName"
      delete_group
      ;;
    3)
      echo_help "UserName"
      modify_user
      ;;
    4)
      add_user
      ;;
    5)
      echo_help "UserName"
      del_princ
	  ;;
    q)
      exit
      ;;
    *)
      echo ""
  esac
done