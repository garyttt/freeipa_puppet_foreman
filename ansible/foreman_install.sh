sudo yum -y install https://yum.puppet.com/puppet6-release-el-8.noarch.rpm
echo y | sudo dnf module reset ruby
echo y | sudo dnf module enable ruby:2.7
sudo yum -y install https://yum.theforeman.org/releases/3.0/el8/x86_64/foreman-release.rpm
sudo yum -y install foreman-installer
foreman-installer \
--foreman-initial-organization='example' \
--foreman-initial-location='local' \
--puppet-autosign-entries='*.example.local' \
--puppet-autosign-mode='0664' \
--puppet-splay=true \
--puppet-splaylimit=60s \
#--reset-foreman-server-ssl-ca \
#--foreman-server-ssl-cert /etc/pki/tls/certs/foreman.example.local.crt \
#--foreman-server-ssl-key /etc/pki/tls/private/foreman.example.local.key \
#--foreman-server-ssl-chain /etc/pki/tls/certs/gd_bundle-g2-g1.crt \
#--puppet-server-foreman-ssl-ca /etc/pki/tls/certs/gd_bundle-g2-g1.crt \
#--foreman-proxy-foreman-ssl-ca /etc/pki/tls/certs/gd_bundle-g2-g1.crt
