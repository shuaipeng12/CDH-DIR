#!/bin/sh
source ./ldapshell.conf

# Usage Tips
if [ $# -lt 2 ] ; then
  echo "USAGE: sh add_group.sh <groupname> <gidNumber>"
  exit 1;
fi

groupname=$1
gidNumber=$2
path="`pwd`/ldif"
mkdir -p $path


#=============================================== Create LDAP Group =============================================

# Create User Group Ldif File
echo "dn: cn=$groupname,ou=Group,${LDAP_REALM}
objectClass: posixGroup
objectClass: top
cn: $groupname
gidNumber: $gidNumber" > ${path}/${groupname}_group.ldif

# Add New LDAP Group
ldapadd -x -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD} -f ${path}/${groupname}_group.ldif

# Search New LDAP Group
res=`ldapsearch -x -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD}  -b "dn: cn=$groupname,ou=Group,${LDAP_REALM}"`
if [[ $res != "" ]] ; then
  echo "Add New LDAP Group Successfully!"
else
  echo "Failed to Add New LDAP Group"
  exit 1
fi
