#!/bin/sh

#backup /etc/fstab
cp /etc/fstab /etc/fstab.bak
PARTITION_LIST="sdb1 sdc1 sdd1 sde1 sdf1 sdg1 sdh1 sdi1 sdj1 sdk1 sdl1 sdm1"
i=1
for PARTITION in $PARTITION_LIST
do
  UUID=`blkid "/dev/""$PARTITION" | awk '{print $2}' | sed 's/\"//g'`
  echo $UUID

  echo "add $PARTITION to /etc/fstab"
  MOUNTDIR="/data""$i"
  i=$((i + 1))
  echo "mkdir -p $MOUNTDIR"
  mkdir -p $MOUNTDIR

  echo "appending \"$UUID $MOUNTDIR xfs defaults 0 0\" to /etc/fstab "
  echo "$UUID $MOUNTDIR xfs defaults 0 0" >> /etc/fstab
  echo "" 
done

#mount all partitions
mount -a

#show mounted partitions
df -h

