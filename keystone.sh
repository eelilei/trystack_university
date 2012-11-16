#!/bin/bash

NOW_DIR=$(pwd)
#DEST= ~/
. $NOW_DIR/setting

install_mysql () {
	apt-get install -y mysql-server mysql-client python-mysqldb curl

	sed -i '/^bind-address/s/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
}

# Keystone Setup
setup_keystone_sql () { 
	mysql -h $MYSQL_HOST -u root -p$MYSQL_ROOT_PASS -e 'DROP DATABASE IF EXISTS keystone;'
	mysql -h $MYSQL_HOST -u root -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE keystone;'
	mysql -h $MYSQL_HOST -u root -p$MYSQL_ROOT_PASS -e "GRANT ALL ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$MYSQL_KEYSTONE_PASS';"

}

install_keystone () { 
	wget https://launchpad.net/keystone/folsom/2012.2/+download/keystone-2012.2.tar.gz -P $DEST/
	cd $DEST
	tar -xzvf $DEST/keystone-2012.2.tar.gz
	cd $DEST/keystone-2012.2/
	pip install -r tools/pip-requires 
	python setup.py install
}

install_keystoneclient () {
	wget https://launchpad.net/python-keystoneclient/trunk/0.1.2/+download/python-keystoneclient-0.1.2.tar.gz -P $DEST/
	cd $DEST
	tar -xzvf $DEST/python-keystoneclient-0.1.2.tar.gz
	cd $DEST/python-keystoneclient-0.1.2/
	pip install -r tools/pip-requires       
	python setup.py install
}

configure_keystone () {
	cd $NOW_DIR
	sed -i "s/MYSQL_HOST/$MYSQL_HOST/g" keystone.conf
	sed -i "s/MYSQL_KEYSTONE_PASS/$MYSQL_KEYSTONE_PASS/g" keystone.conf

	if [[ -d "/etc/keystone" ]];then
		echo "/etc/keystone exist"
	else
		mkdir /etc/keystone
	fi

	if [[ -d "/var/log/keystone" ]];then
		echo "/var/log/keystone exist"
        else
                mkdir /var/log/keystone
        fi
	cp keystone.conf /etc/keystone/keystone.conf

	#keystone endpoint template
	sed -i "s/KEYSTONE_IP/$KEYSTONE_IP/g" default_catalog.templates
	sed -i "s/NOVA_IP/$NOVA_IP/g" default_catalog.templates
	sed -i "s/GLANCE_IP/$GLANCE_IP/" default_catalog.templates
	sed -i "s/NOVA_VOLUME_IP/$NOVA_VOLUME_IP/g" default_catalog.templates
	
	cp default_catalog.templates /etc/keystone/default_catalog.templates
	cp $DEST/keystone-2012.2/etc/policy.json /etc/keystone/policy.json

}

# Function to get ID :
get_id () {
        echo `$@ | awk '/ id / { print $4 }'`
}


creat_user () {
	local tenant_name=$1
	local user_name=$2
	local role_name=$3
	local password=$4
	
	tenant_id=$(keystone tenant-create --name $tenant_name --description "Admin Tenant" --enabled true | awk '/ id / { print $4 }')

	user_id=$(keystone user-create --tenant_id $tenant_id --name $user_name --pass $password --enabled true | awk '/ id / { print $4 }')

	role_id=$(keystone role-create --name $role_name | awk '/ id / { print $4 }')

	keystone user-role-add --user-id $user_id --tenant-id $tenant_id --role-id $role_id

}


apt-get -y install build-essential git python-dev python-setuptools python-pip libxml2-dev libxslt-dev
install_mysql
setup_keystone_sql
install_keystone
install_keystoneclient
configure_keystone
keystone-manage db_sync
keystone-all &
echo "please wait 5 seconds for keystone service starting.."
sleep 5
creat_user $TENANT_NAME $USER_NAME $ROLE_NAME $PASSWORD


