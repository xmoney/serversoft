#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear;
echo '================================================================';
echo ' [Devlopment Environment] Ubuntu ';
echo ' by Aisyer! ';
echo '================================================================';

# VAR ***************************************************************************************
FileDir='/home/server_install_files/';
InstallDir='/usr/local/server';
MysqlPass='test01';

InstallModel='';

NginxVersion='nginx-1.7.2';
MysqlVersion='mysql-5.6.16';
PhpVersion='php-5.5.13';
RedisVersion='redis-2.8.12';

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
	apt-get remove -y apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker mysql-client mysql-server mysql-common php;
	killall apache2;
	apt-get update;
	for packages in build-essential gcc g++ cmake make ntp logrotate automake patch autoconf autoconf2.13 re2c wget flex cron libzip-dev libreadline-dev libc6-dev rcconf bison cpp binutils unzip tar bzip2 libncurses5-dev libncurses5 libtool libevent-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlibc openssl libsasl2-dev libxml2 libxml2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libfreetype6 libfreetype6-dev libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev libpng12-0 libpng12-dev curl libcurl3  libpq-dev libpq5 gettext libcurl4-gnutls-dev  libmcrypt-dev libcurl4-openssl-dev libcap-dev ftp openssl expect; do
		echo "[${packages} Installing] ************************************************** >>";
		apt-get install -y $packages --force-yes;apt-get -fy install;apt-get -y autoremove; 
	done;
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
	
	groupadd www;
	useradd -s /sbin/nologin -g www www;

	if [ ! -d /usr/local/nginx ]; then
		cd $FileDir/packages/untar/$NginxVersion;
		./configure --prefix=$InstallDir/nginx --user=www --group=www --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_gzip_static_module ;
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
	echo "[${MysqlVersion} Installing] ************************************************** >>";
	Downloadfile "${MysqlVersion}.tar.gz" "http://cdn.mysql.com/Downloads/MySQL-5.6//${MysqlVersion}.tar.gz";
	rm -rf $FileDir/packages/untar/$MysqlVersion;
	echo "tar -zxf ${MysqlVersion}.tar.gz ing...";
	tar -zxf $FileDir/packages/$MysqlVersion.tar.gz -C $FileDir/packages/untar;
	
	if [ ! -d $InstallDir/mysql ]; then
		cd $FileDir/packages/untar/$MysqlVersion;
		groupadd mysql;
		useradd -s /sbin/nologin -g mysql mysql;
		
		cmake -DCMAKE_INSTALL_PREFIX=$InstallDir/mysql  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1;
		
		make;
		make install;
		
		chmod +w $InstallDir/mysql;
		mkdir -p $InstallDir/mysql/data;
		chown -R mysql:mysql $InstallDir/mysql;
		
		cp $InstallDir/mysql/support-files/my-default.cnf /etc/my.cnf;
		
		$InstallDir/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/my.cnf --basedir=$InstallDir/mysql --datadir=$InstallDir/mysql/data;

		cp $InstallDir/mysql/support-files/mysql.server /etc/init.d/mysql;
		chmod +x /etc/init.d/mysql;
		update-rc.d mysql defaults;
		
		$InstallDir/mysql/support-files/mysql.server start;

		rm -rf $InstallDir/mysql/data/test;
		
# EOF **********************************
$InstallDir/mysql/bin/mysql  <<EOF
USE mysql;
DELETE FROM user WHERE user='';
UPDATE user set password=password('${MysqlPass}') WHERE user='root';
DELETE FROM user WHERE not (user='root');
FLUSH PRIVILEGES;
EOF
# **************************************

		$InstallDir/mysql/support-files/mysql.server stop;

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
		./configure --prefix=$InstallDir/php --enable-mysqlnd --with-mysql=mysqlnd --with-mysqli=mysqlnd --enable-pdo --with-pdo-mysql=mysqlnd --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/etc --with-openssl --with-zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --with-mcrypt --with-mhash --enable-zip --with-pcre-regex --without-pear --enable-maintainer-zts --enable-cli --enable-opcache --with-readline --with-bz2 --enable-zip --enable-sockets --enable-sysvsem --enable-sysvshm --with-gettext --enable-bcmath;

		#make ZEND_EXTRA_LIBS='-liconv';
		make ZEND_EXTRA_LIBS='-liconv';
		make install;
		
		mkdir -p $InstallDir/php/etc;
		cp php.ini-* $InstallDir/php/etc;
		cp php.ini-development /etc/php.ini;
		
		cp $InstallDir/php/etc/php-fpm.conf.default $InstallDir/php/etc/php-fpm.conf
		cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm;
		chmod +x /etc/init.d/php-fpm;
		update-rc.d php-fpm defaults;
		
		#$InstallDir/php/sbin/php-fpm;

		wget http://pear.php.net/go-pear.phar
     	$InstallDir/php/bin/php go-pear.phar

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
	apt-get --purge remove nginx
	apt-get --purge remove mysql-server;
	apt-get --purge remove mysql-common;
	apt-get --purge remove php;
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
	Downloadfile "phpredis.tar.gz" "https://raw.github.com/xmoney/serversoft/master/phpredis.tar.gz";
	echo "tar -xf phpredis.tar.gz ing...";
	rm -rf $FileDir/packages/untar/phpredis;
	tar -zxf $FileDir/packages/phpredis.tar.gz -C $FileDir/packages/untar;

	cd $FileDir/packages/untar/phpredis;

	$InstallDir/php/bin/phpize;
	./configure	--with-php-config=$InstallDir/php/bin/php-config #--enable-redis-igbinary
	make && make install

	echo "[OK] phpredis install completed.";
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
 InstallOtherPackages;
 InstallNginx;
 InstallMysql;
# # 
# # InstallLibiconv;
# # 
 InstallPhp;
 InstallRedis;
 InstallPhpRedis;
 Run;




