#!/bin/sh
source ./ldapshell.conf

# Usage Tips
if [ $# -lt 1 ] ; then
  echo "USAGE: sh search_user.sh <uid>"
  exit 1;
fi

uid=$1

#ldap Manager password
ldap_manager_pw=123456

ldapsearch -b "uid=$uid,ou=People,${LDAP_REALM}" -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD}

