#!/bin/sh
# service mysqld stop; rm -rf /var/lib/mysql; rm -rf /etc/my.cnf; yum remove mysql-community-server mysql mysql-community-client mysql
# sed -i 's/^skip-grant-tables/#skip-grant-tables/' /etc/my.cnf

. "/root/centos/fun.sh"

rpm -q mysql-community-server > /dev/null

if [ $? != 0 ]; then
	yum install mysql-community-server
	if [ $? = 0 ]; then
		root_password=$(</dev/urandom tr -dc A-Za-z0-9 | head -c32)
		echo $root_password >> /root/centos/site.txt
		echo >> /root/centos/site.txt
		/root/centos/mysql.sh
		service mysqld start;
		\cp /etc/my.cnf /root
		mysql -e "drop user 'root'@'::1'; drop user 'root'@'127.0.0.1'; drop user ''@'localhost';drop user ''@'%';";
		mysql -e "delete from mysql.user where user!='root' or host!='localhost';";
		mysql -e "show databases;drop database if exists test;flush privileges;"
		mysql -e "select user,host,password from mysql.user;";
		mysql -e "update mysql.user set password=password('$root_password') where user='root';";
		red "mysql root密码 $root_password"
		sed -i "s/^pwd=.*/pwd=${root_password}/" "/root/centos/dber.sh"
		sed -i "s/^pwd=.*/pwd=${root_password}/" "/root/centos/addsite.sh"
		sed -i "s/-p123456/-p${root_password}/" "/root/centos/qps.sh"
		sed -i "s/^define('DBPW'.*/define('DBPW', '${root_password}');/" "/root/centos/expuser.php"
		[ -f '/root/centos/mysql.sh' ] && /root/centos/mysql.sh
		ln -vsf /root/centos/dber.sh /sbin
		rm -f /var/lock/subsys/mysqld

		sed -i 's/^skip-grant-tables/#skip-grant-tables/' /etc/my.cnf

		touch /var/log/mysqlslow.log
		chown mysql.mysql /var/log/mysqlslow.log

		service mysqld restart
		chkconfig mysqld on;
	fi
else
	green "mysql已安装"
fi

