#!/bin/sh
source ./ldapshell.conf

# Usage Tips
if [ $# -lt 1 ] ; then
  echo "USAGE: sh search_group.sh <uid>"
  exit 1;
fi

group=$1


ldapsearch -b "cn=$group,ou=Group,${LDAP_REALM}" -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD}

