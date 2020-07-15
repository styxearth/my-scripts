#!/bin/bash


#configuring permissions
chmod og-rwx /etc/ssh/sshd_config

sed -i 's/#LogLevel INFO/LogLevel INFO/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

sed -i 's/#Protocol 2/Protocol 2/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

sed -i 's/#MaxAuthTries 6/MaxAuthTries 4/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

sed -i 's/#IgnoreRhosts yes/IgnoreRhosts yes/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

sed -i 's/#HostbasedAuthentication no/HostbasedAuthentication no/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 0/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

sed -i 's/#Banner none/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

echo "--------------------------------------------------------------------------------------------------------------"
echo "configuring sysctl.conf"

cat >>/etc/sysctl.conf <<EOL
net.ipv4.tcp_tw_reuse=0
net.ipv4.tcp_tw_recycle=0
kernel.shmall = 4294967296
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

#Source routed packets are not accepted
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

#ICMP redirects are not accepted
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

#Logging of Spoofed Packets,Source Routed Packets,Redirect Packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

#Broadcast ICMP requests are ignored
net.ipv4.icmp_echo_ignore_broadcasts = 1

#Bad Error Message Protection
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

#IPv6 router advertisements are not accepted
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

#IPv6 redirects are not accepted
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
fs.suid_dumpable = 0

#TCP SYN Cookie Protection
net.ipv4.tcp_syncookies = 1

#Disable ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOL

#To make the settings affective
sysctl -p


echo "----------------------------------------------------------------------------------------------------------"


echo "configuring ssh warning"

cat >/etc/issue.net <<EOL
#########################################################################################################
# #
# Authorized users only. All activity may be monitored and reported. #
# #
#########################################################################################################
EOL


sed -i 's/#Banner none/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

service sshd restart

echo "-------------------------------------------------------------------------------------------------------------------"

echo "configuring hosts.allow"
cat >> /etc/hosts.allow <<EOL
sshd : ALL : allow
ALL : DENY
EOL

echo "-------------------------------------------------------------------------------------------------------------------"
echo "Downloading and configuring init script"
#cd to directory
cd /usr/local/src

#download script
curl -O http://10.99.97.240/files/init_scripts/suse_12_config_manager.sh

#making it executable
chmod +x suse_12_config_manager.sh

#adding the entry to rc.local
echo "/usr/local/src/suse_12_config_manager.sh" >> /etc/rc.d/boot.local

#makeing it executable
chmod +x /etc/rc.d/boot.local

echo "-------------------------------------------------------------------------------------------------------------------"

echo "configuring permissions"

chown root:root /etc/cron.hourly
chmod og-rwx /etc/cron.hourly

chown root:root /etc/cron.daily
chmod og-rwx /etc/cron.daily

chown root:root /etc/cron.weekly
chmod og-rwx /etc/cron.weekly

chown root:root /etc/crontab
chmod og-rwx /etc/crontab

echo "complete"

echo "---------------------------------------------------------------------------------------"

echo "configuring permissions"

find /var/log -type f -exec chmod g-wx,o-rwx {} +
