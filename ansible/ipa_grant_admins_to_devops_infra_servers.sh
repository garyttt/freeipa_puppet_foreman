#! /bin/bash
#
ipa hbacrule-add allow_admins_to_devops_infra_servers
ipa hbacrule-add-service allow_admins_to_devops_infra_servers --hbacsvcgroups=default_allow_all_services_minus_ftp
ipa hbacrule-add-user allow_admins_to_devops_infra_servers --groups=admins
ipa hbacrule-add-host allow_admins_to_devops_infra_servers --hostgroups=devops_infra_servers
#
# Sample tests if user can access sshd
# ipa hbactest --user first.admin --host puppet.example.local --service sshd
# ipa hbactest --user second.admin --host puppet.example.local --service sshd
# ipa hbactest --user second.admin --host foreman.example.local --service sshd
# ipa hbactest --user third.admin --host ipa.example.local --service sshd
# ipa hbactest --user test.user --host puppet.example.local --service sshd # expect False and it reported correctly
# ipa hbactest --user test.user2 --host ipa.example.local --service sshd # expect False and it reported correctly
