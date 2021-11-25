#! /bin/bash
#
ipa hbacrule-add allow_devops_admins_to_devops_admins_vms
ipa hbacrule-add-service allow_devops_admins_to_devops_admins_vms --hbacsvcgroups=default_allow_all_services_minus_ftp
ipa hbacrule-add-user allow_devops_admins_to_devops_admins_vms --groups=devops-admins
ipa hbacrule-add-host allow_devops_admins_to_devops_admins_vms --hostgroups=devops_admins_vms
#
# Sample tests if user can access sshd
# ipa hbactest --user first.admin --host adminvm001.example.local --service sshd
# ipa hbactest --user second.admin --host adminvm001.example.local --service sshd
# ipa hbactest --user third.admin --host adminvm001.example.local --service sshd
# ipa hbactest --user fourth.admin --host adminvm001.example.local --service sshd
# ipa hbactest --user second.admin --host adminvm007.example.local --service sshd
# ipa hbactest --user test.user --host adminvm007.example.local --service sshd # expect False and it reported correctly
# ipa hbactest --user test.user2 --host adminvm007.example.local --service sshd # expect False and it reported correctly
