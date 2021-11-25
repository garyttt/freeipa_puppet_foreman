#! /bin/bash
echo "Please enter Puppet Enterprise Server FQDN Fully Qualified Domain Name: example puppet.example.local"
read PUPPET_SERVER
[ "`hostname -f`" != "${PUPPET_SERVER}" ] && echo "Please run this script as root locally at Puppet Enterprise Server" && exit 1
[ $EUID -ne 0 ] && echo "Not root" && exit 1
for NODE in centos8 ipa ipa2 jenkins ubuntu20
do
  puppet node clean $NODE.example.local
done
puppetserver ca list --all
