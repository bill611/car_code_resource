#!/bin/sh
/sbin/ifconfig eth0 down
/sbin/ifconfig eth0 172.16.50.10 netmask 255.255.0.0
/sbin/ifconfig eth0 hw ether 00:02:AC:55:89:A7
/sbin/route add default gw 172.16.1.1 dev eth0
/sbin/ifconfig eth0 up
