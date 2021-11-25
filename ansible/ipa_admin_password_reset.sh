#! /bin/bash
# Ref: https://computingforgeeks.com/reset-freeipa-admin-password-as-root-user-on-linux/
echo "Please enter FreeIPA Server FQDN Fully Qualified Domain Name: example ipa.example.local"
read IPA_SERVER
[ "`hostname -f`" != "${IPA_SERVER}" ] && echo "Please run this script locally at IPA Server" && exit 1
echo "Please enter FreeIPA Domain Name: example dev.example.local"
read IPA_DOMAIN
DNS_PREFIX=`echo ${IPA_DOMAIN} | cut -d'.' -f1`
echo "Please enter new admin password TWICE followed by Directory Manager password"
export LDAPTLS_CACERT=/etc/ipa/ca.crt
ldappasswd -ZZ -D 'cn=Directory Manager' -W -S \
  uid=admin,cn=users,cn=accounts,dc=${DNS_PREFIX},dc=example,dc=local \
  -H ldap://${IPA_SERVER}

