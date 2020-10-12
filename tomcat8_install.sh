#!/bin/sh 

# color
Red="\033[3;31m"
Red_White="\033[1;41m"
Reset="\033[1;0m"
Cyan="\033[2;36m"
Blink="\e[5m"
Blod="\e[1m"
Green="\033[2;32m"
White="\033[2;37m"
Yellow="\033[1;33m"
Success="\t\t${White}[   ${Green}${Blink}OK${Reset}   ${White}]${Reset}"
Failed="\t\t${White}[ ${Reset}${Red}${Blink}Failed${Reset}${White} ]${Reset}"

check_yum=`yum list | grep "java-1.7.0" | wc -l`

if [ ${check_yum} -ne 0 ]
then
	# install openjdk 1.7.0
	yum -y install java-1.7.0-openjdk-devel
	
	# install wget
	yum -y install wget
	
	# groupadd tomcat
	groupadd tomcat

	# create user tomcat
	useradd -M -s /bin/nologin -g tomcat -d /opt/tomcat tomcat
	
	# download tomcat8-latest
	cd /usr/local/src
	wget "https://downloads.apache.org/tomcat/tomcat-8/v8.5.59/bin/apache-tomcat-8.5.59.tar.gz"
	
	check_file=`ls /usr/local/src | grep "\\<tomcat-8.5\\>" | wc -l`
	if [ ${check_file} -ne 0 ]
	then
		tar xvf apache-tomcat-8.5.59.tar.gz
		mkdir /opt/tomcat
		tar xvf apache-tomcat-8.5.59.tar.gz -C /opt/tomcat --strip-components=1
		cd /opt/tomcat/
		chgrp -R tomcat /opt/tomcat
		chmod -R g+r conf
		chmod -R g+x conf
		chown -R tomcat webapps/ work/ temp/ logs/
cat << tomcat_set >> /etc/systemd/system/tomcat.service
# Systemd unit file for tomcat
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/jre
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/bin/kill -15 \$MAINPID

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
tomcat_set
		systemctl daemon-reload
		systemctl start tomcat
		systemctl status tomcat
		systemctl enable tomcat
		
		#if [ "`netstat -nltp | grep "8080" | wc -l`" -ne 0 ]
		#then
		#	echo -en "${White}${Bold}tomcat installed success${Success}\n"
		#else
		#	echo -en "${White}${Bold}tomcat installed failed !!!!${Failed}\n"
		#	exit
		#fi
		# install tomcat-connector 1.2.48
		cd /usr/local/src
		wget http://apache.tt.co.kr/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.48-src.tar.gz
		tar -xvf tomcat-connectors-1.2.48-src.tar.gz
		cd tomcat-connectors-1.2.48-src/native
		if [ "`ls /usr/local/apache/bin/apxs | wc -l`" -ne 0 ]
		then
			./configure --with-apxs=/usr/local/apache/bin/apxs
			make
			make install
			if [ "`ls /usr/local/apache/modules/mod_jk.so | wc -l`" -ne 0 ]
			then
				echo -en "${White}${Bold}tomcat-connectors installed${Success}\n"
				if [ -f /usr/local/apache/conf/httpd.conf ]
				then
					last_line=`grep -n "LoadModule" /usr/local/apache/conf/httpd.conf | tail -1 | awk -F":" '{print $1}'`
					sed -i ''"${last_line}"'aLoadModule jk_module modules\/mod_jk.so' /usr/local/apache/conf/httpd.conf
					ipAddress=`ifconfig | grep "\<inet\>" | grep -v "127.0.0.1" | awk -F"inet" '{print $2}' | awk '{print $1}'`
					tomcatPath="/opt/tomcat/webapps/ROOT"
					echo >> /usr/local/apache/conf/httpd.conf
					echo -en "<VirtualHost *:80>\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "\tDocumentRoot ${tomcatPath}\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "\tServerName ${ipAddress}\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "\tjkMount /* worker1\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "\tErrorLog logs/error_log\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "\tCustomLog logs/access_log combined\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "</VirtualHost>\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "# 모듈 로드\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "JkWorkersFile \"conf/workers.properties\"\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "# 로그 파일\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "JkLogFile \"logs/mod_jk.log\"\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "JkLogLevel info\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "# 로그 형식\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "JkLogStampFormat \"[%a %b %d %h:%M:%S %Y]\"\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "JkRequestLogFormat \"%w%v%T\"\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "# 해당 확장자를 처리한 worker를 지정\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "JkMount /*.do worker1\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "JkMount /*.jsp worker1\n" >> /usr/local/apache/conf/httpd.conf
					echo -en "JkMount /servlet/* worker1\n" >> /usr/local/apache/conf/httpd.conf
cat << JkSet > /usr/local/apache/conf/workers.properties
worker.list=worker1
# protocol
worker:worker1.type=ajp13
# host
worker:worker1.host=localhost
# port
worker:worker1.port=8009
JkSet
					add_conf=`cat -n /opt/tomcat/conf/server.xml | grep "\!\-\- Define an AJP 1.3 Connector on port 8009 \-\-" | awk '{print $1}'`
					sed -i ''"${add_conf}"'a<Connector port="8009" address="0.0.0.0" protocol="AJP/1.3" secure="false" tomcatAuthentication="false" secretRequired="false"/>' /opt/tomcat/conf/server.xml
					/usr/local/apache/bin/apachectl -k restart
					systemctl restart tomcat
				else
					echo -en "${White}${Bold}/usr/local/apache/conf/httpd.conf file does not exist !${Failed}\n"
				fi
			else
				echo -en "${White}${Blod}tomcat-connectors installed${Failed}\n"
			fi
		else
			echo -en "${Red}${Bold}/usr/local/apache/bin/apxs does not exist !${Failed}\n"
			exit
		fi
	else
		echo -en "${Red}${Bold}tomcat-8.5*tar.gz file does not exist !${Failed}\n"
		exit
	fi
else
	echo -en "${Red}${Bold}yum list for java-1.7.0 does not exist!${Failed}\n"
	exit
fi
