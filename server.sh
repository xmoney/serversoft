#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear;
echo '================================================================';
echo ' [LNMP/Nginx] Ubuntu ';
echo ' by Aisyer! ';
echo '================================================================';

# VAR ***************************************************************************************
FileDir='/home/server_install_files/';
InstallDir='/usr/local/server';
MysqlPass='test01';

Cpunum='';
InstallModel='';

NginxVersion='nginx-1.4.1';
MysqlVersion='mysql-5.6.11';
PhpVersion='php-5.4.15';



# Function List	*****************************************************************************
function Downloadfile()
{
	randstr=$(date +%s);
	cd $FileDir/packages;

	if [ -s $1 ]; then
		echo "[OK] $1 found.";
	else
		echo "[Notice] $1 not found, download now......";
		if ! wget -c --tries=3 ${2}?${randstr} ; then
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
	for packages in build-essential gcc g++ cmake make ntp logrotate automake patch autoconf autoconf2.13 re2c wget flex cron libzip-dev libc6-dev rcconf bison cpp binutils unzip tar bzip2 libncurses5-dev libncurses5 libtool libevent-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlibc openssl libsasl2-dev libxml2 libxml2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libfreetype6 libfreetype6-dev libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev libpng12-0 libpng12-dev curl libcurl3  libpq-dev libpq5 gettext libcurl4-gnutls-dev  libcurl4-openssl-dev libcap-dev ftp openssl expect; do
		echo "[${packages} Installing] ************************************************** >>";
		apt-get install -y $packages --force-yes;apt-get -fy install;apt-get -y autoremove; 
	done;
}

function InstallReady()
{
	mkdir -p $FileDir/conf;
	mkdir -p $FileDir/packages/untar;
	chmod +Rw $FileDir/packages;
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
		make -j $Cpunum;
		make install;

		$InstallDir/nginx/sbin/nginx;

		echo "[OK] ${NginxVersion} install completed.";
	else
		echo '[NO] ${NginxVersion} is installed!';
	fi;
}

function InstallMysql()
{
	echo "[${MysqlVersion} Installing] ************************************************** >>";
	Downloadfile "${MysqlVersion}.tar.gz" "http://cdn.mysql.com/Downloads/MySQL-5.6/${MysqlVersion}.tar.gz";
	rm -rf $FileDir/packages/untar/$MysqlVersion;
	echo "tar -zxf ${MysqlVersion}.tar.gz ing...";
	tar -zxf $FileDir/packages/$MysqlVersion.tar.gz -C $FileDir/packages/untar;
	
	if [ ! -d /usr/local/mysql ]; then
		cd $FileDir/packages/untar/$MysqlVersion;
		groupadd mysql;
		useradd -s /sbin/nologin -g mysql mysql;
		
		cmake -DCMAKE_INSTALL_PREFIX=$InstallDir/mysql  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1;
		
		make -j $Cpunum;
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
$InstallDir/mysql/bin/mysql -h127.0.0.1 -uroot -p$MysqlPass <<EOF
USE mysql;
DELETE FROM user WHERE user='';
UPDATE user set password=password('$MysqlPass') WHERE user='root';
DELETE FROM user WHERE not (user='root');
FLUSH PRIVILEGES;
EOF
# **************************************
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

function InstallPhp()
{
	echo "[${PhpVersion} Installing] ************************************************** >>";
	Downloadfile "${PhpVersion}.tar.gz" "http://cn2.php.net/distributions/${PhpVersion}.tar.gz";
	rm -rf $FileDir/packages/untar/$PhpVersion;
	echo "tar -zxf ${PhpVersion}.tar.gz ing...";
	tar -zxf $FileDir/packages/$PhpVersion.tar.gz -C $FileDir/packages/untar;

	if [ ! -d /usr/local/php ]; then
		cd $FileDir/packages/untar/$PhpVersion;
		groupadd www;
		useradd -s /sbin/nologin -g www www;
		
		./configure --prefix=$InstallDir/php --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/etc --with-openssl --with-zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip --with-pcre-regex --without-pear --enable-maintainer-zts --enable-pthreads ;

		#make ZEND_EXTRA_LIBS='-liconv';
		make -j $Cpunum ZEND_EXTRA_LIBS='-liconv';
		make install;
		
		cp php.ini-* $InstallDir/php/etc;
		cp php.ini-development /etc/php.ini;
		
		cp $InstallDir/php/etc/php-fpm.conf.default $InstallDir/php/etc/php-fpm.conf
		cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm;
		chmod +x /etc/init.d/php-fpm;
		update-rc.d php-fpm defaults;
		
		$InstallDir/php/sbin/php-fpm;

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
	rm -rf $InstallDir/php /usr/lib/php /etc/php.ini;
	rm -rf /etc/logrotate.d/nginx /root/.mysqlroot;
	rm -rf $FileDir/packages/untar;
	
	update-rc.d -f php-fpm remove;
	update-rc.d -f mysql remove;
	rm -rf /etc/init.d/php-fpm;
	rm -rf /etc/init.d/mysql;

	echo '[OK] Successfully uninstall.';
	exit;
}

# Start Install	*****************************************************************************
ConfirmInstall;
CheckSystem;
DeletePackages;
InstallBasePackages;
InstallReady;
InstallNginx;
InstallMysql;
# InstallLibiconv;
InstallPhp;


