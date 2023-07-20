#!/bin/sh
for i in {b..m}
do 
parted -s /dev/sd$i mklabel gpt
parted -s /dev/sd$i mkpart primary 2048s 100%
/usr/sbin/mkfs.xfs -f /dev/sd${i}1
done
