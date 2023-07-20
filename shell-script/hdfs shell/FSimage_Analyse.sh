#!/bin/bash
#Created by shuaipeng@macrointel.cn
#Created data: 2022/12/12


脚本自己读配置文件判断fsimage文件路径，	自己读配置文件文件做kerberos认证（区分kerberos环境和非kerberos环境），beeline连接hive默认使用hive用户，预留一个自定义用户的接口
查询结果写入文件中，不允许有mv和rm操作

readonly hadoopcoreconf="/etc/hadoop/conf/core-site.xml"
readonly hadoophdfsconf="/etc/hadoop/conf/hdfs-site.xml"
readonly hiveconf="/etc/hive/conf/hive-site.xml"
readonly krbconf="/etc/krb5.conf"
readonly tmpdir="/tmp"
readonly hdfsdir="/hdfs_Analyse/fsimage_txt"
readonly linuxdir="/root/hdfs_Analyse"
readonly kadminhost=`grep admin_server ${krbconf} | awk NR==2'{print $3}'`
readonly realm=`cat ${krbconf} | grep default_realm|awk '{print $3}'`
disableLog="--hiveconf hive.server2.logging.operation.level=NONE"
cmhost=`grep server_host /etc/cloudera-scm-agent/config.ini | cut -f2 -d '='`
beelinesite="/etc/hive/conf/beeline-site.xml"

#读配置文件区分是否是kerberos环境
IsKrbEnv() { 
	iskerberos=`grep kerberos ${hadoopcoreconf} | cut -f2 -d '>'|cut -f1 -d '<'`
	if [ $iskerberos = "kerberos" ]; then
		echo "集群已启用kerberos"
		UserAuth
		
	else
		echo "集群未启用kerberos"
		
	fi
}	



#如果启用了kerberos，则需要认证kerberos用户才能执行hdfs命令和hive命令，这里需要留一个自定义用户的接口
UserAuth() { 
	while true
	do
		read -p "请输入kerberos认证用户名，例如：[hdfs/hive]" readline
		local principal="${readline}@${realm}"
		local istrue=`kadmin.local -s ${kadminhost} -q "listprincs ${principal}" | awk NR==2`
		if [[ ${istrue} = ${principal} ]]; then
			
			#此kerberos用户存在，需要导出keytab文件用于认证
			kadmin.local -s ${kadminhost} -q "ktadd -k ${tmpdir}/${readline}.keytab -norandkey ${principal}"
			kinit -kt ${tmpdir}/${readline}.keytab ${principal}
			klist
			break
			
		else
			echo "您输入的用户不存在，请重新输入！"
		fi
}

#获取fsimage文件，并解析成以 | 分割的文件，上传到hdfs中以便hive加载数据
GetFsimage() { 

	#判断本地目录是否存在
	if [[ -d ${linuxdir} ]]; then
		echo "${linuxdir}目录已存在,请删除此目录或者修改脚本 linuxdir 变量！"
	else
		mkdir -p ${linuxdir}
		hdfs dfsadmin -fetchImage ${linuxdir}
	fi
	
	#判断hdfs目录是否存在
	hdfs dfs -test -d ${hdfsdir}
	if [[ $? -eq 0 ]]; then
		echo "hdfs目录已经存在，请删除此目录或者修改脚本 hdfsdir 变量"
	else
		hdfs dfs -mkdir -p ${hdfsdir}
		echo "=========================Get the Image file from NameNode========================="
		local fsimageFileName=`basename ${linuxdir}/fsimage*`
		hdfs oiv -p Delimited -delimiter '|' -t /tmp/fsimage.tmp -i ${linuxdir}/${fsimageFileName} -o ${linuxdir}/fsimage.out
		hdfs dfs -put ${linuxdir}/fsimage.out ${hdfsdir}
	fi
}


#确定beeline连接串
ConnectString() {

	#从hive-site.xml配置文件中拿出 “hive.server2.authentication.kerberos.principal” 的值作为连接串的 principal
	hs2principal=`grep '@' ${hiveconf} | awk -F'>' NR==2'{print $2}' | cut -f1 -d '<'`
	
	#这里的hiveserver2实例的地址通过 /etc/hive/conf/beeline-site.xml配置文件的 “beeline.hs2.jdbc.url.hive_on_tez” 参数得到
	#这个配置文件在CDH中好像没有，在CDP中有
	hs2_host=`grep "jdbc:hive2" ${beelinesite} | awk -F'>' '{print $2}' | cut -f1 -d ';' | sed -n s/2181/10000/gp`
	
	connectstr="${hs2_host};${hs2principal}"
	
	#通过 API 拿出hiveserver的 load balancer 配置的地址
	#curl -u admin:admin http://"${cmhost}":7180/api/v31/clusters/Cluster%201/services/hive_on_tez/roleConfigGroups/hive_on_tez-HIVESERVER2-BASE/config > ${tmpdir}/balancer.txt
	#hahost=`cat ${tmpdir}/balancer.txt | awk -F'"' NR==8'{print $4}'`
	
	# 判断 hahost等于 false，表示没有启用hiverserver2的高可用 ， 连接串直接使用hiveserver2实例的主机名和 10000端口，否则就用高可用配置的地址
	#if [[ $hahost = "false" ]]; then
	
		#这里的hiveserver2实例的地址通过 /etc/hive/conf/beeline-site.xml配置文件的 “beeline.hs2.jdbc.url.hive_on_tez” 参数得到
		#这个配置文件在CDH中好像没有，在CDP中有
		#hs2_host=`grep "jdbc:hive2" ${beelinesite} | awk -F'>' '{print $2}' | cut -f1 -d ';' | sed -n s/2181/10000/gp`
		#connectstr="${hs2_host};${hs2principal}"
	#else
		#connectstr="${hahost}/;${hs2principal}"
	#fi
}


#在hive中建表以加载数据，并建立内部表，连接hive默认使用hive用户，除非用户自定义
CreateOnHive() { 
	while true
	do
		
		#beeline 连接hive默认使用hive用户，除非用户自定义
		#检查当前认证的kerberos用户
		local authuser=`klist | grep "Default principal" | awk '{print $3}' | cut -f1 -d '@'`
		if [[ ${authuser} = "hive" ]]; then
			echo "当前认证用户为 ${authuser} "
			echo "=========================Build tables and load data========================="
			beeline ${disableLog}  -u ${connectstr} -f ./hive-script.hql
			break
			
		else
			read -p "下面将要在hive中建表，当前认证的kerberos用户为 ${authuser}，是否自定义？ [yes/no] :"  readyes
			if [[ ${readyes} = "yes" ]]; then
				UserAuth
			elif [[ ${readyes} = "no" ]]; then
				echo "当前认证用户为 ${authuser} "
				echo "=========================Build tables and load data========================="
				beeline ${disableLog}  -u ${connectstr} -f ./hive-script.hql
				break
				
			else
				echo "您的输入有误，请重新输入！"
			fi
	done	
}

#查询hive内部表，统计各个目录层级的小文件数量，并写入到文件中，连接hive默认使用hive用户，除非用户自定义
CountFile() { 
	

}


 `
第一个函数功能：根据初始的路径数组中的路径（根路径）查找一层目录的小文件数量，将查找结果输出到一个文件中。
第二个函数功能：判断第一个函数输出结果中的小文件数量大小，大于某一个值的路径覆盖到数组中，共第一个函数再次调用

#定义一个数组,初始值为根路径
filepath=("/%")
depathNum=1

function smartFileNum {  #根据路径数组中的路径查找小文件数量并将结果写入文件中
	#循环获取数组中的所有元素（路径），并给每一个路径都查找一次小文件，结果追加输出到文件中
	for i in ${filepath[*]};do
		beeline $disableLog  -u "jdbc:hive2://${hs2_hostname}:${hs2_port}/;principal=hive/${hs2_hostname}@${realm}" -e 
		"select path, count(1) as cnt from file_info where fsize <= 30000000 and path like $i and depth = $depathNum 
		group by path order by cnt desc limit 20;" >> ./result_${depathNum}.txt
	done
	valueSize
	depathNum=`expr $depathNum + 1`
	smartFileNum
}

function valueSize { #判断第一个函数输出的结果中的cnt值大小，大于某个值的路径覆盖写入到路径数组中
	

}
