#!/bin/bash


# echo "deb http://deb.goaccess.io $(lsb_release -cs) main" | tee -a /etc/apt/sources.list
# wget -O - http://deb.goaccess.io/gnugpg.key | apt-key add -
# apt-get update
# apt-get install goaccess


exit


sudo apt-get install libncursesw5-dev libglib2.0-dev libgeoip-dev libtokyocabinet-dev


wget http://tar.goaccess.io/goaccess-0.8.1.tar.gz
tar -xzvf goaccess-0.8.1.tar.gz
cd goaccess-0.8.1/
./configure --enable-geoip --enable-utf8
make
make install



名称
goaccess - 快速的web日志分析器与交互式查看器

概要
goaccess [-f 输入文件] [-c] [-e] [-a]

描述
goaccess是一个实时的web日志分析器，以及交互式查看器，在类Unix系统的终端(terminal)上运行，是一个基于GPL的自由软件。为需要可视化服务器报告的系统管理员提供快速而重要的HTTP统计信息。首先它会解析web日志文件，从被解析文件中收集数据，然后展示在控制台(console)或者X终端上。收集到的信息会在一个可视化/交互式的窗口中展示给用户，包括：

综合统计数字
有效请求的总数，无效请求的总数，数据分析的总时间，独立访客总数，被请求的独立文件总数，独立静态文件总数(css, ico, jpg, swf, gif, png)，独立HTTP引荐网站(URL)总数，独立404响应(资源未找到)总数，被解析日志文件的大小，总流量。

独立访客
相同IP，相同日期以及相同代理(agent)的HTTP请求被看作一个独立请求。(包括网络爬虫)。这部分的{详细视图}可用。

被访问文件
总数量基于独立请求文件。基于相同IP，相同日期以及相同代理的HTTP请求被看作一次独立访问这一前提。这部分的{详细视图}可用。

被请求静态文件
总数量基于独立请求文件。包括的文件类型：jpg，css，swf，js，gif，png等。这部分的{详细视图}可用。

引荐的URL
请求来自于引荐的URL。总数量并非基于上述前提，而是基于请求的总数目。这部分的{详细视图}可用。

404或者资源未找到
总数量基于请求总数。这部分的{详细视图}可用。

操作系统类型
总数量基于独立访客数。{详细视图}可用。

浏览器类型
总数量基于独立访客数。{详细视图}可用。

主机
总数量基于请求总数。{详细视图}可用。每个IP的{详细视图}会显示该主机的额外信息，包括反向域名解析，IP的定位。

HTTP状态码
基于请求总数。{详细视图}可用。

引荐的站点
这一部分仅显示主机而不是完整的URL。基于请求总数。{详细视图}可用。

关键词短语
这部分会报告Google搜索，Google缓存以及Google翻译中使用的关键词短语。总数目基于请求总数。{详细视图}可用。

命令选项
-f 输入文件

输入文件的路径

-c

提示日期和日志格式配置窗口

-e

在主机部分不统计(排除)某IP

-a

为解析到的主机开启一些用户代理

自定义日志/日期格式
GoAccess几乎可以解析任何web日志格式。

预定义选项包括：Common Log Format(CLF)，Combined Log Format(XLF/ELF)，包含虚拟主机和W3C格式(IIS)。

GoAccess也允许任意自定义格式字符串。

有两种方式来配置日志格式。最简单的方式是执行带-c选项的GoAccess以提示配置窗口。另外，也可以在~/.goaccessrc中配置。

日期格式(date_format)

空格之后的date_format变量指定了包含常规字符和特殊格式说明符的任意组合。这些字符都以百分号(%)开始。详见：http://linux.die.net/man/3/strftime

日志格式(log_format)

空格之后的date_format变量指定了日志格式字符串。

%d 匹配date_format变量的日期域

%h 主机(客户端IP地址，IPv4或IPv6)

%r 来自客户端的请求行

%s 服务器返回给客户端的状态码

%b 返回给客户端的对象大小

%R "Referer"HTTP请求头

%u 用户代理HTTP请求头

%^ 忽略该域

交互式菜单
F1 主帮助页面
F5 重绘主窗口
q 退出程序或者当前{详细视图}(窗口)
o 打开当前激活模块的详细视图
c 设置或改变配色方案
TAB 向前迭代模块。从当前激活模块开始。
SHIFT + TAB 向后迭代模块。从当前激活模块开始。
RIGHT ARROW 打开当前激活模块的详细视图
0-9 激活模块，这样用户就可以使用^o^或^RIGHT ARROW^打开{详细视图}
SHIFT + 0-9 激活超过10的模块
s 根据日期进行独立访客排序。仅在独立访客模块(1)有效。
S 根据点击数进行独立访客排序。仅在独立访客模块(1)有效。
/ 向前在任意{详细视图}窗口搜索输入模式(pattern)。
n 在任意{详细视图}窗口中找到下一次出现的位置。
t 跳到第一个条目或屏幕顶端
b 跳到最后一个条目或者屏幕底部
示例
最简单且最快速的用法：

# goaccess -f access.log
将产生一个交互式的文本输出。

生成一个HTML报告：

# goaccess -f access.log -a > report.html
要想产生全面的统计信息，我们可以这样执行GoAccess：

# goaccess -f access.log -a
-a标志表明我们想为每个解析到的主机处理一个代理列表。-c标志将提示日期/日志格式配置窗口。仅当curses初始时。

如果我们想为GoAccess增加更多的灵活性，可以使用一系列的管道。例如：

# zcat access.log.*gz | goaccess
或者

# zcat access.log.* | goaccess
另一个有用的管道是根据日期过滤web日志。

如下命令将得到日志文件中2010年12月5日的所有HTTP请求：

# sed -n '/05\/Dec\/2010/,$ p' access.log | goaccess -a
如果想仅解析从日期a到日期b的一个特定时限的日志，则可以：

# sed -n '/5\/Nov\/2010/,/5\/Dec\/2010/ p' access.log | goaccess -a
注意这一命令依赖于sed的速度，可能需要更长的解析时间。

另外，值得指出，如果想以更低的进程调度优先级运行GoAccess，可以这样执行：

# nice -n 19 goaccess -f access.log -a
注释
每个{详细视图}窗口中，条目总数目为300。

以管道的方式将日志传给GoAccess会使得实时功能失效。这归因于确定标准输入的实际大小的可移植性问题。然而，未来的某个版本可能会包含这一特性。

