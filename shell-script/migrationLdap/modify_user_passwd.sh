#!/bin/bash
# Created By shuaipeng@macrointel.cn
# Modified By shuaipeng@macrointel.cn
# Created date: 2022/08/15
# Modified data: 2022/08/15


#Provides a tool to change the password of an openldap user

userBaseDN="ou=People,dc=sp,dc=com"
ldapManager="cn=Manager,dc=sp,dc=com"
hostname=`hostname -f`
password=12345678
ldapUser=(`ldapsearch -h $hostname -x -D "$ldapManager" -w $password| grep "dn: uid=" | cut -f2 -d "="|cut -f1 -d ","`)

lsb_functions="/lib/lsb/init-functions"
if test -f $lsb_functions ; then
    . $lsb_functions
else
    # Include non-LSB RedHat init functions to make systemctl redirect work
    init_functions="/etc/init.d/functions"
    if test -f $init_functions; then
        . $init_functions
    fi
    log_success_msg()
    {
        echo " SUCCESS! $@"
    }
    log_failure_msg()
    {
        echo " ERROR! $@"
    }
fi

userName=" "
scanUserName()
{
read -p "Please enter a user name: " userName
if [ -z  $userName ];then
	scanUserName
fi
userName=$userName
}

userPassword=" "
scanUserPassword()
{
read -p "Please enter a password: " userPassword
if [ -z $userPassword ];then
	scanUserPassword
else
	read -p "Please confirm the password: " userPasswordEnter
	if [ $userPassword != $userPasswordEnter ];then
		echo "The password entered twice is inconsistent, please re-enter it!"
		scanUserPassword
	fi
fi
userPassword=$userPasswordEnter
}


modifyUserPassword()
{
scanUserName
if echo "${ldapUser[@]}" | grep -w "$userName" &> /dev/null;then
scanUserPassword
echo "
dn: uid=$userName,$userBaseDN
changetype: modify
replace: userPassword
userPassword: $userPasswordEnter
" > ./modify_${userName}_passwd.ldif

ldapmodify -a -H ldap://${hostname}:389 -D "$ldapManager" -w $password -f modify_${userName}_passwd.ldif > /dev/null
if [ $? -eq 0 ];then
	log_success_msg "Modification successful!"
else
	log_failure_msg "Modification failed!"
fi

else
	echo "${userName} is not in openldap. Please re-enter!"
	modifyUserPassword
fi
}

modifyUserPassword


