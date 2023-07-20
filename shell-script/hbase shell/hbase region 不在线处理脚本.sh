#!/bin/bash


# SetRegionState=CLOSED
for i in `cat /tmp/region_not_deployed_ testg_20210126000000.txt`
do
echo $i
hbase hbck -j ./hbase-hbck2-xxx.jar setRegionState $i CLOSED
done

# Reassign Regions
for i in `cat /tmp/region_not_ deployed_ testg_20210126000000.txt`
do
echo $i
hbase hbck -j ./hbase-hbck2-xxx.jar assigns $i
done