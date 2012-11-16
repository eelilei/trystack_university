#!/bin/bash
NOW_DIR=$(pwd)
. $NOW_DIR/setting

install_horizon () {
	apt-get install build-essenial git python-dev python setuptools python-pip memcached nodejs
	pip install django python-memcached
        wget https://launchpad.net/horizon/folsom/2012.2/+download/horizon-2012.2.tar.gz -P $DEST/
        cd $DEST
        tar -xzvf $DEST/horizon-2012.2.tar.gz
        cd $DEST/horizon-2012.2/
        pip install -r tools/pip-requires
}

config_horizon () {
	sed -i "s/%keystone_ip%/$KEYSTONE_IP/g" $NOW_DIR/local_settings.py
	cp $NOW_DIR/local_settings.py $DEST/horizon-2012.2/openstack_dashboard/local/
}

install_horizon
config_horizon
$DEST/horizon-2012.2/manage.py runserver 0.0.0.0:8989
