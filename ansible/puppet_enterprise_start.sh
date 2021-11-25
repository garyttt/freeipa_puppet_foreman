#! /bin/bash
echo "Please enter Puppet Enterprise Server FQDN Fully Qualified Domain Name: example puppet.example.local"
read PUPPET_SERVER
[ "`hostname -f`" != "${PUPPET_SERVER}" ] && echo "Please run this script as root locally at Puppet Enterprise Server" && exit 1
[ $EUID -ne 0 ] && echo "Not root" && exit 1
echo ""
systemctl daemon-reload
for i in `systemctl list-unit-files | grep "^pe-" | grep -i enabled | cut -d' ' -f1`
do
  echo "Starting $i ..." && systemctl start $i
done
