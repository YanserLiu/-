#!/bin/sh
CONFIG='/etc/sysconfig/network-scripts/ifcfg-sit6to4'
CONROUTE='/etc/sysconfig/network-scripts/route6-sit6to4'
SYSCTL='/etc/sysctl.conf'

if [[ -z $1 ]]; then
    echo "usage: ./set_ipv6.sh YOUR_IP"
    exit 1
fi

IPV4=$1

ip a|grep -q $IPV4
if [[ $? -ne 0 ]];then
    echo "ipv4 address '$IPV4' is not exist!"
    exit 2
fi

IPV6=2002:`echo "${IPV4}" |awk -F '.' '{printf "%02x%02x:%02x%02x\n",$1,$2,$3,$4}'`::1

ip a|grep -q $IPV6
if [[ $? -eq 0 ]];then
    echo "ipv6 address '$IPV6' is already exist!"
    exit 0
fi

if [[ -d /etc/sysctl.d ]];then

cat > $SYSCTL <<EOF
net.ipv6.conf.all.disable_ipv6 = 0
EOF

else

grep "net.ipv6.conf.all.disable_ipv6 = 0" $SYSCTL
    if [[ $? -ne 0 ]];then
cat >> $SYSCTL <<EOF
net.ipv6.conf.all.disable_ipv6 = 0
EOF
    fi

fi

cat > $CONFIG <<EOF
DEVICE=sit6to4
TYPE=sit
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
IPV6INIT=yes
IPV6TUNNELIPV4=any
IPV6TUNNELIPV4LOCAL=$IPV4
IPV6ADDR=$IPV6/128
EOF

cat > $CONROUTE <<EOF
2002:c0a8::/32 dev sit6to4 src $IPV6 metric 8
2002:ac10::/28 dev sit6to4 src $IPV6 metric 8
EOF

sysctl net.ipv6.conf.all.disable_ipv6=0

ifup sit6to4

ping6 -w3 -c1 2002:ac1c:b401:1::1 >/dev/null

if [[ $? -ne 0 ]];then
    echo "ping test failed!"

    ifdown sit6to4

    echo -e "\033[31m !!! ipv6 setup Failed !!! \033[0m"
    exit 3
else
    echo -e "\033[32m !!! ipv6 setup Success !!! \033[0m"
fi

