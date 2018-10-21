#!/bin/sh

# Setting the device index (randomising if arguments are incorrect)
if [ $# != 1 ]; then
  IDX=$(shuf -i 1-100 -n 1)
else 
  IDX=$1
fi

# Starting Zebra
touch /etc/quagga/zebra.conf
/usr/sbin/zebra -d -f /etc/quagga/zebra.conf

cat << EOF >> /etc/quagga/ospf.conf
interface lo0
  ip address 198.51.100.$IDX
!
router ospf
 network 0.0.0.0/0 area 0.0.0.0
!
EOF

# Starting OSPF daemon
/usr/sbin/ospfd -d -f /etc/quagga/ospf.conf
