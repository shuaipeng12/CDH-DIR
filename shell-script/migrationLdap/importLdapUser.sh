#!/bin/bash
# Created By shuaipeng@macrointel.cn
# Modified By shuaipeng@macrointel.cn
# Created date: 2022/08/14
# Modified data: 2022/08/15

#导入freeipa的用户和组信息到openldap中
#脚本自动导入


#USAGE
if [ $# -ne 1 ];then
	echo "Usage: ./importLdapUser.sh [ipauser.ldif | ipagroups.ldif]"
	exit 0
fi


userBaseDN="ou=People,dc=sp,dc=com"
groupBaseDN="ou=Group,dc=sp,dc=com"
ldapManager="cn=Manager,dc=sp,dc=com"
hostname=`hostname -f`
password=12345678


if [[ $1 == "ipauser.ldif" ]];then
for uid in `cat $1 | grep 'dn: uid' | cut -f2 -d "="|cut -f1 -d ","`
do
cn=`sed -e "/^dn: uid=$uid/,/^$/!d;!p" $1| grep 'cn:' | cut -f2 -d ":"`
password=`sed -e "/^dn: uid=$uid/,/^$/!d;!p" $1| grep userPassword:: |cut -f3 -d ":"`
uidNumber=`sed -e "/^dn: uid=$uid/,/^$/!d;!p" $1|grep uidNumber|cut -f2 -d ":"`
gidNumber=`sed -e "/^dn: uid=$uid/,/^$/!d;!p" $1|grep gidNumber|cut -f2 -d ":"`
loginShell=`sed -e "/^dn: uid=$uid/,/^$/!d;!p" $1|grep loginShell |cut -f2 -d ":"`
mail=`sed -e "/^dn: uid=$uid/,/^$/!d;!p" $1|grep mail|cut -f2 -d ":"`
gecos=`sed -e "/^dn: uid=$uid/,/^$/!d;!p" $1|grep gecos|cut -f2 -d ":"`
sn=`sed -e "/^dn: uid=$uid/,/^$/!d;!p" $1|grep sn:|cut -f2 -d ":"`

if [[ -z $password ]];then
echo "
dn: uid=$uid,$userBaseDN
uid: $uid
cn:$cn
sn:$sn
objectClass: person
objectClass: posixAccount
objectclass: iNetOrgPerson
objectClass: top
objectClass: shadowAccount
shadowLastChange: 17566
shadowMin: 0
shadowMax: 99999
shadowWarning: 7
loginShell:$loginShell
uidNumber:$uidNumber
gidNumber:$gidNumber
mail:$mail
homeDirectory: /home/${uid}
gecos:$gecos


" >> ./user.ldif

elif [[ -z $mail ]];then
echo "
dn: uid=$uid,$userBaseDN
uid: $uid
cn:$cn
sn:$sn
objectClass: person
objectClass: posixAccount
objectclass: iNetOrgPerson
objectClass: top
objectClass: shadowAccount
userPassword:$password
shadowLastChange: 17566
shadowMin: 0
shadowMax: 99999
shadowWarning: 7
loginShell:$loginShell
uidNumber:$uidNumber
gidNumber:$gidNumber
homeDirectory: /home/${uid}
gecos:$gecos


" >> ./user.ldif

else
echo "
dn: uid=$uid,$userBaseDN
uid: $uid
cn:$cn
sn:$sn
objectClass: person
objectClass: posixAccount
objectclass: iNetOrgPerson
objectClass: top
objectClass: shadowAccount
userPassword:$password
shadowLastChange: 17566
shadowMin: 0
shadowMax: 99999
shadowWarning: 7
loginShell:$loginShell
uidNumber:$uidNumber
gidNumber:$gidNumber
mail:$mail
homeDirectory: /home/${uid}
gecos:$gecos


" >> ./user.ldif
fi
done
ldapadd -h $hostname  -D "$ldapManager" -w $password  -x -f ./user.ldif
fi


if [[ $1 == "ipagroups.ldif" ]];then
OLDIFS="$IFS"
IFS=$'\n'

for gid in `cat $1 | grep ",cn=groups"|cut -f2 -d "="|cut -f1 -d ","`
do
#echo $gid
cn=`sed -e "/^dn: cn=$gid/,/^$/!d;!p" $1| grep cn:|cut -f2 -d ":"`
#echo $cn
gidNumber=`sed -e "/^dn: cn=$gid/,/^$/!d;!p" $1|grep gidNumber:|cut -f2 -d ":"`
#echo $gidNumber
memberUid=`sed -e "/^dn: cn=$gid/,/^$/!d;!p" $1|grep member:|cut -f1 -d ","|sed "s/member: uid=/memberUid: /g"`

if  [[ $gidNumber -gt 1 ]];then
echo "
dn: cn=$gid,$groupBaseDN
objectClass: posixGroup
objectClass: top
cn:$cn
userPassword: {crypt}x
gidNumber:$gidNumber
$memberUid

" >> ./group.ldif
fi
done
IFS="$OLDIFS"
ldapadd -h $hostname  -D "$ldapManager" -w $password  -x -f ./group.ldif
fi
