#!/bin/bash
#Net Reinstall Centos System
#bash <(curl -s -S -L https://github.com/Marcotso/code/blob/main/DDCentOS.sh)
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
nicCard=$(ls /sys/class/net)
nicCard=(${nicCard})
d0Str='$0'
nicCardName=""
vnc_password=""
repo_url=""
ipaddr=""
gateway=""
netmask=""
bootRoot=""
run_script() {
if [ -f "/boot/initrd77.img" ]; then
  rm -rf /boot/initrd77.img
fi
wget -P /boot/ ${repo_url}images/pxeboot/initrd.img -O /boot/initrd77.img > /dev/null
if [ -f "/boot/vmlinuz77" ]; then
  rm -rf /boot/vmlinuz77
fi
wget -P /boot/ ${repo_url}images/pxeboot/vmlinuz -O /boot/vmlinuz77 > /dev/null
startDiskPart=$(cat /boot/grub2/grub.cfg |grep "set root" | head -n 1 |awk -F \' '{print $2}')
startDiskType=$(df -T /boot | awk '{print $2}' | sed -n '2p')
if [ "ext4" = "${startDiskType}" -o "ext3" = "${startDiskType}" ]
then
startDiskType="ext2"
fi
cat << EOF > /etc/grub.d/40_custom
#!/bin/sh
exec tail -n +3 ${d0Str}
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.
menuentry "NetInstall" {
        load_video
        set gfxpayload=keep
        insmod gzio
        insmod part_msdos
        insmod ${startDiskType}
        set root='${startDiskPart}'
 
        linux16 ${bootRoot}/vmlinuz77 inst.vnc inst.vncpassword=${vnc_password} inst.headless ip=${ipaddr}::${gateway}:${netmask}::${nicCardName}:none nameserver=1.1.1.1 inst.repo=${repo_url} inst.lang=en_US inst.keymap=us
  initrd16 ${bootRoot}/initrd77.img
}
EOF
if [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
  grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
fi
if [ -f "/boot/grub2/grub.cfg" ]; then
  grub2-mkconfig -o /boot/grub2/grub.cfg
fi
grub2-reboot NetInstall
reboot
 
}
 
input_nic() {
bootRoot=$(cat /boot/grub2/grub.cfg |grep "linux16" | head -n 1)
bootRoot=${bootRoot#*/}
bootRoot=${bootRoot:0:4}
if [ "boot" = "${bootRoot}" ]
then
bootRoot="/boot"
else
bootRoot=""
fi
while true
do
for ((i=1;i<=${#nicCard[@]};i++ )); do
    local_p="${nicCard[$i-1]}"
    echo -e "${green}${i}${plain}) ${local_p}"
done
read -p "????????????????????????[?????? 1]:" input_nic_no
[ -z "$input_nic_no" ] && input_nic_no=1
expr ${input_nic_no} + 1 &>/dev/null
if [ $? -ne 0 ]; then
    echo -e "[${red}??????:${plain}] ?????????????????????"
    continue
fi
if [[ "$input_nic_no" -lt 1 || "$input_nic_no" -gt ${#nicCard[@]} ]]; then
    echo -e "[${red}?????????${plain}] ????????????????????? 1 - ${#nicCard[@]}"
    continue
fi
nicCardName=${nicCard[$input_nic_no-1]}
break;
done
read -p "????????? VNC ??????[6 ???+][???????????? tg_jockerli]:" input_passwd
[ -z "${input_passwd}" ] && input_passwd="tg_jockerli"
vnc_password=${input_passwd}
read -p "????????? repo ??????[??????????????????????????????]:" input_repo
[ -z "${input_repo}" ] && input_repo="http://vault.centos.org/7.2.1511/os/x86_64/"
repo_url=${input_repo}
gateway=$(route -n | grep ${nicCardName} | grep UG | awk '{print $2}')
ipaddr=$(ifconfig eth0 | grep "inet" | awk -F " " '{print $2}' | head -n 1)
netmask=$(ifconfig eth0 | grep "inet" | awk -F " " '{print $4}' | head -n 1)
echo
echo "---------------------------"
echo -e "${green}???    ??? ${plain}= ${green}${nicCardName}${plain}"
echo -e "${green}IP  ?????? ${plain}= ${green}${ipaddr}${plain}"
echo -e "${green}???    ??? ${plain}= ${green}${gateway}${plain}"
echo -e "${green}???    ??? ${plain}= ${green}${netmask}${plain}"
echo "---------------------------"
echo -e "${green}VNC URL ${plain}= ${green}${ipaddr}:1${plain}"
echo "---------------------------"
echo -e "${green}VNC ?????? ${plain}= ${green}${vnc_password}${plain}"
echo -e "${yellow}VNC ??????????????? 6 ??????????????????????????????????????????${plain}"
echo "---------------------------"
echo -e "${green}repo ?????? ${plain}= ${green}${repo_url}${plain}"
echo "---------------------------"
echo -e "?????????${yellow}VNC ?????????????????????????????????????????????${plain}"
echo -e "     ${yellow}?????????????????????????????????[1]???????????????${plain}"
echo
read -p "???????????????????????????ctrl + c ??????????????????" input_read
run_script
}
init() {
if [ ! -f "/usr/bin/wget" ]; then
  yum -y install wget > /dev/null
fi
if [ ! -f "/usr/sbin/ifconfig" ]; then
  yum -y install net-tools > /dev/null
fi
input_nic
}
init
