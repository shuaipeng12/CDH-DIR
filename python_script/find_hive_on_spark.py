import re
from datetime import datetime

# 输入和输出文件路径
input_log_file = r"C:\Users\帅鹏\Desktop\hadoop-cmf-hive-HIVESERVER2-hadoop01.macro.com.log.out"
output_file = r"C:\Users\帅鹏\Desktop\find_hive_on_spark.txt"


def find_thread_id():
    # 打开输入和输出文件
    input_file = open(input_log_file, 'r')
    thread_id_list = []  # 用于保存 thread_id
    for line in input_file:
        session = re.search("Trying to open Hive on Spark session", line)
        if session:
            thread_id = line.strip().split()[5][:-2]
            thread_id_list.append(thread_id)
    # 关闭并重新打开输入文件，以重置文件指针位置
    input_file.close()
    return thread_id_list


def extract_sql_from_log(ids):
    fs = open(input_log_file, 'r')
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


def extract_start_time(ids):
    fs = open(input_log_file, 'r')
    log_data = fs.read()
    info_list = []
    lines = log_data.split('\n')
    i = 0

    while i < len(lines):
        line = lines[i]
        if ids in line and "start time:" in line:
            start_time = line.split("start time: ")[-1].strip()
            next_line = lines[i + 1]
            i += 1
            while ids not in next_line and next_line.strip():
                start_time += next_line
                i += 1
                if i < len(lines):
                    next_line = lines[i]
                else:
                    break
            info_list.append(start_time)
        i += 1
    fs.close()
    return info_list


def extract_queue(ids):
    fs = open(input_log_file, 'r')
    log_data = fs.read()
    info_list = []
    lines = log_data.split('\n')
    i = 0

    while i < len(lines):
        line = lines[i]
        if ids in line and "queue:" in line:
            queue = line.split("queue: ")[-1].strip()
            next_line = lines[i + 1]
            i += 1
            while ids not in next_line and next_line.strip():
                queue += next_line
                i += 1
                if i < len(lines):
                    next_line = lines[i]
                else:
                    break
            info_list.append(queue)
        i += 1
    fs.close()
    return info_list


def extract_user(ids):
    fs = open(input_log_file, 'r')
    log_data = fs.read()
    info_list = []
    lines = log_data.split('\n')
    i = 0

    while i < len(lines):
        line = lines[i]
        if ids in line and "user:" in line:
            user = line.split("user: ")[-1].strip()
            next_line = lines[i + 1]
            i += 1
            while ids not in next_line and next_line.strip():
                user += next_line
                i += 1
                if i < len(lines):
                    next_line = lines[i]
                else:
                    break
            info_list.append(user)
        i += 1
    fs.close()
    return info_list


def extract_application_id(ids):
    fs = open(input_log_file, 'r')
    log_data = fs.read()
    info_list = []
    lines = log_data.split('\n')
    i = 0

    while i < len(lines):
        line = lines[i]
        if ids in line and "tracking URL:" in line:
            application_id = line.split("tracking URL: ")[-1].strip()
            next_line = lines[i + 1]
            i += 1
            while ids not in next_line and next_line.strip():
                application_id += next_line
                i += 1
                if i < len(lines):
                    next_line = lines[i]
                else:
                    break
            info_list.append(application_id)
        i += 1
    fs.close()
    return info_list


def main():
    fw = open(output_file, 'w')
    thread_id = find_thread_id()
    for ids in thread_id:
        query_id = ""
        sql = ""
        formatted_datetime = ""
        queue = ""
        user = ""
        application_id = ""
        start_time_line = extract_start_time(ids)
        count_start_time = len(start_time_line)
        if count_start_time == 1:
            start_time = start_time_line[0]
            # 转换为 datetime 对象
            timestamp_datetime = datetime.fromtimestamp(int(start_time) / 1000)  # 将毫秒转换为秒
            # 格式化为字符串
            formatted_datetime = timestamp_datetime.strftime('%Y-%m-%d %H:%M:%S')

        queue_line = extract_queue(ids)
        count_queue = len(start_time_line)
        if count_queue == 1:
            queue = queue_line[0]

        user_line = extract_user(ids)
        count_user = len(user_line)
        if count_user == 1:
            user = user_line[0]

        application_id_line = extract_application_id(ids)
        count_app = len(application_id_line)
        if count_app == 1:
            application_id = application_id_line[0].split("/")[-2]

        sql_line = extract_sql_from_log(ids)
        count_sql_line = len(sql_line)
        if count_sql_line == 1:
            query_id = sql_line[0].split("): ")[0]
            sql = sql_line[0].split("): ")[-1]

        if queue == "root.default":
            message = f"{formatted_datetime},{user},{queue},{application_id},{query_id},{sql}\n"
            fw.write(message)
    fw.close()


if __name__ == "__main__":
    main()
