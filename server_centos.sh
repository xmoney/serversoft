#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo -ne "
* soft nofile 65535
* hard nofile 65535
" >> /etc/security/limits.conf

clear;
echo '================================================================';
echo ' [Devlopment Environment] Centos 7 ';
echo ' by Aisyer! ';
echo '================================================================';

# VAR ***************************************************************************************
FileDir='/home/server_install_files/';
InstallDir='/usr/local/server';
MysqlPass='test01';

InstallModel='';

NginxVersion='nginx-1.9.7';
MysqlVersion='mysql-5.6.24';
PhpVersion='php-7.0.0';
RedisVersion='redis-3.0.3';

# SVN
SvnData='/home/svn';



# Function List	*****************************************************************************
function Downloadfile()
{
	randstr=$(date +%s);
	cd $FileDir/packages;

	if [ -s $1 ]; then
		echo "[OK] $1 found.";
	else
		echo "[Notice] $1 not found, download now......";
		if ! wget -c --tries=10 --wait=3 --waitretry=3 ${2}?${randstr} ; then
			echo "[Error] Download Failed : $1, please check $2 ";
			exit;
		else
			mv ${1}?${randstr} $1;
		fi;
	fi;
}

function InstallBasePackages()
{
	/usr/bin/yum install epel-release;
	/usr/bin/yum update;

	/usr/bin/yum -y install git;

	/usr/bin/yum -y install gcc gcc-c++ ncurses ncurses-devel cmake autoconf psmisc zlib zlib-devel openssl openssl-devel pcre pcre-devel libxml2 libxml2-devel curl-devel libjpeg-devel libpng-devel freetype-devel libmcrypt libmcrypt-devel mcrypt mhash
}

function InstallReady()
{
	mkdir -p $FileDir/conf;
	mkdir -p $FileDir/packages/untar;
	chmod +w -R $FileDir/packages;

	groupadd www;
	useradd -s /sbin/nologin -g www www;

	mkdir -p /data/wwwroot;
	mkdir -p /data/logs;
	mkdir -p /data/mysql;
	mkdir -p /data/leveldb;

	chmod -R 775 /data/leveldb;

	killall nginx;
	killall mysqld;
	killall php-cgi;
	killall php-fpm;
	killall php5-fpm;
}

function InstallNginx()
{
	echo "[${NginxVersion} Installing] ************************************************** >>";
	Downloadfile "${NginxVersion}.tar.gz" "http://nginx.org/download/${NginxVersion}.tar.gz";
	rm -rf $FileDir/packages/untar/$NginxVersion;
	echo "tar -zxf ${NginxVersion}.tar.gz ing...";
	tar -zxf $FileDir/packages/$NginxVersion.tar.gz -C $FileDir/packages/untar;
	
	mkdir -p /var/cache/nginx/client_temp;
	mkdir -p /var/cache/nginx/proxy_temp;
	mkdir -p /var/cache/nginx/fastcgi_temp;
	mkdir -p /var/cache/nginx/uwsgi_temp;
	mkdir -p /var/cache/nginx/scgi_temp;

	groupadd www;
	useradd -s /sbin/nologin -g www www;

	if [ ! -d /usr/local/nginx ]; then
		cd $FileDir/packages/untar/$NginxVersion;
		./configure --prefix=$InstallDir/nginx \
			--error-log-path=/var/log/nginx/error.log \
			--http-log-path=/var/log/nginx/access.log \
			--pid-path=/var/run/nginx.pid \
			--lock-path=/var/run/nginx.lock \
			--http-client-body-temp-path=/var/cache/nginx/client_temp \
			--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
			--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
			--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
			--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
			--user=www \
			--group=www \
			--with-http_ssl_module \
			--with-http_realip_module \
			--with-http_addition_module \
			--with-http_sub_module \
			--with-http_dav_module \
			--with-http_flv_module \
			--with-http_mp4_module \
			--with-http_gunzip_module \
			--with-http_gzip_static_module \
			--with-http_random_index_module \
			--with-http_secure_link_module \
			--with-http_stub_status_module \
			--with-http_auth_request_module \
			--with-mail \
			--with-mail_ssl_module \
			--with-file-aio \
			--with-ipv6 \
			--with-stream \
			--with-stream_ssl_module;

		make;
		make install;

		#$InstallDir/nginx/sbin/nginx;

		echo "[OK] ${NginxVersion} install completed.";
	else
		echo '[NO] ${NginxVersion} is installed!';
	fi;
}

function InstallMysql()
{
	Downloadfile "boost.tar.gz" "wget http://downloads.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz";
	tar -zxf $FileDir/packages/boost.tar.gz -C $FileDir/packages/untar;


	echo "[${MysqlVersion} Installing] ************************************************** >>";
	Downloadfile "${MysqlVersion}.tar.gz" "http://cdn.mysql.com/Downloads/MySQL-5.7/${MysqlVersion}.tar.gz";
	rm -rf $FileDir/packages/untar/$MysqlVersion;
	echo "tar -zxf ${MysqlVersion}.tar.gz ing...";
	tar -zxf $FileDir/packages/$MysqlVersion.tar.gz -C $FileDir/packages/untar;
	
	if [ ! -d $InstallDir/mysql ]; then
		cd $FileDir/packages/untar/$MysqlVersion;
		groupadd mysql;
		useradd -s /sbin/nologin -g mysql mysql;

		cmake . -DCMAKE_INSTALL_PREFIX=$InstallDir/mysql \
			-DMYSQL_DATADIR=/data/mysql \
			-DDOWNLOAD_BOOST=1 \
			-DWITH_BOOST=$FileDir/packages/untar/boost_1_59_0 \
			-DSYSCONFDIR=/etc \
			-DWITH_INNOBASE_STORAGE_ENGINE=1 \
			-DWITH_PARTITION_STORAGE_ENGINE=1 \
			-DWITH_FEDERATED_STORAGE_ENGINE=1 \
			-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
			-DWITH_MYISAM_STORAGE_ENGINE=1 \
			-DENABLED_LOCAL_INFILE=1 \
			-DENABLE_DTRACE=0 \
			-DWITH_EXTRA_CHARSETS=complex \
			-DWITH_READLINE=1 \
			-DDEFAULT_CHARSET=utf8 \
			-DDEFAULT_COLLATION=utf8_general_ci \
			-DWITH_EMBEDDED_SERVER=1

		make;
		make install;
		
		chmod +w $InstallDir/mysql;
		mkdir -p $InstallDir/mysql/data;
		chown -R mysql:mysql $InstallDir/mysql;
		
		cp $InstallDir/mysql/support-files/my-default.cnf /etc/my.cnf;
		cp $InstallDir/mysql/support-files/mysql.server /etc/init.d/mysqld;
		chmod +x /etc/init.d/mysqld
		chkconfig --add mysqld
		chkconfig mysqld on

		$InstallDir/mysql/bin/mysqld --initialize-insecure --user=mysql --basedir=$InstallDir/mysql --datadir=/data/mysql

		rm -rf $InstallDir/mysql/data/test;

		service mysqld start;

		# $InstallDir/mysql/bin/mysql -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"$MysqlPass\" with grant option;"
		# $InstallDir/mysql/bin/mysql -e "grant all privileges on *.* to root@'localhost' identified by \"$MysqlPass\" with grant option;"

# EOF **********************************
$InstallDir/mysql/bin/mysql  <<EOF
USE mysql;
DELETE FROM user WHERE user='';
UPDATE user set password=password('${MysqlPass}') WHERE user='root';
DELETE FROM user WHERE not (user='root');
FLUSH PRIVILEGES;
EOF
# **************************************

		service mysqld stop;

		echo "[OK] ${MysqlVersion} install completed.";
	else
		echo '[NO] MySQL is installed.';
	fi;
}

function InstallLibiconv()
{
	echo "[libiconv-1.14 Installing] ************************************************** >>";
	rm -f libiconv-1.14.tar.gz*;
	Downloadfile "libiconv-1.14.tar.gz" "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz";
	rm -rf $FileDir/packages/untar/libiconv-1.14;
	echo "tar -zxf libiconv.tar.gz ing...";
	mv libiconv-1.14.tar.gz* libiconv-1.14.tar.gz;
	tar -zxf $FileDir/packages/libiconv-1.14.tar.gz -C $FileDir/packages/untar;

	cd $FileDir/packages/untar/libiconv-1.14;

	./configure --prefix=/usr/local/libiconv;
	make;
	make install;

	echo "[OK] libiconv-1.14 install completed.";
}

function InstallOtherPackages()
{
	## libmcrypt-2.5.8
	packageName='libmcrypt-2.5.8';
	echo "[${packageName} Installing] ************************************************** >>";
	Downloadfile "${packageName}.tar.gz" "http://downloads.sourceforge.net/mcrypt/${packageName}.tar.gz";
	rm -rf $FileDir/packages/untar/$packageName;
	echo "tar -zxf ${packageName}.tar.gz ing...";
	tar -zxf $FileDir/packages/$packageName.tar.gz -C $FileDir/packages/untar;

	cd $FileDir/packages/untar/$packageName;

	./configure;
	make;
	make install;

	echo "[OK] ${packageName} install completed.";

	## mhash-0.9.9.9
	packageName='mhash-0.9.9.9';
	echo "[${packageName} Installing] ************************************************** >>";
	Downloadfile "${packageName}.tar.gz" "http://downloads.sourceforge.net/mhash/${packageName}.tar.gz";
	rm -rf $FileDir/packages/untar/$packageName;
	echo "tar -zxf ${packageName}.tar.gz ing...";
	tar -zxf $FileDir/packages/$packageName.tar.gz -C $FileDir/packages/untar;

	cd $FileDir/packages/untar/$packageName;

	./configure;
	make;
	make install;

	echo "[OK] ${packageName} install completed.";

	## mcrypt-2.6.8
	packageName='mcrypt-2.6.8';
	echo "[${packageName} Installing] ************************************************** >>";
	Downloadfile "${packageName}.tar.gz" "http://downloads.sourceforge.net/mcrypt/${packageName}.tar.gz";
	rm -rf $FileDir/packages/untar/$packageName;
	echo "tar -zxf ${packageName}.tar.gz ing...";
	tar -zxf $FileDir/packages/$packageName.tar.gz -C $FileDir/packages/untar;

	cd $FileDir/packages/untar/$packageName;

	LD_LIBRARY_PATH=/usr/local/lib ./configure;
	make;
	make install;

	echo "[OK] ${packageName} install completed.";
}

function InstallPhp()
{
	echo "[${PhpVersion} Installing] ************************************************** >>";
	Downloadfile "${PhpVersion}.tar.gz" "http://cn2.php.net/distributions/${PhpVersion}.tar.gz";
	rm -rf $FileDir/packages/untar/$PhpVersion;
	echo "tar -zxf ${PhpVersion}.tar.gz ing...";
	tar -zxf $FileDir/packages/$PhpVersion.tar.gz -C $FileDir/packages/untar;

	if [ ! -d $InstallDir/php ]; then
		cd $FileDir/packages/untar/$PhpVersion;
		groupadd www;
		useradd -s /sbin/nologin -g www www;
		
		#./configure --prefix=$InstallDir/php --with-mysql=$InstallDir/mysql --with-mysqli=$InstallDir/mysql/bin/mysql_config --enable-pdo --with-pdo-mysql=$InstallDir/mysql --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/etc --with-openssl --with-zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --with-mcrypt --with-mhash --enable-zip --with-pcre-regex --without-pear --enable-maintainer-zts --enable-pthreads --enable-cli;
		./configure --prefix=$InstallDir/php \
		--exec-prefix=$InstallDir/php \
		--bindir=$InstallDir/php/bin \
		--sbindir=$InstallDir/php/sbin \
		--includedir=$InstallDir/php/include \
		--libdir=$InstallDir/php/lib/php \
		--mandir=$InstallDir/php/man \
		--with-config-file-path=/etc \
		--with-mcrypt \
		--with-mhash \
		--with-openssl \
		--with-mysql=mysqlnd \
		--with-mysqli=mysqlnd \
		--with-pdo-mysql=mysqlnd \
		--with-gd \
		--with-iconv \
		--with-zlib \
		--enable-zip \
		--enable-inline-optimization \
		--disable-debug \
		--disable-rpath \
		--enable-shared \
		--enable-xml \
		--enable-bcmath \
		--enable-shmop \
		--enable-sysvsem \
		--enable-mbregex \
		--enable-mbstring \
		--enable-ftp \
		--enable-pdo \
		--enable-gd-native-ttf \
		--enable-pcntl \
		--enable-sockets \
		--enable-cli \
		--with-xmlrpc \
		--enable-soap \
		--without-pear \
		--with-gettext \
		--enable-session \
		--with-curl \
		--with-jpeg-dir \
		--with-freetype-dir \
		--enable-opcache \
		--enable-fpm \
		--enable-fastcgi \
		--with-fpm-user=www \
		--with-fpm-group=www \
		--without-gdbm \
		--disable-fileinfo;

		#make ZEND_EXTRA_LIBS='-liconv';
		make;
		make install;
		
		mkdir -p $InstallDir/php/etc;
		cp php.ini-* $InstallDir/php/etc;
		cp php.ini-development /etc/php.ini;
		
		cp $InstallDir/php/etc/php-fpm.conf.default $InstallDir/php/etc/php-fpm.conf
		cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm;
		chmod +x /etc/init.d/php-fpm;
		chkconfig --add php-fpm;
		chkconfig php-fpm on;
		
		#$InstallDir/php/sbin/php-fpm;

		echo "[OK] ${PhpVersion} install completed.";
	else
		echo '[NO] PHP is installed.';
	fi;
}

function ConfirmInstall()
{
	echo "[Notice] Confirm Install/Uninstall ? please select: (1~3)"
	select selected in 'Install' 'Uninstall' 'Exit'; do
		break;
	done;
	if [ "$selected" == 'Exit' ]; then
		echo 'Exit Install.';
		exit;
	elif [ "$selected" == 'Install' ]; then
		InstallModel='1';
	elif [ "$selected" == 'Uninstall' ]; then
		Uninstall;
	else
		ConfirmInstall;
		return;
	fi;

	echo "[OK] You Selected: ${selected}";
}

function CheckSystem()
{
	if [ $(id -u) != '0' ]; then
		echo '[Error] Please use root to install.';
		exit;
	fi;
	
	Cpunum=`cat /proc/cpuinfo |grep 'processor'|wc -l`;
}

function DeletePackages()
{
	/bin/yum uninstall nginx
	/bin/yum uninstall mysql-server;
	/bin/yum uninstall mysql-common;
	/bin/yum uninstall php;
}

function Run()
{
	$InstallDir/nginx/sbin/nginx;
	$InstallDir/mysql/support-files/mysql.server start;
	$InstallDir/php/sbin/php-fpm;
}

function Uninstall()
{
	echo -e "\033[41m\033[37m[Warning] Please backup your data first. Uninstall will delete all the data!!! \033[0m ";
	read -p '[Notice] Confirm Uninstall(Delete All Data)? : (y/n)' confirmUN;
	if [ "$confirmUN" != 'y' ]; then
		exit;
	fi;

	killall nginx;
	killall mysqld;
	killall php-cgi;
	killall php-fpm;

	rm -rf $InstallDir/nginx;
	rm -rf $InstallDir/mysql /etc/my.cnf;
	rm -rf $InstallDir/redis /etc/redis;
	rm -rf $InstallDir/php /usr/lib/php /etc/php.ini;
	rm -rf /etc/logrotate.d/nginx /root/.mysqlroot;
	rm -rf $FileDir/packages/untar;
	
	update-rc.d -f php-fpm remove;
	update-rc.d -f mysql remove;
	update-rc.d -f redis remove;
	rm -rf /etc/init.d/php-fpm;
	rm -rf /etc/init.d/mysql;
	rm -rf /etc/init.d/redis;

	rm -rf /etc/php*;
	rm /usr/bin/php*;
	rm /usr/sbin/php*;
	rm /usr/bin/mysql*;

	echo '[OK] Successfully uninstall.';
	exit;
}

function InstallRedis()
{
	echo "[${RedisVersion} Installing] ************************************************** >>";
	Downloadfile "${RedisVersion}.tar.gz" "http://download.redis.io/releases/${RedisVersion}.tar.gz";
	rm -rf $FileDir/packages/untar/$RedisVersion;
	echo "tar -zxf ${RedisVersion}.tar.gz ing...";
	tar -zxf $FileDir/packages/$RedisVersion.tar.gz -C $FileDir/packages/untar;

	if [ ! -d $InstallDir/redis ]; then
		cd $FileDir/packages/untar/$RedisVersion;
		make

		mkdir /etc/redis;
		mkdir /data/redis;

		cp -rf $FileDir/packages/untar/$RedisVersion/src $InstallDir/redis
		cp $FileDir/packages/untar/$RedisVersion/redis.conf /etc/redis/redis.conf
		cp $FileDir/packages/untar/$RedisVersion/sentinel.conf /etc/redis/sentinel.conf

		cp $FileDir/packages/untar/$RedisVersion/utils/redis_init_script /etc/init.d/redis

		chmod +x /etc/init.d/redis;
		update-rc.d redis defaults;

		echo "[OK] ${RedisVersion} install completed.";
	else
		echo '[NO] Redis is installed.';
	fi;
}

function InstallPhpRedis()
{
    echo "[phpredis Installing] ************************************************** >>";
    cd $FileDir/packages/untar;

    git clone https://github.com/phpredis/phpredis.git;
    cd phpredis;

    $InstallDir/php/bin/phpize;
    ./configure     --with-php-config=$InstallDir/php/bin/php-config #--enable-redis-igbinary
    make && make install

    echo "[OK] phpredis install completed.";
}

function InstallLevelDB()
{
	cd $InstallDir;

	git clone https://github.com/google/leveldb.git;
	cd leveldb;
	make;

	git clone https://github.com/reeze/php-leveldb.git;
	cd php-leveldb;
	$InstallDir/php/bin/phpize;
	./configure --with-leveldb=$InstallDir/leveldb --with-php-config=$InstallDir/php/bin/php-config;
	make;
	make install;
}

function InstallSVN()
{
	apt-get install subversion;
	adduser svnuser;
	addgroup subversion;
	addgroup svnuser subversion;

	mkdir $SvnData;
	cd $SvnData;
	mkdir svn_data;
	chown -R root:subversion svn_data;
	chmod -R g+rws svn_data;
	svnadmin create $SvnData/svn_data;

	# run
	#svnserve -d -r /home/$SvnData;
}

# Start Install	*****************************************************************************
 ConfirmInstall;
 CheckSystem;
 DeletePackages;
 InstallBasePackages;
 InstallReady;
 # InstallOtherPackages;
 # InstallNginx;
 InstallMysql;
# # 
# # InstallLibiconv;
# # 
 # InstallPhp;
 # InstallRedis;
 # InstallPhpRedis;
 # InstallLevelDB;
 # Run;




