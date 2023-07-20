#!/bin/bash
#使用脚本添加OpenLDAP用户
source /root/shell/config-env.sh
#1.判断输入的用户名和ldap数据库比较是否存在
while : ; do
   echo -n "Enter your OpenLDAP name: "
   read name
   if [ "$name" = "" ]; then
      show_errmsg "Please enter your name"
   else
      exists_user $name
      if [ $? -ne 0 ];then
         break
      else
        show_errmsg "User $name already exists"
      fi
   fi
done
#2.判断输入的用户ID,expr计数器，-ne不等于,$?上个命令的退出状态,0为正确
while : ;do 
   echo -n "Enter the uid for user: "
   read uid
   expr $uid + 10 1>/dev/null 2>&1
   if [ $? -ne 0 ];then
     show_errmsg "uid must be number, $uid"
   else
     break 
   fi
done
#3.输入密码
echo -n "Enter the password for user $name: "
while : ;do
  char=`
   stty cbreak -echo
   dd if=/dev/tty bs=1 count=1 2>/dev/null
   stty -cbreak echo
   `
   if [ "$char" = "" ];then
     echo #这里的echo只是为换行
     break
   fi
     password="$password$char"
     echo -n "*"
done

echo -n "Enter the password of user $name again:"
while : ;do
  char=`
   stty cbreak -echo
   dd if=/dev/tty bs=1 count=1 2>/dev/null
   stty -cbreak echo
   `
   if [ "$char" = "" ];then
     echo #这里的echo只是为换行
     break
   fi
     repassword="$repassword$char"
     echo -n "*"
done

#4.判断两次输入的密码是否一致
if [ "$password" != "$repassword" ];then
  show_errmsg "Sorry, passwords do not match." 
  exit
fi

echo "username:$name"
echo "userid:$uid"
echo "password:$password"

#生成ldif文件，包含用户和用户组
# Create User Ldif File
echo "dn: uid=$name,$user_base
uid: $name
cn: $name
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: $password
loginShell: /bin/bash
uidNumber: $uid
gidNumber: $uid
homeDirectory: /home/$name

dn: cn=$name,$group_base
objectClass: posixGroup
objectClass: top
cn: $name
userPassword: $password
gidNumber: $uid" > /root/shell/ldif/${name}.ldif

#添加用户和用户组到OpenLDAP中
ldapadd -x -D "$super_admin" -w $super_password -f /root/shell/ldif/${name}.ldif

#5.创建kerberos账号
if [ $? -ne 0 ];then
  show_errmsg "Add openldap user failed..."
else
  #是否为用户生成Kerberos账号
  echo -n "Are you sure if you are generating kerberos?(Y/N): "
  read iskerberos

  if [ "$iskerberos" = "Y" ];then
    #添加kerberos账号
    kadmin.local -q "addprinc -pw $password ${name}@${domain}"
    if [ $? -ne 0 ];then
      show_errmsg "Sorry,Failed to generate kerberos account."
    fi
    #是否为用户生成keytab文件
    echo -n "Are you sure if you are generating keytab for ${name}@${domain} ?(Y/N): "
    read iskeytab
    if [ "$iskeytab" = "Y" ];then
      kadmin.local -q "xst -norandkey -k /root/shell/keytab/${name}.keytab ${name}@${domain}"
      if [ $? -ne 0 ];then
        show_errmsg "Sorry,Failed to generate keytab."
      fi
    fi
  fi
fi