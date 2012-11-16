#!/bin/bash
NOW_DIR=$(pwd) 
. $NOW_DIR/nova-base.sh

va_controller () {
        sed -i "s/%controller_ip%/$NOVA_CONTROLLER_IP/g" $NOW_DIR/nova.conf
        sed -i "s/%compute_ip%/$COMPUTE_IP/g" $NOW_DIR/nova.conf
        cp $NOW_DIR/nova.conf /etc/nova
        sed -i "s/server ntp.ubuntu.com/$NOVA_CONTROLLER_IP/g" /etc/ntp.conf

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

nova_start () {
        nova-api &
        nova-network &
        nova-compute &

}


config_nova_controller 
nova_start 
