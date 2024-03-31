# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
import subprocess
import logging

# 设置日志文件路径
log_filename = '/var/log/hive_merge_' + datetime.now().strftime('%Y%m%d') + '.log'
logging.basicConfig(filename=log_filename, level=logging.INFO, format='%(asctime)s %(levelname)s:%(message)s')

# 计算昨天的日期
yesterday = (datetime.now() - timedelta(1)).strftime('%Y%m%d')

# 分区值
partitions = ['A1', 'C1']

# Beeline连接信息
beeline_url = "jdbc:hive2://your_hive_server:10000/default"
beeline_user = "your_username"
beeline_password = "your_password"

# Hive SQL模板
sql_template = ("INSERT OVERWRITE TABLE your_table PARTITION (fab='{fab}', date='{date}') SELECT * FROM your_table "
                "WHERE fab='{fab}' AND date='{date}';")


# 生成并执行Hive SQL
def generate_and_execute_sql(fab, date):
    sql_command = sql_template.format(fab=fab, date=date)
    logging.info(f"Executing SQL for partition {fab}, {date}:")
    logging.info(sql_command)

    # 使用Beeline执行SQL
    try:
        beeline_command = (f"beeline -u '{beeline_url}' -n {beeline_user} -p {beeline_password} --silent=true "
                           f"--outputformat=csv2 --hiveconf mapreduce.job.queuename=your_queue_name --hiveconf "
                           f"hive.exec.dynamic.partition.mode=nonstrict -e \"{sql_command}\"")
        process = subprocess.Popen(beeline_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = process.communicate()
        if process.returncode == 0:
            logging.info("SQL executed successfully.")
        else:
            logging.error(f"Error executing SQL: {err}")
    except Exception as e:
        logging.error(f"Exception occurred: {e}")


# 主函数
def main():
    for fab in partitions:
        generate_and_execute_sql(fab, yesterday)


if __name__ == "__main__":
    main()

# --silent=true选项用于减少在执行过程中输出到控制台的不必要信息，例如进度信息。这可以使输出更加清晰，只显示查询结果或重要的错误信息。
# --outputformat=csv2选项指定了查询结果的输出格式。在这种情况下，它设置Beeline以CSV格式输出查询结果，其中csv2是一种特定的CSV格式，通常用于确保字段值中的逗号不会被错误地解释为字段分隔符。
# 这两个选项通常用于自动化脚本中，以便能够更容易地解析和处理Beeline的输出。

# 使用PySpark执行INSERT OVERWRITE命令合并Hive中的小文件后，如果HDFS中表目录下的文件数没有变化，可能有以下几个原因：
# Spark作业配置：确保您的Spark作业配置正确，特别是与分区和文件大小相关的设置。例如，spark.sql.files.maxPartitionBytes和spark.sql.shuffle.partitions等参数可能会影响输出文件的数量和大小。
# 动态分区：如果您的表是动态分区的，需要确保hive.exec.dynamic.partition和hive.exec.dynamic.partition.mode这两个参数被正确设置。如果设置为非严格模式（nonstrict），则允许所有分区列都是动态的。
# 文件合并策略：Spark有时可能不会合并小文件，这取决于它的文件合并策略。您可以尝试设置spark.sql.execution.mergeSmallFile.enabled为true来强制合并小文件。
# 作业执行：确认作业是否成功执行且没有错误。有时候，作业可能看起来已经完成，但实际上由于某些错误并没有成功执行。
# HDFS缓存：在某些情况下，HDFS的元数据缓存可能导致文件系统的视图延迟更新。您可以尝试刷新HDFS的元数据缓存或稍等一段时间再检查。
# 权限问题：确保您有足够的权限在HDFS上对应的目录中写入文件。权限不足可能会导致写入失败。
# 文件系统的延迟：在大型HDFS集群中，文件系统的更新可能会有延迟，特别是在高负载时。
