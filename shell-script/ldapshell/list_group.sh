#!/bin/sh
source ./ldapshell.conf

ldapsearch -b "ou=Group,${LDAP_REALM}" -D "cn=Manager,${LDAP_REALM}" -w ${LDAP_PASSWD}

