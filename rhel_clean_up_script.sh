#!/bin/bash

#Deleting udev-rules entry of the Interface Name
sed -i '$d' /etc/udev/rules.d/70-persistent-net.rules


#Clear the logs of /var/log
truncate --size 0 /var/log/* # first-level logs
truncate --size 0 /var/log/**/* # nested folders, like /var/log/nginx/access.log
truncate --size 0 /var/log/**/**/* # nested folders, like /var/log/nginx/enlight/access.log

truncate --size 0 /etc/sysconfig/network-scripts/ifcfg-eth0
truncate --size 0 /root/.bash_history


yum clean all
rm -rf /var/cache/yum/

# Remove ssh keys
/bin/rm -f /etc/ssh/*key*

# Remove root's SSH history and other cruft
/bin/rm -rf ~root/.ssh/
/bin/rm -f ~root/anaconda-ks.cfg
