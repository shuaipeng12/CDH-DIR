#!/bin/sh
source ./ldapshell.conf
# Usage Tips
if [ $# -lt 3 ] ; then
  echo "USAGE: sh add_user.sh <uid> <password> <uidNumber>"
  exit 1;
fi

uid=$1
password=$2
uidNumber=$3
path="`pwd`/ldif"
mkdir -p $path


#============================================ Create LDAP User And Group ==========================================
echo "Create LDAP User......"
echo "dn: uid=$uid,ou=People,${LDAP_REALM}
uid: $uid
cn: $uid
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: $password
loginShell: /bin/bash
uidNumber: $uidNumber
gidNumber: $uidNumber
homeDirectory: /home/$uid" > ${path}/${uid}.ldif

# Create User Group Ldif File
echo "dn: cn=$uid,ou=Group,${LDAP_REALM}
objectClass: posixGroup
objectClass: top
cn: $uid
userPassword: $password
gidNumber: $uidNumber
memberUid: $uid" > ${path}/${uid}_group.ldif

# Add LDAP user and group
ldapadd -h cdp2.macro.com:389  -x -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD} -f ${path}/${uid}.ldif
ldapadd -h cdp2.macro.com:389  -x -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD} -f ${path}/${uid}_group.ldif

# Search New LDAP User
res=`ldapsearch -h cdp2.macro.com:389  -x -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD}  -b "${LDAP_REALM}" | grep -w "$uid"`
if [[ $res != "" ]] ; then
  echo "Add New LDAP User Successfully!"
else
  echo "Failed to Add New LDAP User"
  exit 1
fi

#==================================================== Create Kerberos Principal =====================================
#echo "Create Kerberos Principal......"
#ssh -p ${PORT} ${USER_NAME}@${ADMIN_SERVER} "kadmin.local -q 'add_principal -pw ${password} ${uid}${KRB_REALM}'"
#exit 0
