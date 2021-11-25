firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --permanent --add-port=67-69/udp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=3000/tcp
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --permanent --add-port=5910-5930/tcp
firewall-cmd --permanent --add-port=5432/tcp
firewall-cmd --permanent --add-port=8140/tcp
firewall-cmd --permanent --add-port=8443/tcp
firewall-cmd --reload

