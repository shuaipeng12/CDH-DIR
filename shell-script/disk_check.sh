#!/bin/sh

echo "https://zhuanlan.zhihu.com/p/458276937"
echo "https://www.jianshu.com/p/3991c0dba094"

echo "|load average: 0.00, 0.00, 0.00  |系统负载，即任务队列的平均长度。 三个数值分别为 1分钟、5分钟、15分钟前到现在的平均值" >> ./top_res.log
echo "|0 zombie  |僵尸进程数">> ./top_res.log
echo "|0.0%ni    |用户进程空间内改变过优先级的进程占用CPU百分比">> ./top_res.log
echo "|100.0%id  |空闲CPU百分比">> ./top_res.log
echo "|0.0%wa    |等待输入输出的CPU时间百分比">> ./top_res.log
echo "|0.0%hi    |硬中断（Hardware IRQ）占用CPU的百分比">> ./top_res.log
echo "|0.0%si    |软中断（Software Interrupts）占用CPU的百分比">> ./top_res.log
echo "|0.0 st    |用于有虚拟cpu的情况，用来指示被虚拟机偷掉的cpu时间">> ./top_res.log
echo "|PR        |优先级">> ./top_res.log
echo "|NI        |nice值。负值表示高优先级，正值表示低优先级">> ./top_res.log
echo "|VIRT      |进程使用的虚拟内存总量，单位kb。VIRT=SWAP+RES">> ./top_res.log
echo "|RES       |进程使用的、未被换出的物理内存大小，单位kb。RES=CODE+DATA">> ./top_res.log
echo "|SHR       |共享内存大小，单位kb">> ./top_res.log
echo "|S |进程状态。D=不可中断的睡眠状态 R=运行 S=睡眠 T=跟踪/停止 Z=僵尸进程">> ./top_res.log
echo "|%CPU      |上次更新到现在的CPU时间占用百分比">> ./top_res.log
echo "|%MEM      |进程使用的物理内存百分比">> ./top_res.log
echo "|TIME+     |进程使用的CPU时间总计，单位1/100秒">> ./top_res.log
echo " " >> ./top_res.log

echo "|%user  |CPU在用户态执行进程的时间百分比。" >> ./iostat_res.log
echo "|%nice  |CPU在用户态模式下，用于nice操作，所占用CPU总时间的百分比" >> ./iostat_res.log
echo "|%system  |CPU处在内核态执行进程的时间百分比" >> ./iostat_res.log
echo "|%iowait  |CPU用于等待I/O操作占用CPU总时间的百分比" >> ./iostat_res.log
echo "|%steal  |管理程序(hypervisor)为另一个虚拟进程提供服务而等待虚拟CPU的百分比" >> ./iostat_res.log
echo "|%idle  |CPU空闲时间百分比" >> ./iostat_res.log
echo "|rrqm/s  |每秒对该设备的读请求被合并次数，文件系统会对读取同块(block)的请求进行合并" >> ./iostat_res.log
echo "|wrqm/s  |每秒对该设备的写请求被合并次数" >> ./iostat_res.log
echo "|r/s  |每秒完成的读次数" >> ./iostat_res.log
echo "|w/s  |每秒完成的写次数" >> ./iostat_res.log
echo "|rkB/s  |每秒读数据量(kB为单位)" >> ./iostat_res.log
echo "|wkB/s  |每秒写数据量(kB为单位)" >> ./iostat_res.log
echo "|avgrq-sz  |平均每次IO操作的数据量(扇区数为单位)" >> ./iostat_res.log
echo "|avgqu-sz  |平均等待处理的IO请求队列长度" >> ./iostat_res.log
echo "|await  |平均每次IO请求等待时间(包括等待时间和处理时间，毫秒为单位)" >> ./iostat_res.log
echo "|svctm  |平均每次IO请求的处理时间(毫秒为单位)" >> ./iostat_res.log
echo "|%util  |采用周期内用于IO操作的时间比率，即IO队列非空的时间比率" >> ./iostat_res.log
echo " " >> ./iostat_res.log

while : 
do
	cur_time=$(date "+%Y-%m-%d %H:%M:%S")
	time_cur=`date -d "$cur_time" +%s`

	echo $cur_time >> ./top_res.log
	top -b -n 1 >> ./top_res.log
	echo " " >> ./top_res.log

	echo $cur_time >> ./iostat_res.log
	iostat -m -x 1 1 >> ./iostat_res.log

	echo $cur_time >> ./pidstat_res.log
	pidstat -d  1 1 >> ./pidstat_res.log
	
	stop_time="2023-10-07 01:49:00"
	time_stop=`date -d "$stop_time" +%s`
	if [ $time_cur -gt $time_stop ]
	then
		echo "exit"
		break
	fi 
	
	sleep 60
done

