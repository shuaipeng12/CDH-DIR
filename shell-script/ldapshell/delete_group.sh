#!/bin/sh
source ./ldapshell.conf
# Usage Tips
if [ $# -lt 1 ] ; then
  echo "USAGE: sh delete_group.sh <cn>"
  exit 1;
fi

group=$1

ldapdelete "cn=$group,ou=Group,${LDAP_REALM}" -x -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD}
if [ $? == 0 ] ; then
  echo "LDAP Group $group is deleted Successfully!"
else
  echo "Failed to delete LDAP Group $group!"
  exit 1
fi
