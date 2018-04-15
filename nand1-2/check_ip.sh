#!/bin/sh

while [ 1 ]; do
    IsNetRun=`cat /sys/class/net/wlan0/carrier`
    if [ "$IsNetRun" == "1" ]; then
        touch ip_ok;
    else
        if [ -e ip_ok ]; then
            rm ip_ok;
        fi
    fi
    sleep 1
done
