@[toc]

# 前言
* 最近在搞发展对象培训，17号就要结业考试了。虽说有题库，但是是做对一道显示一道的，有的不会的还得找半天，咱计算机的不能干这些没有技术含量的，因此写了个爬虫自动刷题，套出答案并记录在数据库中。如果要爬其它的应该可以稍微修改一下，我比较懒，就没试了
* 估计是把
* https://dangxiao.hnust.edu.cn/index.php?s=/Exam/practice/lib/2
* 改成
* 入党积极分子：https://dangxiao.hnust.edu.cn/index.php?s=/Exam/practice/lib/1
* 预备党员：https://dangxiao.hnust.edu.cn/index.php?s=/Exam/practice/lib/3

# 主要功能
* 爬取题库，将题目和选项以及正确答案记录在mysql中
* 去除重复的题目
* 记录题目被爬到的次数，统计频率，找出出得多的高频题目

# 注意事项
* 要更改的内容用‘##’注释标出了
* 数据库结构为（DDL）

```sql
-- auto-generated definition
create table dangxiaotiku_fzdx
(
    problem_id int           not null
        primary key,
    title      varchar(500)  not null,
    A          varchar(100)  null,
    B          varchar(100)  null,
    C          varchar(100)  null,
    D          varchar(100)  null,
    E          varchar(100)  null,
    answer     varchar(20)   null,
    count      int default 1 not null,
    constraint dangxiaotiku_fzdx_problem_id_uindex
        unique (problem_id)
);
```
* 示例
![部分数据库数据](https://img-blog.csdnimg.cn/9d9b4425c0cb432489173ac882797499.png)

# 代码

```python
from time import sleep
import pymysql
import requests
from lxml import html

requests.packages.urllib3.disable_warnings()


def connect_database():
	# 打开数据库连接
	db = pymysql.connect("localhost", "root", "root", "mydb")
	# 使用cursor()方法获取操作游标
	cursor = db.cursor()
	return db, cursor


# 在数据库中查询，看看题目是否已经有了
# 如果在数据库中存在，给该题目出现的次数加一
def has_exists(problem_id):
	db = ''
	cursor = ''
	try:
		db, cursor = connect_database()
		# 执行sql语句，返回在数据库中的记录数
		count = cursor.execute('select count from mydb.dangxiaotiku_fzdx where problem_id=' + str(problem_id))
		if count == 0:
			return False
		else:
			t = cursor.fetchall()
			print(t)
			data = int(t[0][0]) + 1
			cursor.execute(
				'update mydb.dangxiaotiku_fzdx set count=' + str(data) + ' where problem_id=' + str(problem_id))
			db.commit()
			return True
	except Exception as e:
		print(e)
		db.close()
	finally:
		# 关闭数据库连接
		cursor.close()
		db.close()


# 写入发展对象题库数据库
def write_fzdx(problem_id, title, answer_content_list, right_answer):
	problem_id = problem_id.split('_')[1].replace('[]', '')
	print('开始保存题目：', problem_id)
	a = ['', '', '', '', '']
	i = 0
	# print(answer_content_list.__len__())
	while i < answer_content_list.__len__():
		a[i] = answer_content_list[i]
		i = i + 1

	if type(right_answer) is list:
		print('list数组')
		right_answer = ','.join(right_answer)

	print(right_answer)
	# SQL 修改数据
	insert_sql = "insert into mydb.dangxiaotiku_fzdx(problem_id, title, A, B, C, D, E, answer) values(" \
	             + problem_id + \
	             ",'" + title + \
	             "','" + a[0] + \
	             "','" + a[1] + \
	             "','" + a[2] + \
	             "','" + a[3] + \
	             "','" + a[4] + \
	             "','" + right_answer + "')"

	db = ''
	cursor = ''
	try:
		db, cursor = connect_database()
		# 执行sql语句
		cursor.execute(insert_sql)
		# 提交到数据库执行
		db.commit()
		print(problem_id, '保存完毕')
	except Exception as e:
		print(e)
		# 如果发生错误则回滚
		db.rollback()
		print(problem_id, '保存失败')
	finally:
		# 关闭数据库连接
		cursor.close()
		db.close()


# 发送请求，返回正确答案
def judge(number, c):
	# 提交答案（post）
	submit_url = 'https://dangxiao.hnust.edu.cn/index.php?s=/exam/practice'
	data = {
		# 题目编号，如problem_914[]或problem_914
		number: c,
		'method': 'submit'
	}
	headers = {
		'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36',
		'Host': 'dangxiao.hnust.edu.cn',
		'Origin': 'https://dangxiao.hnust.edu.cn',
		'Referer': 'https://dangxiao.hnust.edu.cn/index.php?s=/Exam/practice/lib/2'
	}
	print(data)
	response = requests.post(url=submit_url, headers=headers, data=data, verify=False)
	json = response.json()
	# 状态码 响应为200，正确，有响应，status=100 \u7b54\u6848\u4e0d\u6b63\u786e 为错误
	print(json)
	if json.__len__() > 0:
		status = json.get('status')
		print(status)
		if status == 100:
			print('答案错误')
			return 'error'
		elif status == 200:
			print('答案正确，为：', c)
			return c
	else:
		print('答案正确，为：', c)
		return c


def get_one():
	# 获取题目（get）
	# 入党积极分子1 发展对象2 预备党员3（包括了全部的）
	target_url = 'https://dangxiao.hnust.edu.cn/index.php?s=/Exam/practice/lib/3'
	# 请求方法: POST
	headers = {
		'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36',
		'Referer': 'https://dangxiao.hnust.edu.cn/index.php?s=/exam/index'
	}

	# 因为https是第三方CA证书认证的
	# 解决办法 是：告诉web 忽略证书访问 verify = False
	response = requests.get(url=target_url, headers=headers, verify=False)

	resp = response.text
	# print(resp)
	tree = html.etree.HTML(resp)
	# 题目编号
	number = tree.xpath('//*[@id="form1"]/table/tbody/tr[1]/td[1]/input/@name')[0]
	print(number)

	# 获取纯id
	# 在数据库中不存在才寻找答案并插入
	if not has_exists(number.split('_')[1].replace('[]', '')):
		# 题目标题
		title = tree.xpath('//*[@id="form1"]/table/thead/tr/th/text()')[0].replace(' ', '')
		print(title)

		# 判断有几个选项
		trs = tree.xpath('//*[@id="form1"]/table/tbody/tr')
		answer_count = trs.__len__()
		print(answer_count)

		answer_content_list = []
		# 获取选项内容
		for tr in trs:
			answer_content = tr.xpath('./td[2]/text()')[0]
			answer_content_list.append(answer_content)
		print(answer_content_list)

		is_multiple = ''

		# 多选题
		if number.find('[]') != -1:
			print('多选题')
			c_list = [['A', 'B'], ['A', 'C'], ['A', 'D'], ['A', 'E'], ['B', 'C'], ['B', 'D'], ['B', 'E'], ['C', 'D'],
			          ['C', 'E'],
			          ['D', 'E'],
			          ['A', 'B', 'C'], ['A', 'B', 'D'], ['A', 'B', 'E'], ['B', 'C', 'D'], ['B', 'C', 'E'],
			          ['B', 'D', 'E'], ['A', 'C', 'D'], ['A', 'C', 'E'], ['A', 'D', 'E'], ['C', 'D', 'E'],
			          ['A', 'B', 'C', 'D'], ['A', 'B', 'C', 'E'], ['A', 'B', 'D', 'E'], ['B', 'C', 'D', 'E'],
			          ['A', 'C', 'D', 'E'],
			          ['A', 'B', 'C', 'D', 'E']]
			i = 0
			while i < c_list.__len__():
				# 抽取一种可能的答案
				c = c_list[i]
				# 判断返回值
				t = judge(number, c)
				if 'error' == t:
					i = i + 1
				else:
					write_fzdx(number, title, answer_content_list, t)
					break
		else:
			print('单选题')
			# 单选题
			i = 1
			# 设置需要提交的选项
			while i <= answer_count:
				c = ''
				if i == 1:
					c = 'A'
				elif i == 2:
					c = 'B'
				elif i == 3:
					c = 'C'
				elif i == 4:
					c = 'D'
				elif i == 5:
					c = 'E'
				else:
					print('ERROR')
					exit(1)

				# 判断返回值
				t = judge(number, c)
				if 'error' == t:
					i = i + 1
				else:
					write_fzdx(number, title, answer_content_list, t)
					break
				sleep(0.5)


if __name__ == '__main__':
	i = 0
	# 爬2000次
	while i < 2000:
		get_one()
		i = i + 1
		sleep(1)
```
