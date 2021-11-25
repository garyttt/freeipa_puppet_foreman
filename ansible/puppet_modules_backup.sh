
#! /bin/bash
cd /
PATHS=`/opt/puppetlabs/puppet/bin/puppet config print | grep -i ^modulepath | tr -d ' ' | cut -d'=' -f2 | tr ':' ' '`
DOM=`date "+%d"`
mkdir -p /root/backup
tar cvfz /root/backup/puppet_modules_${DOM}.tgz $PATHS
