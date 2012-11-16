#!/bin/bash
NOW_DIR=$(pwd)
GLANCE_DIR=/etc/glance
. $NOW_DIR/setting

setup_glance_sql () {
	
	mysql -h $MYSQL_HOST -u root -p$MYSQL_ROOT_PASS -e 'DROP DATABASE IF EXISTS glance;'
        mysql -h $MYSQL_HOST -u root -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE glance;'
        mysql -h $MYSQL_HOST -u root -p$MYSQL_ROOT_PASS -e "GRANT ALL ON glance.* TO 'glance'@'%' IDENTIFIED BY '$MYSQL_GLANCE_PASS';"

}

install_glance () {
        wget https://launchpad.net/glance/folsom/2012.2/+download/glance-2012.2.tar.gz -P $DEST/
        cd $DEST
        tar -xzvf $DEST/glance-2012.2.tar.gz
        cd $DEST/glance-2012.2/
        pip install -r tools/pip-requires
        python setup.py install
}

install_glanceclient () {
        wget https://launchpad.net/python-glanceclient/trunk/0.4.1/+download/python-glanceclient-0.4.1.tar.gz -P $DEST/
        cd $DEST
        tar -xzvf $DEST/python-glanceclient-0.4.1.tar.gz
        cd $DEST/python-glanceclient-0.4.1/
        pip install -r tools/pip-requires
        python setup.py install
}

install_keystoneclient () {
	if [ "$KEYSTONE_IP" != "$GLANCE_IP" ];then
		echo "installing keystoneclient..."
	        wget https://launchpad.net/python-keystoneclient/trunk/0.1.2/+download/python-keystoneclient-0.1.2.tar.gz -P $DEST/
	        cd $DEST
        	tar -xzvf $DEST/python-keystoneclient-0.1.2.tar.gz
        	cd $DEST/python-keystoneclient-0.1.2/
        	pip install -r tools/pip-requires
        	python setup.py install

	fi
}

config_glance_keystone () {
	local file=$1
	sed -i "s/KEYSTONE_IP/$KEYSTONE_IP/g" $file
	sed -i "s/TENANT_NAME/$TENANT_NAME/g" $file
	sed -i "s/USER_NAME/$USER_NAME/g" $file
	sed -i "s/PASSWORD/$PASSWORD/g" $file
}

configure_glance () {
	if [ ! -d "/etc/glance" ];then
                mkdir /etc/glance
        fi
	if [ ! -d "/var/log/glance" ];then
                mkdir /var/log/glance
        fi
	if [ ! -d "/var/lib/glance/images" ];then
                mkdir -p /var/lib/glance/images
        fi
	cp $DEST/glance-2012.2/etc/* /etc/glance/
	config_glance_keystone $NOW_DIR/glance-api.conf
	config_glance_keystone $NOW_DIR/glance-registry.conf	

	sed -i "s/MYSQL_HOST/$MYSQL_HOST/g" $NOW_DIR/glance-registry.conf
	sed -i "s/MYSQL_GLANCE_PASS/$MYSQL_GLANCE_PASS/g" $NOW_DIR/glance-registry.conf

	cp $NOW_DIR/glance-registry.conf /etc/glance
	cp $NOW_DIR/glance-api.conf /etc/glance
	
}

if [ "$KEYSTONE_IP" != "$GLANCE_IP" ];then
	apt-get install build-essential git python-dev python-setuptools python-pip libxml2-dev libxslt-dev
fi
setup_glance_sql
install_glance
install_glanceclient
install_keystoneclient
configure_glance
glance-manage db_sync
glance-control api start
glance-control registry start
