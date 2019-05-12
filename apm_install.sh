#!/bin/sh

mysql_path="/usr/local/src/apm"

# Color
Red="\033[2;31m"
Red_White="\033[1;41m"
Reset="\033[1;0m"

# Path
default_path="/usr/local/src"
apm_path="/usr/local/src/apm"

# ^M bad interpreter delete
yum -y install dos2unix

# install apm
install_apm(){
	cd ${default_path}/
	wget "https://github.com/kimtaekhan/apm/raw/master/apm.tar.gz"
	tar -xvf apm.tar.gz
	rm -f ${default_path}/apm.tar.gz
}

# Check if a directory exists
if [ ! -d ${apm_path} ]
then
	echo -en "${Red_White}${apm_path}${Reset} ${Red}directory is not exist !${Reset}\n"
	echo -en "${Red_White}${apm_path}${Reset} ${Red}make directory now !${Reset}\n"
	mkdir ${apm_path}
	mkdir ${apm_path}/apache
	mkdir ${apm_path}/php
	mkdir ${apm_path}/mysql
	mkdir ${apm_path}/ext
	mkdir ${apm_path}/config
elif [ -d ${apm_path} ]
then
	if [ ! -d ${apm_path}/apache ]
	then
		echo -en "${Red}directory for different purposes !"
		echo -en "a modification to the script is required !${Reset}\n"
		exit 1
	elif [ -d ${apm_path}/apache ]
	then
		echo -en "${Red} Already installed !"
		echo -en "Exit Script !${Reset}\n"
		exit 0
	fi
fi

# Check if a Wget Command exists
wget_exist_check=`yum list installed | grep wget | wc -l`
if [ "${wget_exist_check}" -eq 0 ]
then
	echo -en "${Red}Command is not exist !${Reset}\n"
	echo -en "${Red}install wget start !${Reset}\n"
	yum -y install wget
	install_apm
	${apm_path}/install.sh
elif [ "${wget_exist_check}" -eq 1 ] # go !
then
	install_apm
	${apm_path}/install.sh
fi

exit 0
