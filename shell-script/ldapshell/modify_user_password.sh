#!/bin/sh
source ./ldapshell.conf
# Usage Tips
if [ $# -lt 2 ] ; then
  echo "USAGE: sh modify_user_password <uid> <new_password>"
  exit 1;
fi

uid=$1
password=$2

ldappasswd -x -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD} "uid=${uid},ou=People,${LDAP_REALM}" -s ${password}

if [[ $? == 0 ]] ; then
  echo "Modify LDAP User password Successfully!"
else
  echo "Failed to Modify LDAP User password"
  exit 1
fi
