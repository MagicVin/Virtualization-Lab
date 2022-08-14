#!/bin/bash

p2() {
	p2lens=10
	printf "%-${p2lens}s %-s\n" $1 $2
}

p3() {
	p3lens=10
	printf "%-${p3lens}s %-10s %-s\n" $1 $2 $3
}

fp() {
	fplens=10
	printf "%-${fplens}s " $@ && printf "\n"
}

modinstall() {
	modlist=(
		vfio
		vfio_pci
		msr
		kvm
		kvm_intel
		)
	echo "Modules installing ..."
	for mod in ${modlist[@]} ;{
		modprobe $mod 2>/dev/null  && {
			fp install $mod successfully 
		} || {
			fp install $mod failed
			exit -1
		}
	}
}

drvdetach() {
	for bus in ${bus_ids[@]} ;{
		[ -f /sys/bus/pci/devices/*${bus}/driver/unbind ] && {
			busfpath="`ls -d /sys/bus/pci/devices/*${bus}`"
			busfpath=${busfpath##*/}
			echo $busfpath > /sys/bus/pci/devices/${busfpath}/driver/unbind && {
				fp detach $busfpath successfully
			} || {
				fp detach $busfpath failed
				exit -1
			}
			drvname="`ls /sys/bus/pci/devices/${busfpath}/driver -l`"
			drvname=${drvname##*/}
			vender_dev=`lspci -s $bus -n | sed -n 's/^.*\([[:alnum:]]\{4\}\)\:\([[:alnum:]]\{4\}\).*/\1 \2/p'`
			echo $vender_dev > /sys/bus/pci/drivers/${drvname}/remove_id && {
				fp remove $vender_dev successfully
			} || {
				fp remove $vender_dev failed 
				exit -1
			}
		} || {
			echo $bus is free to use
		}
	}
}

drvattach() {
	fp vfio devices list: `ls /dev/vfio | xargs`
	for bus in ${bus_ids[@]} ;{
		vender_dev=`lspci -s $bus -n | sed -n 's/^.*\([[:alnum:]]\{4\}\)\:\([[:alnum:]]\{4\}\).*/\1 \2/p'`
		[[ $vender_dev ]] && echo $vender_dev > /sys/bus/pci/drivers/vfio-pci/new_id && fp attach $bus successfully
	}
	fp vfio devices list: `ls /dev/vfio | xargs`
}

devpthr() {
	devlist=(
		NVIDIA
		VIA
	)
	
	bus_ids=(`lspci | egrep $(echo "${devlist[@]}" | sed 's/ /|/g') | awk '{print $1}'`)
	devpath=/sys/bus/pci/devices/
	[ ${#bus_ids[@]} -lt 1 ] && { 
		echo there is no device needs to passthrough 
	} || {
		drvdetach && drvattach
	}
}


main() {
	modinstall
	devpthr

}

main
