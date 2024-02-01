import sys
from datetime import datetime


def calculate_date_difference(data1_str, data2_str):
    # 将字符串转换为日期对象
    format_string = "%Y-%m-%d"
    data1 = datetime.strptime(data1_str, format_string)
    data2 = datetime.strptime(data2_str, format_string)

    # 计算两个日期之间的差值
    delta = abs(data1 - data2)

    # 返回计算结果天数
    return delta.days


if __name__ == "__main__":
    # 获取命令行参数
    if len(sys.argv) != 3:
        print("Usage: python time_calculation.py YYYY-MM-DD YYYY-MM-DD")
        sys.exit()

    today_data = sys.argv[1]
    past_data = sys.argv[2]

    # 计算并输出天数差
    diff_days = calculate_date_difference(today_data, past_data)
    print("两个日期相差: %d" % diff_days)
