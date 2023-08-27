import json
import re
from datetime import datetime, timedelta

# 示例 JSON 数据
input_file = r"C:\Users\帅鹏\Desktop\json_data.txt"
output_file = r"C:\Users\帅鹏\Desktop\json_data_sql_result.txt"
log_file = r"C:\Users\帅鹏\Desktop\hadoop-cmf-hive-HIVESERVER2-hadoop01.macro.com.log.out"

fi = open(input_file, 'r')
json_data = fi.read()

# 解析 JSON 数据
parsed_data = json.loads(json_data)


def change_time(time_8):
    # 示例日期时间字符串
    datetime_string = time_8
    # 解析日期时间字符串
    parsed_datetime = datetime.strptime(datetime_string, "%Y-%m-%dT%H:%M:%S.%fZ")
    # 将时区信息移除并加上8小时得到东八区时间
    eastern_datetime = parsed_datetime.replace(tzinfo=None) + timedelta(hours=8)
    # 格式化并只保留毫秒的前三位
    formatted_datetime = eastern_datetime.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
    return formatted_datetime


def find_thread_id(app_id):
    # 打开输入和输出文件
    thread_id = ""
    fr = open(log_file, 'r')
    for line in fr:
        thread_id_line = re.search(app_id, line)
        if thread_id_line:
            thread_id = line.split()[5][:-2]
            break
        else:
            thread_id = "none"
    # 关闭并重新打开输入文件，以重置文件指针位置
    fr.close()
    return thread_id


def extract_sql_from_log(ids):
    fs = open(log_file, 'r')
    log_data = fs.read()
    sql_list = []
    lines = log_data.split('\n')
    i = 0
    count = len(lines)

    while i < count:
        line = lines[i]
        if ids in line and "Executing command(queryId=" in line:
            sql = line.split("Executing command(queryId=")[-1]
            next_line = lines[i + 1]
            i += 1
            while ids not in next_line and next_line.strip():
                sql += next_line
                i += 1
                if i < count:
                    next_line = lines[i]
                else:
                    break
            sql_list.append(sql.strip())
        i += 1
    fs.close()

    return sql_list


# 将元素值写入文件
with open(output_file, 'w') as file:
    applications = parsed_data["applications"]

    for app in applications:
        pool = app['pool']
        if pool == "root.default":
            application_id = app['applicationId']
            sql = ""
            query_id = ""
            thread_id = find_thread_id(application_id)
            if thread_id == "none":
                thread_id = "none, The current application id does not exist in the log file."
                sql = "none, The current application id does not exist in the log file."
                query_id = "none, The current application id does not exist in the log file."
            else:
                sql_line = extract_sql_from_log(thread_id)
                count_sql_line = len(sql_line)
                if count_sql_line == 1:
                    query_id = sql_line[0].split("): ")[0]
                    sql = sql_line[0].split("): ")[-1]

            file.write(f"Application ID: {application_id}\n")
            file.write(f"Query ID: {query_id}\n")
            file.write(f"Thread ID: {thread_id}\n")
            file.write(f"SQL: {sql}\n")
            file.write(f"Name: {app['name']}\n")
            start_time = change_time(app['startTime'])
            file.write(f"Start Time: {start_time}\n")
            end_time = change_time(app['endTime'])
            file.write(f"End Time: {end_time}\n")
            file.write(f"User: {app['user']}\n")
            file.write(f"Pool: {pool}\n")
            file.write(f"State: {app['state']}\n")
            file.write(f"Progress: {app['progress']}\n")
            file.write("\n")


    # for app in applications:
    #     application_id = app['applicationId']
    #     sql = ""
    #     query_id = ""
    #     thread_id = find_thread_id(application_id)
    #     if thread_id == "none":
    #         thread_id = "none, The current application id does not exist in the log file."
    #         sql = "none, The current application id does not exist in the log file."
    #         query_id = "none, The current application id does not exist in the log file."
    #     else:
    #         sql_line = extract_sql_from_log(thread_id)
    #         count_sql_line = len(sql_line)
    #         if count_sql_line == 1:
    #             query_id = sql_line[0].split("): ")[0]
    #             sql = sql_line[0].split("): ")[-1]
    #
    #     file.write(f"Application ID: {application_id}\n")
    #     file.write(f"Query ID: {query_id}\n")
    #     file.write(f"Thread ID: {thread_id}\n")
    #     file.write(f"SQL: {sql}\n")
    #     file.write(f"Name: {app['name']}\n")
    #     start_time = change_time(app['startTime'])
    #     file.write(f"Start Time: {start_time}\n")
    #     end_time = change_time(app['endTime'])
    #     file.write(f"End Time: {end_time}\n")
    #     file.write(f"User: {app['user']}\n")
    #     file.write(f"Pool: {app['pool']}\n")
    #     file.write(f"State: {app['state']}\n")
    #     file.write(f"Progress: {app['progress']}\n")
    #     file.write("\n")

print("数据已写入文件。")
