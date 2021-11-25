#! /bin/bash
# This script needs 'kinit admin' kerberos ticket
# It grants RESTRICTED sudo access to group servers for user group members, users in guests group won't be included
# RESTRICTION is based on a list of allow-commands or allow-command-groups
# Pre-requisites:
# . Users_Group and Hosts_Group already exist
# . List of allow-commands or allow-command-groups setup

# Templates for copy and paste
# FULL sudo: a total of three CLIs are required
# ipa sudorule-add proj_xxx_developers --runasusercat=all --runasgroupcat=all --cmdcat=all
# ipa sudorule-add-user sudo_access_to_xxxservers --group xxxgroup
# ipa sudorule-add-host sudo_access_to_xxxservers --hostgroup xxxhostgroup
# RESTRICTED sudo: extra lines needed to setup allow-commands and allow-command-groups and associate it with sudoRole
# ipa sudorule-add proj_xxx_developers --runasusercat=all --runasgroupcat=all
# ipa sudocmd-add "/usr/bin/somecmd arg1 arg2"
# ipa sudocmd-add "/usr/bin/anothercmd arg1 arg2"
# ipa sudocmdgroup-add sudocmds_for_sudo_access_to_xxxservers
# ipa sudocmdgroup-add-member sudocmds_for_sudo_access_to_xxxservers --sudocmds "/usr/bin/somecmd arg1 arg2"
# ipa sudocmdgroup-add-member sudocmds_for_sudo_access_to_xxxservers --sudocmds "/usr/bin/anothercmd arg1 arg2"
# ipa sudorule-add-user proj_xxx_developers --group proj_xxx_group
# ipa sudorule-add-host proj_xxx_developers --hostgroups=proj_xxx_servers
# ipa sudorule-add-allow-command proj_xxx_developers --sudocmdgroups=proj_xxx_developers_allow_sudocmds

# setup list of allow-commands
ipa sudocmd-add "/usr/sbin/sss_cache -E"
ipa sudocmd-add "/usr/bin/systemctl restart sssd"
ipa sudocmd-add "/usr/bin/systemctl restart sshd"
ipa sudocmd-add "/usr/bin/chmod * /mnt/appln_xx/*"
ipa sudocmd-add "/usr/bin/chown * /mnt/appln_xx/*"
ipa sudocmd-add "/usr/bin/chgrp * /mnt/appln_xx/*"
# setup list of allow-command-groups
ipa sudocmdgroup-add proj-xx1-developers-allow-sudocmds --sudocmds

# FULL sudo for XX1 Team:
# sudo access to xx1servers - commented out next three lines in favour of RESTRICTED sudo (ALL) access
# ipa sudorule-add sudo_access_to_xx1servers --runasusercat=all --runasgroupcat=all --cmdcat=all
# ipa sudorule-add-user sudo_access_to_xx1servers --group=xx1
# ipa sudorule-add-host sudo_access_to_xx1servers --hostgroup=xx1servers

# RESTRICTED sudo for XX1 Team:
ipa sudorule-remove-host sudo_access_to_xx1servers --hostgroup=xx1servers
ipa sudorule-remove-user sudo_access_to_xx1servers --group=xx1
ipa sudorule-remove sudo_access_to_xx1servers
ipa sudorule-add proj_xx1_developers --runasusercat=all --runasgroupcat=all
ipa sudocmdgroup-add-member proj-xx1-developers-allow-sudocmds --sudocmds "/usr/sbin/sss_cache -E"
ipa sudocmdgroup-add-member proj-xx1-developers-allow-sudocmds --sudocmds "/usr/bin/systemctl restart sssd"
ipa sudocmdgroup-add-member proj-xx1-developers-allow-sudocmds --sudocmds "/usr/bin/systemctl restart sshd"
ipa sudocmdgroup-add-member proj-xx1-developers-allow-sudocmds --sudocmds "/usr/bin/chmod * /mnt/appln_xx/*"
ipa sudocmdgroup-add-member proj-xx1-developers-allow-sudocmds --sudocmds "/usr/bin/chown * /mnt/appln_xx/*"
ipa sudocmdgroup-add-member proj-xx1-developers-allow-sudocmds --sudocmds "/usr/bin/chgrp * /mnt/appln_xx/*"
ipa sudorule-add-user proj_xx1_developers --group=xx1
ipa sudorule-add-host proj_xx1_developers --hostgroups=xx1servers
ipa sudorule-add-allow-command proj_xx1_developers --sudocmdgroups=proj-xx1-developers-allow-sudocmds

# sudo access to xx2servers
ipa sudorule-add sudo_access_to_xx2servers --runasusercat=all --runasgroupcat=all --cmdcat=all
ipa sudorule-add-user sudo_access_to_xx2servers --group xx2
ipa sudorule-add-host sudo_access_to_xx2servers --hostgroup xx2servers

echo "FreeIPA changes will take a little time to propagate, to speed up you may run the following commands at Master and affected Clients"
echo "ssh gtay@ipa 'sudo sss_cache -E && sudo systemctl restart sssd && sudo systemctl restart sshd'"
echo "ssh gtay@ipaclient 'sudo sss_cache -E && sudo systemctl restart sssd && sudo systemctl restart sshd'"

