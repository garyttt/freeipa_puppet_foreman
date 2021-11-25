#! /bin/bash
# Ref: https://access.redhat.com/solutions/2859621
echo "Please enter The Foreman (tfm) Server FQDN Fully Qualified Domain Name: example foreman.example.local"
read FOREMAN_SERVER
[ "`hostname -f`" != "${FOREMAN_SERVER}" ] && echo "Please run this script as root locally at Foreman Server" && exit 1
[ $EUID -ne 0 ] && echo "Not root" && exit 1
foreman-rake permissions:reset
echo "Please reset the admin password to your desired in Foreman GUI under Administer / Users / Edit Admin User"
foreman-rake apipie:cache
echo "Done."

