#!/bin/bash
NOW_DIR=$(pwd)
. $NOW_DIR/nova-base.sh

config_nova_controller () {
	sed -i "s/%controller_ip%/$NOVA_CONTROLLER_IP/g" $NOW_DIR/nova.conf
	sed -i "s/%compute_ip%/$NOVA_CONTROLLER_IP/g" $NOW_DIR/nova.conf
	cp $NOW_DIR/nova.conf /etc/nova

	sed -i "s/server ntp.ubuntu.com/server ntp.ubuntu.com\nserver 127.127.1.0\nfudge 127.127.1.0 stratum 10/g" /etc/ntp.conf

	if [ ! -d "/var/log/nova" ];then
                mkdir /var/log/nova
        fi
	if [ ! -d "/var/lock/nova" ];then
                mkdir /var/lock/nova
        fi
	if [ ! -d "/opt/nova/instances" ];then
                mkdir -p /opt/nova/instances
        fi

}

config_nova_volume () {
	sed -i "s/false/true/g" /etc/default/iscsitarget
	service iscsitarget restart
	pvcreate /dev/$VOLUME_DEVICE
	vgcreate nova-volumes /dev/$VOLUME_DEVICE
}

nova_start () {
	nova-api &
	nova-scheduler &
	nova-network &
	nova-cert &
	nova-consoleauth &
	
}

create_network () {
	nova-manage network create private $FIXED_RANGE_NET $FIXED_RANGE_NETWORK_COUNT $FIXED_RANGE_NETWORK_SIZE --bridge=$BRIDGE
	nova-manage floating create $FLOATING_RANGE_NET
}

config_nova_controller 
config_nova_volume
nova-manage db sync
sleep 5
nova_start
sleep 5
create_network
