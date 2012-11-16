#!/bin/bash
NOW_DIR=$(pwd)
. $NOW_DIR/setting

install_required_software () {
	apt-get install -y build-essential git python-dev python-setuptools python-pip python-mysqldb libxml2-dev libxslt-dev
	apt-get install-y rabbitmq-server bridge-utils ntp
	rabbitmqctl change_password guest openstack
	apt-get install -y lvm2 iscsitarget open-iscsi iscsitarget-source iscsitarget-dkms tgt
	apt-get install -y libhivex0 btrfs-tools cryptsetup diff libaugeas0 reiserfsprogs zfs-fuse jfsutils scrub xfsprogs zerofree libfuse2
	/etc/init.d/tgt start
	apt-get install -y qemu libvirt-bin libvirt-dev python-libvirt kvm ebtables nbd-server nbd-client qemu-kvm dnsmasq-utils
}

setup_nova_sql () {

        mysql -h $MYSQL_HOST -u root -p$MYSQL_ROOT_PASS -e 'DROP DATABASE IF EXISTS nova;'
        mysql -h $MYSQL_HOST -u root -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE nova;'
        mysql -h $MYSQL_HOST -u root -p$MYSQL_ROOT_PASS -e "GRANT ALL ON nova.* TO 'nova'@'%' IDENTIFIED BY '$MYSQL_NOVA_PASS';"

}


install_keystoneclient () {
        wget https://launchpad.net/python-keystoneclient/trunk/0.1.2/+download/python-keystoneclient-0.1.2.tar.gz -P $DEST/
        cd $DEST
        tar -xzvf $DEST/python-keystoneclient-0.1.2.tar.gz
        cd $DEST/python-keystoneclient-0.1.2/
        pip install -r tools/pip-requires
        python setup.py install
}

install_nova () {
	wget https://launchpad.net/nova/folsom/2012.2/+download/nova-2012.2.tar.gz -P $DEST/
	cd $DEST
	tar -xzvf $DEST/nova-2012.2.tar.gz
	cd $DEST/nova-2012.2/
        pip install -r tools/pip-requires
        python setup.py install
	 
}

install_novaclient () {
	wget https://launchpad.net/python-novaclient/trunk/2.6.10/+download/python-novaclient-2.6.10.tar.gz -P $DEST
        cd $DEST
        tar -xzvf $DEST/python-novaclient-2.6.10.tar.gz
        cd $DEST/python-novaclient-2.6.10/
        pip install -r tools/pip-requires
        python setup.py install
}

config_nova_keystone () {
        local file=$1
        sed -i "s/KEYSTONE_IP/$KEYSTONE_IP/g" $file
        sed -i "s/TENANT_NAME/$TENANT_NAME/g" $file
        sed -i "s/USER_NAME/$USER_NAME/g" $file
        sed -i "s/PASSWORD/$PASSWORD/g" $file
}

config_nova () {
	if [[ "$LIBVIRT_TYPE" == "kvm" ]];then
        	modprobe kvm || true
        	if [ ! -e /dev/kvm ];then
                	LIBVIRT_TYPE=qemu
        	fi
	fi

	cp -r $DEST/nova-2012.2/etc/nova /etc
	config_nova_keystone $NOW_DIR/api-paste.ini
        sed -i "s/KEYSTONE_IP/$KEYSTONE_IP/g" $NOW_DIR/nova.conf
	sed -i "s/MYSQL_NOVA_PASS/$MYSQL_NOVA_PASS/g" $NOW_DIR/nova.conf
	sed -i "s/HOST_IP/$HOST_IP/g" $NOW_DIR/nova.conf
	sed -i "s/%swift_ip/$SWIFT_IP/g" $NOW_DIR/nova.conf
	sed -i "s/%glance_ip/$GLANCE_IP/g" $NOW_DIR/nova.conf
	sed -i "s/ISCSI_IP_PREFIX/$ISCSI_IP_PREFIX/g" $NOW_DIR/nova.conf
        sed -i "s/eth0/$PUBLIC_INTERFACE/g" $NOW_DIR/nova.conf
        sed -i "s/eth1/$FLAT_INTERFACE/g" $NOW_DIR/nova.conf
        sed -i "s/kvm/$LIBVIRT_TYPE/g" $NOW_DIR/nova.conf
	
}

setup_nova_sql
install_required_software
if [ "$KEYSTONE_IP" != "$NOVA_IP" ];then
	install_keystoneclient
fi
#install_nova
#install_novaclient
config_nova
