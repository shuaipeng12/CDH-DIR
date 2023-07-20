#!/bin/sh
source ./ldapshell.conf

# Usage Tips
if [ $# -lt 2 ] ; then
  echo "USAGE: sh delete_user_from_group.sh <uid> <group>"
  exit 1;
fi

# Args
uid=$1
group=$2
path="`pwd`/ldif"

# Edit LDIF
echo "dn: cn=$group,ou=Group,${LDAP_REALM}
changetype: modify
delete: memberUid
memberUid: $uid" > ${path}/update_${group}_group.ldif

ldapmodify -x -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD} -f ${path}/update_${group}_group.ldif
if [ $? == 0 ] ; then
  rm -f /var/lib/sss/db/cache_default.ldb
  systemctl restart sssd
else
  exit 1
fi
