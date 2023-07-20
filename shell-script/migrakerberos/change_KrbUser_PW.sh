#!/bin/bash
# Created By shuaipeng@macrointel.cn
# Modified By shuaipeng@macrointel.cn
# Created date: 2022/08/23
# Modified data:

#修改导入的kerberos用户的密码

adminPassword=12345678
echo $adminPassword | kinit admin/admin > /dev/null
krbUser=(`kadmin -q "listprincs" -w $adminPassword | grep -v '/'`)


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


uerName=" "
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


changePW()
{
scanUserName
if echo "${krbUser[@]}" | grep -w "$userName" &> /dev/null;then
	scanUserPassword
	kadmin -q "cpw -pw $userPassword $userName" -w $adminPassword

	if [ $? -eq 0 ];then
        	log_success_msg "Modification successful!"
	else
        	log_failure_msg "Modification failed!"
	fi

elif echo $userName | grep "/" > /dev/null;then
	echo "${userName} is the principal of the service, not the principal of the user.Please re-enter!"
	changePW
else
        echo "${userName} is not in Kerberos. Please re-enter!"
        changePW
fi
}


changePW
