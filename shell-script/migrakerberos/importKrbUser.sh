#!/bin/bash
# Created By shuaipeng@macrointel.cn
# Modified By shuaipeng@macrointel.cn
# Created date: 2022/08/23
# Modified data: 

#导入freeipa用户的principal到MIT KDC 数据库中
#脚本自动导入


#USAGE
if [ $# -ne 1 ];then
        echo "Usage: ./importKrbUser.sh ipakrb.ldif"
        exit 0
fi


hostname=`hostname -f`
password=12345678


if [[ $1 == "ipakrb.ldif" ]];then
echo "$password" | kinit admin/admin

for uid in `cat $1 | grep 'dn: uid' | cut -f2 -d "="|cut -f1 -d ","`
do
krbPrincipalName=`sed -e "/^dn: uid=$uid/,/^$/!d;!p" $1|grep krbPrincipalName:|cut -f2 -d " "`
krbPrincipalKey=`sed -e "/^dn: uid=$uid/,/^$/!d;!p" $1|grep krbPrincipalKey::|cut -f2 -d " "`

kadmin -q "addprinc -pw $krbPrincipalKey $krbPrincipalName" -w $password -s $hostname
if [ $? -eq 0 ];then
	echo "KrbPrincipal import successfully!"
else
	echo "KrbPrincipal import failed!"
fi

done

else
	echo "UNKNOW ARGUMENT $1"
fi

