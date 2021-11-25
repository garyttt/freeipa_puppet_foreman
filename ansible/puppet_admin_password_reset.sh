#! /bin/bash
# Ref: https://puppet.com/docs/pe/2021.3/console_accessing.html#reset_the_admin_password
echo "Please enter Puppet Enterprise Server FQDN Fully Qualified Domain Name: example puppet.example.local"
read PUPPET_SERVER
[ "`hostname -f`" != "${PUPPET_SERVER}" ] && echo "Please run this script as root locally at Puppet Enterprise Server" && exit 1
[ $EUID -ne 0 ] && echo "Not root" && exit 1
ADMIN_PASSWORD=x
ADMIN_PASSWORD2=y
while [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD2" ]
do
  echo -n "Please enter new admin password (min. 8 characters): "
  stty -echo
  read ADMIN_PASSWORD
  echo ""
  echo -n "Please enter new admin password again (min. 8 characters): "
  read ADMIN_PASSWORD2
  echo ""
  [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD2" ] && echo "Password mismatched..."
done
/opt/puppetlabs/puppet/bin/puppet infrastructure console_password --password=$ADMIN_PASSWORD
stty echo
