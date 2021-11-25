#! /bin/bash
#
# Ref: https://www.freeipa.org/page/Howto/HBAC_and_allow_all
#
ipa hbacrule-add allow_devops_admins_to_legacy_prod_servers
ipa hbacrule-add-service allow_devops_admins_to_legacy_prod_servers --hbacsvcgroups=default_allow_all_services_minus_ftp
ipa hbacrule-add-user allow_devops_admins_to_legacy_prod_servers --groups=devops-admins
ipa hbacrule-add-host allow_devops_admins_to_legacy_prod_servers --hostgroups=legacy_prod_servers
#
# Sample tests if user can access sshd
# ipa hbactest --user first.admin --host cicd.example.local --service sshd # expect True however as cicd runs sshd on port 22000, it reported False
# ipa hbactest --user second.admin --host cicd.example.local --service sshd # expect True however as cicd runs sshd on port 22000, it reported False
# ipa hbactest --user second.admin --host cicdr0.example.local --service sshd # expect True and it reported correctly
# ipa hbactest --user second.admin --host cicdr1.example.local --service sshd # expect True and it reported correctly
# ipa hbactest --user test.user --host cicd.example.local --service sshd # expect False and it reported correctly
