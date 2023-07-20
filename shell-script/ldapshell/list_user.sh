#!/bin/sh

# Usage Tips
source ./ldapshell.conf

ldapsearch -b "ou=People,${LDAP_REALM}" -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD}

