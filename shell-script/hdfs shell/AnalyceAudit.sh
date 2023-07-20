#!/bin/bash
# Created By shuaipeng@macrointel.cn
# Created date: 2022/12/9

#脚本参数提示
if test $# -ne 3
then
        echo USAGE: sh ./AnalyceAudit.sh [logPath] [outPath] [Nproc]
	echo logPath: hdfs的audit日志源文件路径
	echo outPath: 解析后的csv文件输出路径
	echo Nproc: 脚本最大进程数
        echo EXAMPLE: sh ./AnalyceAudit.sh /root/namenodeAudit/hdfs-audit.log /root/namenodeAudit/hdfs-audit.csv 10
        exit 0;
fi


Nproc=$3 #最大并发进程数

function PushQue { #将PID值追加到队列中
	Que="$Que $1"
	Nrun=$(($Nrun+1))
}

function GenQue { #更新队列信息，先清空队列信息，然后检索生成新的队列信息
	OldQue=$Que
	Que=""; Nrun=0
	for PID in $OldQue; do
		if [[ -d /proc/$PID ]]; then
			PushQue $PID
		fi
	done
}

function ChkQue { #检查队列信息，如果有已经结束了的进程的PID，那么更新队列信息
	OldQue=$Que
	for PID in $OldQue; do
		if [[ ! -d /proc/$PID ]]; then
			GenQue; break
		fi
	done
}

logPath=$1
outPath=$2

#修改循环默认的分隔符为换行符
IFS_old=$IFS
IFS=$'\n'

#循环获取每一行的每一部分，使用逗号拼接并写入到csv格式的文件中
for line in `cat $logPath`
do
        date=`echo $line|awk '{print $1}'`
	datetime=`echo $line|awk '{print $2}'`
        logLevel=`echo $line|cut -f 3 -d ' '`
        state=`echo $line|awk '{print $4,$5}'`
        userAndAuth=`echo $line|awk '{print $6,$7}'`
        ip=`echo $line|awk '{print $8}'`
        cmd=`echo $line|awk '{print $9}'`
        src=`echo $line|awk '{print $10}'`
        dst=`echo $line|awk '{print $11}'`
        perm=`echo $line|awk '{print $12}'`
        proto=`echo $line|awk '{print $13}'`
        callerContext=`echo $line|awk '{print $14}'`


        if [ -z "$callerContext" ]
        then
                echo -e "$date,$datetime,$logLevel,$state,$userAndAuth,$ip,$cmd,$src,$dst,$perm,$proto" >> $outPath
        else
                echo -e "$date,$datetime,$logLevel,$state,$userAndAuth,$ip,$cmd,$src,$dst,$perm,$proto,$callerContext" >> $outPath
        fi
	
	sleep 1 &
	PID=$!
	PushQue $PID
        while [[ $Nrun -ge $Nproc ]]; do # 如果Nrun大于Nproc，就一直ChkQue
                ChkQue
                sleep 0.1
        done

done

wait
echo -e "time-consuming: $SECONDS seconds" #显示脚本执行耗时
IFS=$IFS_old #将循环分隔符修改回默认的
