#check if the correct kernel headers-devel package is installed
kernel_devel=`rpm -qa |grep kernel-devel-$(uname -r)| cut -d '-' -f3,4`
kernel_headers=`rpm -qa |grep kernel-headers-$(uname -r)| cut -d '-' -f3,4`
kernel=`uname -r`


if [[ $kernel_devel == $kernel && $kernel_headers == $kernel ]]; then
echo "correct kernel headers-devel is present"

else echo "no kernel headers-devel package present"
exit 1
fi
