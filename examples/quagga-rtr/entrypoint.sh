#!/bin/sh

# Setting the device index (randomising if arguments are incorrect)
#if [ $# != 1 ]; then
#  IDX=$(shuf -i 1-100 -n 1)
#else 
#  IDX=$1
#fi

# Starting Zebra
if [ ! -f /etc/quagga/zebra.conf ]; then
  echo 'Creating empty zebra.conf'
  touch /etc/quagga/zebra.conf
fi
/usr/sbin/zebra -d -f /etc/quagga/zebra.conf

#ip add add 198.51.100.$IDX/32 dev lo

cat << EOF >> /etc/quagga/ospf.conf
!
router ospf
 network 0.0.0.0/0 area 0.0.0.0
 passive-interface eth0
!
EOF

# Starting OSPF daemon
/usr/sbin/ospfd -f /etc/quagga/ospf.conf
