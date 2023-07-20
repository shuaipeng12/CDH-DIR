#!/bin/sh
source ./ldapshell.conf

# Usage Tips
if [ $# -lt 1 ] ; then
  echo "USAGE: sh delete_user.sh <uid>"
  exit 1;
fi

uid=$1
group=$1

#==================================================== Delete LDAP User And Group =====================================
echo "Delete LDAP User......"
ldapdelete "uid=$uid,ou=People,${LDAP_REALM}" -x  -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD}

if [ $? -eq 0 ]; then
  echo "LDAP User $uid is deleted!"
  echo "Delete LDAP Group......"
  ldapdelete "cn=$group,ou=Group,${LDAP_REALM}" -x  -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD}
  if [ $? -eq 0 ]; then
    echo "LDAP Group $uid is deleted!"
  else
    echo "LDAP Group $uid is not deleted!"
  fi
else
  echo "LDAP User $uid is not deleted!"
fi

#==================================================== Delete Kerberos Principal =====================================
echo "Delete Kerberos Principal......"
ssh -p ${PORT} ${USER_NAME}@${ADMIN_SERVER} "kadmin.local -q 'delete_principal -force $uid${KRB_REALM}'"
if [ $? -eq 0 ]; then
  echo "Principal '$uid${KRB_REALM}' deleted!"
else
  echo "Principal '$uid${KRB_REALM}' not deleted!"
fi
exit 0
