#! /bin/bash
#
# Ref: https://www.freeipa.org/page/Howto/HBAC_and_allow_all
#
ipa hostgroup-add --desc 'Host group which will have allow_all_users_services HBAC enabled.' allow_all_hosts
ipa host-find --raw --pkey-only --sizelimit=0 \
    | awk '$1 == "fqdn:" { print "--hosts=" $2 }' | xargs -n100 ipa hostgroup-add-member allow_all_hosts
ipa hbacrule-add allow_all_users_services --usercat=all --servicecat=all --desc='Allow access to hosts in group allow_all_hosts to anybody from anywhere.'
ipa hbacrule-add-host allow_all_users_services --hostgroups=allow_all_hosts
ipa hbacrule-disable allow_all
