#!/bin/bash

# exit when any command fails
#set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT


#Disabling iptables

echo "configuring firewall"

if grep -q -i "release 7" /etc/redhat-release ; then
systemctl stop firewalld
systemctl disable firewalld
systemctl stop NetworkManager
systemctl disable NetworkManager

else service stop iptables
chkconfig iptables off
fi
echo "done"
echo "-----------------------------------------------------------------------------------------------------------------------------------"

echo "checking kernel and Installing kernel kernel-headers and kernel-devel"

#centos7.0
yum install kernel-headers$(uname -r) -y
yum install kernel-devel$(uname -r) -y

echo "done"

echo "--------------------------------------------------------------------------------------------------------------------------------------"

echo "configuring SELINUX and Installing packages"

#Disabliing selinux
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

#Installing required packages
yum install epel-release net-tools bash-completion vim perl gcc make ntp open-vm-tools -y

#initiating bash completion
source /etc/profile.d/bash_completion.sh

echo "done"

echo "--------------------------------------------------------------------------------------------"
echo "Installing SNMP"

#Installing snmp packages
yum install net-snmp net-snmp-utils -y

#Adding rocommunity in snmpd.conf
sed -i '1 i\rocommunity supp0rt' /etc/snmp/snmpd.conf

#Enabling snmpd service
service snmpd enable
chkconfig snmpd on

#Restarting snmpd service
service snmpd restart

#Verifying the config with snmpwalk
snmpwalk -v 2c -c supp0rt localhost

#verifying tunlp
netstat -tunlp

echo "-------------------------------------------------------------------------------------------------"

#check the version of os and download veeam rpm

if grep -q -i "release 7" /etc/redhat-release ; then
yum install http://10.99.97.240/files/veeam-release-el7-1.0.5-1.x86_64.rpm -y

elif grep -q -i "release 6" /etc/redhat-release ; then
curl -O http://10.99.97.240/files/veeam-release-el6-1.0.5-1.x86_64.rpm
rpm -ivh veeam-release-el6-1.0.5-1.x86_64.rpm

fi

#Install veeam and veeamsnap
yum install veeam veeamsnap -y

#Restart veeam service
service veeamservice restart

#Enable veeam service
service veeamservice enable

#modprobe veeam module
modprobe veeamsnap

#check if the module is running
lsmod | grep veeamsnap

echo "-------------------------------------------------------------------------------------------------"

echo "Configuring NTP"

yum install ntp -y

service ntpd restart

chkconfig ntpd on

ntpdate -u -s 0.centos.pool.ntp.org 1.centos.pool.ntp.org 2.centos.pool.ntp.org

echo "--------------------------------------------------------------------------------------------------------------"

#ssh config script
#file effected /etc/ssh/sshd_config

#configuring permissions
chmod og-rwx /etc/ssh/sshd_config

sed -i 's/#Port 22/Port 5522/g' /etc/ssh/sshd_config /etc/ssh/sshd_config

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

echo "--------------------------------------------------------------------------------------------------------------"

echo "configuring rsyslog"

sed -i 's/*.info;mail.none;authpriv.none;cron.none/#.info;mail.none;authpriv.none;cron.none/g' /etc/rsyslog.conf /etc/rsyslog.conf

cat >>/etc/rsyslog.conf <<EOL
*.emerg :omusrmsg:* mail.* /var/log/mail
mail.info /var/log/mail.info
mail.warning /var/log/mail.warn
mail.err /var/log/mail.err
news.crit /var/log/news/news.crit
news.err /var/log/news/news.err
news.notice /var/log/news/news.notice
*.=warning;*.=err -/var/log/warn
*.crit /var/log/warn
*.*;mail.none;news.none -/var/log/messages
local0,local1.* -/var/log/localmessages
local2,local3.* -/var/log/localmessages
local4,local5.* -/var/log/localmessages
EOL


service rsyslog restart

chkconfig rsyslog on

echo "configuring permissions"
find /var/log -type f -exec chmod g-wx,o-rwx {} +

logrotate --force /etc/logrotate.conf

echo "------------------------------------------------------------------------------------------------------------------"

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
echo "Downloading and configuring init script for xen"
#cd to directory
cd /usr/local/src

#download script
curl -O http://10.99.97.240/files/init_scripts/centos_config-manager.sh

#making it executable
chmod +x centos_config-manager.sh

#adding the entry to rc.local
echo "/usr/local/src/centos_config-manager.sh" >> /etc/rc.d/rc.local

#makeing it executable
chmod +x /etc/rc.d/rc.local

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
