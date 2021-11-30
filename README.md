# Centralized UNIX Auth / Centralized sudoers / Centralized HostBasedAccessControl / Centralized Configuration

This GIT Repo provides Ansible and Shell scripts for building:

1. FreeIPA (RedHat Identity Management) Primary Master (ipa.example.local) CentOS Stream 8.X 2-CPU/4GB RAM
2. FreeIPA (RedHat Identity Management) Secondary Master (ipa2.example.local) CentOS Stream 8.X 2-CPU/4GB RAM
3. Puppet Enterprise 2021.4 (puppet.example.local) CentOS Stream 8.X 2-CPU/4GB RAM
4. Foreman 3.0.1 (foreman.example.local) CentOS Stream 8.X 2-CPU/4GB RAM
---
Please 'dnf upgrade' the above servers OS to the latest patches prior to proceeding.

# What is FreeIPA?

* https://en.wikipedia.org/wiki/FreeIPA
* https://pagure.io/freeipa
* https://www.freeipa.org/page/Quick_Start_Guide
* https://freeipa.readthedocs.io/en/latest/workshop/workshop.html
* https://lists.fedoraproject.org/archives/list/freeipa-users@lists.fedorahosted.org/
* https://hub.docker.com/r/freeipa/freeipa-server

Note: we will be using RedHat Identity Management (IdM) AppStream Yum Repo '@idm:DL1', the name of the FreeIPA packages are prefixed with 'ipa-' not 'freeipa-'.

# Preparations

1. Ensure all VMs are having the same host entries in /etc/hosts, edit it to the actual one for your VMs.
```
192.168.159.128 puppet.example.local puppet
192.168.159.129 foreman.example.local foreman
192.168.159.131 centos8.example.local centos8
192.168.159.132 ubuntu20.example.local ubuntu20
192.168.159.133 ipa.example.local ipa
192.168.159.134 jenkins.example.local jenkins
192.168.159.135 ipa2.example.local ipa2
```
2. Ensure DNS Client (Resolver) is configured to search 'example.local' domain at ALL VMs.
---
Login as root at ALL VMs:
```bash
sed -i s/.*Domains=.*/Domains=example.local/ /etc/systemd/resolved.conf
systemctl restart systemd-resolved
hostname -i
hostname -f
```
3. Ensure all VMs are having the same timezone.
```bash
ln -sf /usr/share/zoneinfo/Asia/Singapore /etc/localtime
```
4. Ensure umask is 0022 in ~/.bashrc of root account who will usually own the package files.
5. Ensure the run_user@controller (gtay@centos8) SSH public key is authorized by remote_user@remote_host (gtay@ALL_VMs).
6. Ensure the remote_user (gtay) has sudo right at the remote_host (ALL VMs).
7. Ensure curl and GIT client are installed at ALL VMs.
8. Ensure ntpd service is inactive and chronyd service is active at ALL VMs.

# Centralized UNIX Authentication: FreeIPA Primary and Secondary Master

Note: Secondary Master is a Replica Master with additional CA Server Install, at any one time either Primary Master or Secondary Master can play the role as CA Renewal Master Server via 'ipa-crlgen-manage enable' command.

1. Login as run_user (gtay) at the controller (centos8) and clone the GIT Repo.
```bash
git clone https://github.com/garyttt/freeipa_puppet_foreman.git
cd freeipa_puppet_foreman/ansible
```
2. Edit 'DNS_SERVER1' and other customized settings and provide the actual IP for your use case.
```bash
grep -iR 192.168 *
install_freeipa_replica.yaml:    DNS_SERVER1: "192.168.159.2"
install_freeipa_server.yaml:    DNS_SERVER1: "192.168.159.2"
install_freeipa_server.yaml:      prompt: The FreeIPA Server IP Address, press Enter for default of 192.168.159.133 (ipa)
install_freeipa_server.yaml:      default: "192.168.159.133"
```
3. Run Ansible for Primary Master Install, take default values except admin and directory manager password which you need to define.
```bash
ansible-playbook -vv -i inventory/hosts -l ipa install_freeipa_server.yaml -K
```
Inputs:
```
The FreeIPA Server IP Address, press Enter for default of 192.168.159.133 (ipa) [192.168.159.133]:
The FreeIPA Server FQDN, press Enter for default of ipa.example.local [ipa.example.local]:
The FreeIPA Kerberos REALM in CAPITAL, press Enter for default of DEV.EXAMPLE.LOCAL [DEV.EXAMPLE.LOCAL]:
The FreeIPA DNS Domain/Sub-Domain in lowercase, press Enter for default of dev.example.local [dev.example.local]:
The admin principal Kerberos password:
The Directory Manager password:
```
4. When the current task is 'Install/Configure FreeIPA Server', launch another terminal session, login as remote_user (gtay) at remote host (ipa), and tail the IPA Server Install log.
```bash
sudo tail -100f /var/log/ipaserver-install.log
```
5. When it shows 'INFO The ipa-server-install command was successful', Ctrl-C to break the tailing, and restart IPA. If this is the first FreeIPA Server Install, enable it as the default CRL Generator.
---
Login as root:
```bash
sudo -i
ipactl restart
ipactl status
ipa-crlgen-manage enable
ipa-crlgen-manage status
```
6. If there is failure and re-installation is needed:
```bash
ipa-server-install --uninstall
dnf remove -y sssd-ipa 389-ds-core
```
7. Verify FreeIPA GUI https://ipa.example.local/ipa/ui
---
It is highly recommended to apply SSL Cert to FreeIPA GUI Web Server

Now Replica (plus CA) Install:

Login as run_user (gtay) at controller (centos8)

Edit IPA\_ related FQDN, DOMAIN and REALM for your use case.
```
grep -i IPA_ install_freeipa*.yaml
install_freeipa_client.yaml:    IPA_FQDN: "ipa.example.local"
install_freeipa_client.yaml:    IPA_DOMAIN: "dev.examle.local"
install_freeipa_client.yaml:    IPA_REALM: "DEV.EXAMPLE.LOCAL"
install_freeipa_replica.yaml:    IPA_DOMAIN: "dev.example.local"
install_freeipa_replica.yaml:    IPA_REALM: "DEV.EXAMPLE.LOCAL"
```

8. Run Ansible for Seondary Master Install, take default values except for the last prompt you need to provide admin password.
```bash
ansible-playbook -vv -i inventory/hosts -l ipa2 install_freeipa_replica.yaml -K
```
Inputs:
```
The Fully Qualified Domain Name of the IPA Primary Master (CA-CRL)), press Enter for default of ipa.example.local" [ipa.example.local]:
The Fully Qualified Domain Name of the IPA Replica Master (ipa2.example.local), press Enter for default of ipa2.example.local" [ipa2.example.local]:
The admin Kerberos principal, press Enter for default of admin@"DEV.EXAMPLE.LOCAL" [admin@DEV.EXAMPLE.LOCAL]:
The admin Kerberos password:
```
9. When the current task is 'Install/Configure FreeIPA Replica', launch another terminal session, login as remote_user (gtay) at remote host (ipa2), and tail the IPA Replica Install log.
```bash
sudo tail -100f /var/log/ipareplica-install.log
```
10. When it shows 'INFO The ipa-replica-install command was successful', Ctrl-C to break the tailing, and restart IPA.
---
Login as root at ipa2:
```bash
sudo -i
ipactl restart
ipactl status
```
11. If there is failure and re-installation is needed:
---
Login as root at Primary Master (ipa):
```bash
ipa-replica-manage del ipa2.example.local --force
# Note: there will be error if you have not performed the fix as per step 14.
```
Login as root at Replica Master (ipa2):
```bash
ipa-server-install --uninstall
dnf remove -y sssd-ipa 389-ds-core
```
12. Else continue with CA Server Install, ensure CRL Generator status is 'disabled' as Primary Master is acting as it.
```bash
ipa-ca-install
ipa-crlgen-manage status
```
13. Verify FreeIPA GUI https://ipa2.example.local/ipa/ui

14. Note that as there is no DNS Server serving zone 'example.local', the following messages are normal.
```
ipaserver.dns_data_management: ERROR unable to resolve host name ipa.example.local. to IP address, ipa-ca DNS record will be incomplete
OR
Unknown host ipa.example.local: Host 'ipa2.example.local' does not have corresponding DNS A/AAAA record
OR
Unknown host ipa2.example.local: Host 'ipa2.example.local' does not have corresponding DNS A/AAAA record

To fix this, we can easily add 'example.local' DNS Zone in IPA GUI and the required 'ipa.example.local.' and 'ipa2.example.local.' DNS 'A' Resource Records (note the trailing dot). Once this is done 'ipa-replica-manage list' will show no error.
```

# Install FreeIPA Client at multiple remote hosts

1. Login as run_user (gtay) at the controller (centos8) and clone the GIT Repo if it is not already done.
```bash
git clone https://github.com/garyttt/freeipa_puppet_foreman.git
cd freeipa_puppet_foreman/ansible
```
2. Edit IPA\_ related FQDN, DOMAIN and REALM for your use case if applicable.
```bash
grep IPA_.*: install_freeipa_client.yaml
install_freeipa_client.yaml:    IPA_FQDN: "ipa.example.local"
install_freeipa_client.yaml:    IPA_DOMAIN: "dev.examle.local"
install_freeipa_client.yaml:    IPA_REALM: "DEV.EXAMPLE.LOCAL"
```
3. Run Ansible for FreeIPA Clients Install, take default values except admin password which you need to define.
```bash
ansible-playbook -vv -i inventory/hosts -l ipaclients install_freeipa_client.yaml -K
```
Inputs:
```
The admin Kerberos principal, press Enter for default of admin@"DEV.EXAMPLE.LOCAL" [admin@DEV.EXAMPLE.LOCAL]:
The admin Kerberos password:
```
4. If there is failure and re-installation is needed, run at the Client end:
---
Login as root:
```bash
ipa-client-install --uninstall
```

# Populate the FreeIPA Server with some testing data

1. Login as remote_user (gtay) at the remote_host (ipa) and clone the GIT Repo.
```bash
kinit admin
ipa config-mod --defaultshell=/bin/bash
ipa config-mod --emaildomain=example.local
git clone https://github.com/garyttt/freeipa_puppet_foreman.git
cd freeipa_puppet_foreman/ansible
bash -vx ./ipa_add_groups.sh
bash -vx ./ipa_add_users.sh
bash -vx ./ipa_add_groups_memberships.sh
```

# FreeIPA Backup and Restore

Please setup two cron jobs at Primary (ipa) and Seconday Master (ipa2), both the Primary and Secondary Master should run the cron at different timing, example 00:00 for Primray Master and 01:00 for Secondary Master as there will be short burst of IPA Service downtime for running 'ipa-backup', typically few minutes.

Login as root:
```
# One time effort to create /root/logs
# mkdir ~/logs
# Create the following crons
# crontab -l Primary Master
0 0 * * * cd /var/lib/ipa/backup && /sbin/ipa-backup > ~/logs/ipa_backup_`date "+\%d"`.log 2>&1 || true
30 0 * * * find /var/lib/ipa/backup -mtime +30 | xargs rm -rf > /dev/null 2>&1 || true
# crontab -l Secondary Master
0 1 * * * cd /var/lib/ipa/backup && /sbin/ipa-backup > ~/logs/ipa_backup_`date "+\%d"`.log 2>&1 || true
30 1 * * * find /var/lib/ipa/backup -mtime +30 | xargs rm -rf > /dev/null 2>&1 || true
```

Each full backup is presented as a folder in /var/lib/ipa/backup, If there is a real need for Disaster Recovery, the LDAP data backed up can be restored back using 'ipa-restore'.
```
cd /var/lib/ipa/backup
ipa-restore ipa-full-2021-MM-DD-HH-MM-SS
```

# FreeIPA FAQ Troubleshooting and Tips

Please refer to:

* https://github.com/garyttt/freeipa_puppet_foreman/blob/main/ansible/FreeIPA_FAQ_Troubleshooting_and_Tips.pdf

# Two-Factor Authentication 2FA (Global or Per-User)
---
Ref: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/linux_domain_identity_authentication_and_policy_guide/otp

Per-User based is preferred as it is more flexible, to activate 2FA in FreeIPA GUI, access user details, check both the **'Password'** and **'Two factor authentication (password + OTP)'** boxes of the **'User authentication types'** attribute.

We should enable 2FA for admin privileged accounts via the use of OTP (One-Time-Password), it can be done either:
* Option 1: User is able to self-service - User can do it in GUI via **'Actions / Add OTP Token / Add and Edit'**
* Option 2: Admin is able to assist

The 'Add and Edit' option provides us the opportunity to obtain the QR code for our Authenticator mobile applications, you may use
Microsoft Authenticator, Google Authenticator or FreeOTP Authenticator.

For some reason if IPA OTP Server is acting up and not working, you may disable the Per-User 2FA temporarily and enable it when issue is fixed.
```bash
kinit admin
ipa user-show --all admin.0001
ipa user-mod --user-auth-type=password admin.0001
# When issue is fixed
ipa user-mod --user-auth-type=password --user-auth-type=otp admin.0001
ipa user-show --all admin.0001
```
Note that it is possible to create multiple OTP Tokens for the same user.

# Secure FreeIPA Server With Let’s Encrypt SSL Certificate

Ref: https://computingforgeeks.com/secure-freeipa-server-with-lets-encrypt-ssl-certificate/

1. Login as run_user (gtay) at the controller (centos8) and clone the GIT Repo if it is not already done.
```bash
git clone https://github.com/garyttt/freeipa_puppet_foreman.git
cd freeipa_puppet_foreman/ansible
```
2. Take a backup of current Apache Web Server SSL Cert and Key
```
cp -p /var/lib/ipa/certs/httpd.crt   /var/lib/ipa/certs/httpd.crt.orig
cp -p /var/lib/ipa/private/httpd.key /var/lib/ipa/private/httpd.key.orig
tar cvf /root/var_lib_ipa_certs_private.tar /var/lib/ipa/certs/httpd.crt /var/lib/ipa/private/httpd.key
```
3. Run Ansible for FreeIPA SSL Install, please provide Email/FQDN.
```bash
ansible-playbook -vv -i inventory/hosts -l ipa install_freeipa_ssl.yaml -K
```
Inputs:
```
IPA Apache Web Server SSL Cert EMAIL Contact, press Enter for default of garyttt@singnet.com.sg [garyttt@singnet.com.sg]: 
IPA Apache Web Server SSL Cert FQDN, press Enter for default of ipa.example.local [ipa.example.local]: 
```
4. When the playbook is run successfully, perform post setup one-time instructions, and verify SSL connection.
Login as root at Primary Master (ipa)
```bash
cat /var/lib/ipa/passwds/ipa.example.local-443-RSA && echo 
# When the renew-le.sh is run for the first-time and it asks for the pass phrase, enter the context of the above file
/root/freeipa-letsencrypt/renew-le.sh --first-time
systemctl restart httpd
ipa-certupdate
ipactl status && systemctl status ipa
openssl s_client -showcerts -verify 5 ipa.example.local:443
```

Note: as example.local is a POC (Proof Of Concept) private domain, the 'renew-le.sh --first-time' will fail with the following error:
```
An unexpected error occurred:
The server will not issue certificates for the identifier :: Error creating new order :: Cannot issue for "ipa.example.local": Domain name does not end with a valid public suffix (TLD)
Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for more details.
```

# Centralized SSH Public Keys
---
* Ref: https://freeipa.readthedocs.io/en/latest/workshop/10-ssh-key-management.html
* Study the 'ipa_add_ssh_public_key.sh'

# Centralized sudoers (aka sudoRule in FreeIPA)
---
* Ref: https://freeipa.readthedocs.io/en/latest/workshop/8-sudorule.html
* Study the 'ipa_add_sudo_rules.sh' script.

# Centralized Host Based Access Control
---
* Ref: https://freeipa.readthedocs.io/en/latest/workshop/4-hbac.html
* Ref: https://www.freeipa.org/page/Howto/HBAC_and_allow_all
* Study the 'ipa_grant_[group]_to_[hostgroup].sh' scripts.
* Study also the 'ipa_replace_default_allow_all_hbacrule.sh' script.

# Centralized Configuration - Install Puppet Enterprise

1. Login as run_user (gtay) at the controller (centos8) and clone the GIT Repo if it is not already done.
```bash
git clone https://github.com/garyttt/freeipa_puppet_foreman.git
cd freeipa_puppet_foreman/ansible
```
2. Edit 'PPM_IP' and provide the actual IP for your use case.
```bash
grep -iR PPM_IP: *
install_puppet_agent.yaml:    PPM_IP: "192.168.159.129"
install_puppet_master.yaml:    PPM_IP: "192.168.159.128"
puppet_agent_re_gen_csr.yaml:    PPM_IP: "192.168.159.129"
```
3. Run Ansible for Puppet Enterprise Install, provide admin password.
```bash
ansible-playbook -vv -i inventory/hosts -l puppet install_puppet_master.yaml -K
```
Inputs:
```
The Puppet Primary Master Admin Password:
```

4. If there is failure and re-installation is needed, run at the PE end:
---
Login as root:
```bash
puppet-enterprise-uninstaller
```
Ref: https://puppet.com/docs/pe/2019.8/uninstalling.html#uninstaller_options

5. It is highly recommended to apply SSL Cert to PE Console Service Web Server, please refer to:
https://puppet.com/docs/pe/2019.8/use_a_custom_ssl_cert_for_the_console.html

6. Else verify PE Console https://puppet.example.local

# Centralized Configuration - Install Foreman

1. Login as run_user (gtay) at the Foreman Server (foreman) and clone the GIT Repo if it is not already done.
```bash
git clone https://github.com/garyttt/freeipa_puppet_foreman.git
cd freeipa_puppet_foreman/ansible
```
Login as root at foreman:
```bash
./foreman_install_firewall_rules.sh
./foreman_install.sh
```
2. If there is failure and re-installation is needed, it is easier to rebuild VM and re-run the install scripts.
3. Else verify Foreman GUI https://foreman.example.local
4. Fine tune puppetserver within Foreman for performance, make the modifications as shown and restart puppetserver
```bash
[root@foreman ~]# diff /etc/sysconfig/puppetserver.orig /etc/sysconfig/puppetserver
9c9
< JAVA_ARGS="-Xms2G -Xmx2G -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger -XX:ReservedCodeCacheSize=512m"
---
> JAVA_ARGS="-Xms2G -Xmx2G -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger -XX:ReservedCodeCacheSize=1G -Djava.io.tmpdir=/var/tmp"
[root@foreman ~]#
[root@foreman ~]#
[root@foreman ~]#
[root@foreman ~]# diff /etc/puppetlabs/puppetserver/conf.d/puppetserver.conf.orig /etc/puppetlabs/puppetserver/conf.d/puppetserver.conf
71,72c71,72
<     environment-class-cache-enabled: false
<     multithreaded: false
---
>     environment-class-cache-enabled: true
>     multithreaded: true
[root@foreman ~]#
[root@foreman ~]#
[root@foreman ~]#
[root@foreman ~]# systemctl restart puppetserver
[root@foreman ~]# systemctl status puppetserver
● puppetserver.service - puppetserver Service
   Loaded: loaded (/usr/lib/systemd/system/puppetserver.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2021-11-25 01:57:32 EST; 7s ago
  Process: 10876 ExecStop=/opt/puppetlabs/server/apps/puppetserver/bin/puppetserver stop (code=exited, status=0/SUCCESS)
  Process: 10991 ExecStart=/opt/puppetlabs/server/apps/puppetserver/bin/puppetserver start (code=exited, status=0/SUCCESS)
 Main PID: 11017 (java)
    Tasks: 42 (limit: 4915)
   Memory: 1.0G
   CGroup: /system.slice/puppetserver.service
           └─11017 /usr/bin/java -Xms2G -Xmx2G -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger -XX:ReservedCodeCacheSize=1G -Djava.io.tmpdir=/var/tmp -XX:OnOutOfMemoryError=kill -9 %p -XX:Err>

Nov 25 01:57:14 foreman.example.local systemd[1]: puppetserver.service: Succeeded.
Nov 25 01:57:14 foreman.example.local systemd[1]: Stopped puppetserver Service.
Nov 25 01:57:14 foreman.example.local systemd[1]: Starting puppetserver Service...
Nov 25 01:57:32 foreman.example.local systemd[1]: Started puppetserver Service.
[root@foreman ~]#
```
---
It is highly recommended to apply SSL Cert to Foreman Apache Server (httpd).

# Install Puppet Agent at multiple remote hosts

1. Login as run_user (gtay) at the controller (centos8) and clone the GIT Repo if it is not already done.
```bash
git clone https://github.com/garyttt/freeipa_puppet_foreman.git
cd freeipa_puppet_foreman/ansible
```
2. Edit PPM_IP for your use case if applicable, default points to Foreman (.129), it can be Puppet Enterprise (.128)
```bash
grep -iR PPM_IP: *
install_puppet_agent.yaml:    PPM_IP: "192.168.159.129"
install_puppet_master.yaml:    PPM_IP: "192.168.159.128"
puppet_agent_re_gen_csr.yaml:    PPM_IP: "192.168.159.129"
```
3. Run Ansible for Puppet Agents Install.
Login as run_user (gtay)
```bash
ansible-playbook -vv -i inventory/hosts -l ppagents install_puppet_agents.yaml -K
```
4. If there is failure and re-installation is needed, run at the Puppet Agent end:
---
Login as root:
```bash
dnf remove -y puppet-agent
# or
apt-get remove -y puppet-agent
```

# Centralized Configuration (OS hardening, Audit and Compliance) - Install cis_profile puppet module

* Ref: https://github.com/garyttt/cis_profile

1. Login as root at puppet.example.local and/or foreman.example.local
2. Follow the instructions, it is as simple as running './install.sh'
```bash
git clone https://github.com/garyttt/cis_profile.git
cd cis_profile
./install.sh
```
After a few minutes, it is done.

Check 'puppet module list' for warnings or errors
If for some reason camptocamp-systemd was not installed to latest 3.0.0 level, perform the following clean-up and re-install fix:
```bash
# puppet module list
# cd /etc/puppetlabs/code/environments/production/modules
# rm -rf systemd
# puppet module install camptocamp-systemd
# puppet module list
```
Outputs:
```bash
[root@{puppet,foreman} ~]# puppet module list
/etc/puppetlabs/code/environments/production/modules
├── aboe-chrony (v0.3.2)
├── camptocamp-augeas (v1.9.0)
├── camptocamp-kmod (v2.5.0)
├── camptocamp-postfix (v1.12.0)
├── camptocamp-systemd (v3.0.0)
├── fervid-secure_linux_cis (v3.0.0)
├── gtay-cis_profile (v0.1.0)
├── herculesteam-augeasproviders_core (v2.7.0)
├── herculesteam-augeasproviders_grub (v3.2.0)
├── herculesteam-augeasproviders_pam (v2.3.0)
├── herculesteam-augeasproviders_shellvar (v4.1.0)
├── herculesteam-augeasproviders_sysctl (v2.6.2)
├── kemra102-auditd (v2.2.0)
├── puppet-alternatives (v3.0.0)
├── puppet-cron (v2.0.0)
├── puppet-firewalld (v4.4.0)
├── puppet-logrotate (v5.0.0)
├── puppet-nftables (v1.3.0)
├── puppetlabs-augeas_core (v1.2.0)
├── puppetlabs-concat (v7.1.1)
├── puppetlabs-firewall (v2.8.1)
├── puppetlabs-inifile (v5.2.0)
├── puppetlabs-mailalias_core (v1.1.0)
├── puppetlabs-mount_core (v1.1.0)
├── puppetlabs-ntp (v8.5.0)
├── puppetlabs-reboot (v2.4.0)
├── puppetlabs-stdlib (v7.0.0)
└── puppetlabs-translate (v2.2.0)
/etc/puppetlabs/code/modules (no modules installed)
/opt/puppetlabs/puppet/modules
├── puppetlabs-cd4pe_jobs (v1.5.0)
├── puppetlabs-enterprise_tasks (v0.1.0)
├── puppetlabs-facter_task (v1.1.0)
├── puppetlabs-facts (v1.4.0)
├── puppetlabs-package (v2.1.0)
├── puppetlabs-pe_bootstrap (v0.3.0)
├── puppetlabs-pe_concat (v1.1.1)
├── puppetlabs-pe_databases (v2.2.0)
├── puppetlabs-pe_hocon (v2019.0.0)
├── puppetlabs-pe_infrastructure (v2018.1.0)
├── puppetlabs-pe_inifile (v1.1.3)
├── puppetlabs-pe_install (v2018.1.0)
├── puppetlabs-pe_nginx (v2017.1.0)
├── puppetlabs-pe_patch (v0.13.0)
├── puppetlabs-pe_postgresql (v2016.5.0)
├── puppetlabs-pe_puppet_authorization (v2016.2.0)
├── puppetlabs-pe_r10k (v2016.2.0)
├── puppetlabs-pe_repo (v2018.1.0)
├── puppetlabs-pe_staging (v0.3.3)
├── puppetlabs-pe_support_script (v3.0.0)
├── puppetlabs-puppet_conf (v1.2.0)
├── puppetlabs-puppet_enterprise (v2018.1.0)
├── puppetlabs-puppet_metrics_collector (v7.0.5)
├── puppetlabs-python_task_helper (v0.5.0)
├── puppetlabs-reboot (v4.1.0)
├── puppetlabs-ruby_task_helper (v0.6.0)
└── puppetlabs-service (v2.1.0)
[root@{puppet,foreman} ~]#
```

# Reducing Puppet Agent Risks in causing OS crahses and SSH login issues

Many OS hardening Puppet Forge modules would contain rules to harden Firewall (host based likes iptables and nftables) and SSH related system settings (host based likes AllowUsers and AllowGroups in SSH Server Configs), these settings could cause server crashes and user login issues, and therefore it is better to exclude these in the HIERA data/os hierachies of OSNAME based Major_Release yaml files.

Please refer to a Shell script for the said risk mitigation, this script is executed as part of CIS Profile ./install.sh.
* https://github.com/garyttt/cis_profile/blob/main/10_disable_excluded_classes.sh

If you were to run this script manually one-time, prior to that please make a copy of common.yaml as shown in the script to common.pp.orig.
* cp -p /etc/puppetlabs/code/environments/production/modules/cis_profile/data/common.yaml /etc/puppetlabs/code/environments/production/modules/cis_profile/data/common.yaml.orig

# Reducing Puppet Agent Runtime in scanning for large number of files

Login as root at puppet.example.local and/or foreman.example.local

For practical reasons we should define EXCLUDES so as to reduce the runtime of Puppet Agent and save system resources.
```
[root@{puppet,foreman} files]# pwd
/etc/puppetlabs/code/environments/production/modules/secure_linux_cis/files
[root@{puppet,foreman} files]#
[root@{puppet,foreman} files]#
[root@{puppet,foreman} files]# diff ensure_no_ungrouped.sh.orig ensure_no_ungrouped.sh
2c2,9
< df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nogroup
---
> # Reasons to exclude:
> # /var/cache/private/fwupdmgr - Ubuntu Firmware Update Manager work files
> # /var/lib/docker/overlay2 - Docker work files
> # /var/lib/kubelet/pods - Kubernetes work files
> # /var/opt/microsoft/omsagent - Azure Linux VM cloud-init work files
> EXCLUDES="^/var/cache/private/fwupdmgr|^/var/lib/docker/overlay2|^/var/lib/kubelet/pods|^/var/opt/microsoft/omsagent"
> df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nogroup | egrep -v "$EXCLUDES"
>
[root@{puppet,foreman} files]#
[root@{puppet,foreman} files]#
[root@{puppet,foreman} files]#  diff ensure_no_unowned.sh.orig ensure_no_unowned.sh
2c2,9
< df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nouser
---
> # Reasons to exclude:
> # /var/cache/private/fwupdmgr - Ubuntu Firmware Update Manager work files
> # /var/lib/docker/overlay2 - Docker work files
> # /var/lib/kubelet/pods - Kubernetes work files
> # /var/opt/microsoft/omsagent - Azure Linux VM cloud-init work files
> EXLUDES="^/var/cache/private/fwupdmgr|^/var/lib/docker/overlay2|^/var/lib/kubelet/pods|^/var/opt/microsoft/omsagent"
> df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nouser | egrep -v "$EXCLUDES"
>
[root@{puppet,foreman} files]#
[root@{puppet,foreman} files]#
[root@{puppet,foreman} files]# diff ensure_no_world_writable.sh.orig ensure_no_world_writable.sh
1c1,9
< df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type f -perm -0002
---
> #!/bin/bash
> # Reasons to exclude:
> # /var/cache/private/fwupdmgr - Ubuntu Firmware Update Manager work files
> # /var/lib/docker/overlay2 - Docker work files
> # /var/lib/kubelet/pods - Kubernetes work files
> # /var/opt/microsoft/omsagent - Azure Linux VM cloud-init work files
> EXLUDES="^/var/cache/private/fwupdmgr|^/var/lib/docker/overlay2|^/var/lib/kubelet/pods|^/var/opt/microsoft/omsagent"
> df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type f -perm -0002 | egrep -v "$EXCLUDES"
>
```


# Centralized OS Hardening Dashboard - How to create cis_profile host-group in Foreman

Login to Foreman 3.0.1 GUI and refer to the doc:

* https://github.com/garyttt/freeipa_puppet_foreman/blob/main/ansible/Configure_CIS_Profile_for_Foreman.pdf

The doc describes the steps to define Host Group which is a logical grouping for all hosts to be OS Hardened, first we must import and update the 'production' environment puppet classes, then we add 'cis_profile' class to 'cis_profile' Host Group. After which we will select and add all hosts to 'cis_profile' Host Group.

The only Smart Class Parameter needs to be changed is:
* enforcement_level: from '1' to '2'

# Configure FreeIPA LDAP User Authentication for PE and Foreman and Softerra LDAP Browser

Please refer to:
* https://github.com/garyttt/freeipa_puppet_foreman/blob/main/ansible/Configure_FreeIPA_LDAP_Auth_for_PE_and_Foreman.pdf

Once the IPA 'ldapread' account has been created, you could also use it at the profile definition of Softerra LDAP Browser 4.5 which is a freeware for Windows desktop that makes IPA LDAP Browsing a walk in the garden.
* https://www.ldapadministrator.com/download.htm#browser

Definition of 'ipa.example.local' profile (Properties) in Softerra LDAP Browser 4.5:
* Host: ipa.example.local
* Port: 389 or 636
* BaseDN: dc=dev,dc=example,dc=local
* Use Secure Connection checked if port 636
* Other Credentials / Mechanisem: Simple
* Other Credentials / Principal: uid=ldapread,cn=users,cn=accounts,dc=dev,dc=example,dc=local
* Other Credentials / Password: ********
* Other Credentials / Save password checked
* Entry / Filters: (objectClass=*)
