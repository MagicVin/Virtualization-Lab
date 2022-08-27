#!/bin/bash

netconf() {
	nic=enx00e04c330c6a
	init_ipconf="192.168.132.20/24"
	while true
	do
		ipconf=`ip address show $nic | awk '/inet.*global/ {print $2}'`
		[ "$init_ipconf" == "$ipconf" ] && {
			continue
		} || {
			ip address add dev $nic $init_ipconf
		}
		sleep 5
	done
}

start_main() {

	netconf &
}

start_main
