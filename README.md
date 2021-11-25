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

# Centralized UNIX Authentication: FreeIPA Primary and Secondary Master

Note: Secondary Master is a Replica Master with additional CA Server Install, at any one time either Primary Master or Secondary Master can play the role as CA Renewal Master Server via 'ipa-crlgen-manage enable' command.

1. Login as run_user (gtay) at the controller (centos8) and clone the GIT Repo.
```bash
git clone git@github.com:garyttt/freeipa_puppet_foreman.git
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
tail -100f /var/log/ipaserver-install.log
```
5. When it shows 'INFO The ipa-server-install command was successful', Ctrl-C to break the tailing, and restart IPA. If this is the first FreeIPA Server Install, enable it as the default CRL Generator.
---
Login as root:
```bash
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
tail -100f /var/log/ipareplica-install.log
```
10.  When it shows 'INFO The ipa-replica-install command was successful', Ctrl-C to break the tailing, and restart IPA.
---
Login as root at ipa2:
```bash
ipactl restart
ipactl status
```
11.   If there is failure and re-installation is needed:
---
Login as root at Primary Master:
```bash
ipa-replica-manage del ipa2.example.local --force
```
Login as root at Replica Master:
```bash
ipa-server-install --uninstall
dnf remove -y sssd-ipa 389-ds-core
```
12.   Else continue with CA Server Install, ensure CRL Generator status is 'disabled' as Primary Master is acting as it.
```bash
ipa-ca-install
ipa-crlgen-manage status
```
13.   Verify FreeIPA GUI https://ipa2.example.local/ipa/ui

14.   Note that as there is no DNS Server serving zone 'example.local', the following messages are normal.
```
ipaserver.dns_data_management: ERROR unable to resolve host name ipa.example.local. to IP address, ipa-ca DNS record will be incomplete
OR
Unknown host ipa.example.local: Host 'ipa2.example.local' does not have corresponding DNS A/AAAA record
OR
Unknown host ipa2.example.local: Host 'ipa2.example.local' does not have corresponding DNS A/AAAA record
```

# Install FreeIPA Client at multiple remote hosts

1. Login as run_user (gtay) at the controller (centos8) and clone the GIT Repo if it is not already done.
```bash
git clone git@github.com:garyttt/freeipa_puppet_foreman.git
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
git clone git@github.com:garyttt/freeipa_puppet_foreman.git
cd freeipa_puppet_foreman/ansible
kinit admin
bash -vx ./ipa_add_groups.sh
bash -vx ./ipa_add_users.sh
bash -vx ./ipa_add_groups_memberships.sh
```

# Two-Factoe Authentication 2FA (Global or Per-User)
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
git clone git@github.com:garyttt/freeipa_puppet_foreman.git
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
git clone git@github.com:garyttt/freeipa_puppet_foreman.git
cd freeipa_puppet_foreman/ansible
```
Login as root at foreman:
```bash
./foreman_install_firewall_rules.sh
./foreman_install.sh
```
2. If there is failure and re-installation is needed, it is easier to rebuild VM and re-run the install scripts.
3. Else verify Foreman GUI https://foreman.example.local
---
It is highly recommended to apply SSL Cert to Foreman Apache Server (httpd).

# Install Puppet Agent at multiple remote hosts

1. Login as run_user (gtay) at the controller (centos8) and clone the GIT Repo if it is not already done.
```bash
git clone git@github.com:garyttt/freeipa_puppet_foreman.git
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

