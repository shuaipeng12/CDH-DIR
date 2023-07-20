#!/bin/bash
#Created by shuaipeng@macrointel.cn
#Created data: 2022/12/12

#脚本参数提示
if test $# -ne 3
then
	echo USAGE: sh ./FSImage_Analyse.sh [keytabFilePath] [hs2_hostname] [hs2_port]
	echo keytabFilePath：hdfs的keytab文件路径
	echo hs2_hostname: hiveserver2实例所在主机的主机名/IP
	echo hs2_port: hiveserver2实例的端口
	echo EXAMPLE: sh ./FSImage_Analyse.sh /root/hdfs.keytab cdp2.macro.com 10099
	exit 0;
fi

keytabFilePath=$1
hs2_hostname=$2
hs2_port=$3
realm=`cat /etc/krb5.conf| grep default_realm|awk '{print $3}'`
disableLog="--hiveconf hive.server2.logging.operation.level=NONE"

#登录hdfs的keytab账号
hdfsPrincipal=`klist -ket $keytabFilePath | cut -f7 -d ' '|tail -n 1`
kinit -kt $keytabFilePath $hdfsPrincipal

#删除已存在的目录
mv /root/hdfs_Analyse /tmp > /dev/null 2>&1
hdfs dfs -rm -r /hdfs_Analyse/fsimage_txt > /dev/null 2>&1
rm -rf /tmp/fsimage.tmp > /dev/null 2>&1

#创建主目录
mkdir -p /root/hdfs_Analyse
path="/root/hdfs_Analyse"

#创建hdfs主目录
hdfs dfs -mkdir -p /hdfs_Analyse/fsimage_txt
hdfsPath="/hdfs_Analyse/fsimage_txt"

#获取nanenode的fsimage文件
echo "=========================Get the Image file from NameNode========================="
hdfs dfsadmin -fetchImage $path

#解析fsimage文件,使用 | 为分隔符
echo "=========================Analysis of Image file========================="
fsimageFileName=`basename ${path}/fsimage*`
hdfs oiv -p Delimited -delimiter '|' -t /tmp/fsimage.tmp -i  ${path}/${fsimageFileName} -o ${path}/fsimage.out
hdfs dfs -put ${path}/fsimage.out $hdfsPath

#在hive中建表并加载数据
echo "=========================Build tables and load data========================="
beeline $disableLog  -u "jdbc:hive2://${hs2_hostname}:${hs2_port}/;principal=hive/${hs2_hostname}@${realm}" -f ./hive-script.hql


#查询内部表统计小文件结果
echo "需要从 hdfs的根目录即目录层级为1（depath = 1）开始查询小文件,根据根目录的查询结果选择几个小文件数量较多的目录作为目录层级为2（depath = 2）查询下一级目录的小文件，依此类推。"
echo "查询根目录示例：select path, count(1) as cnt from file_info where fsize <= 30000000 and path like '/%' and depth = 1 group by path order by cnt desc limit 20;"
echo "查询第二级目录示例：select path, count(1) as cnt from file_info where fsize <= 30000000 and path like '/user/%' and depth = 2 group by path order by cnt desc limit 20;"
