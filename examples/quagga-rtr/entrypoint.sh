#!/bin/sh

echo 'service integrated-vtysh-config' > /etc/quagga/vtysh.conf

echo 'Starting zebra and ospf daemons and applying configuration'
/usr/sbin/zebra -d 
/usr/sbin/ospfd -d
vtysh -b

echo 'Sleeping...'
tail -f /dev/null

