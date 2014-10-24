#!/bin/bash

#nginx日志切割脚本
# use: 0 0 * * * bash /usr/local/server/nginx/nginx_log.sh

#!/bin/bash
#设置日志文件存放目录
logs_path="/usr/local/server/nginx/logs/"
#设置pid文件
pid_path="/usr/local/server/nginx/logs/nginx.pid"

#重命名日志文件
mv ${logs_path}access.log ${logs_path}access_$(date -d "yesterday" +"%Y%m%d").log

#向nginx主进程发信号重新打开日志
kill -USR1 `cat ${pid_path}`
