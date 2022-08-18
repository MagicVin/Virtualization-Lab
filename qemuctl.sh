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
		echo modprobe $mod && modprobe $mod 2>/dev/null  && {
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
			echo "echo $busfpath > /sys/bus/pci/devices/${busfpath}/driver/unbind" && 
			echo $busfpath > /sys/bus/pci/devices/${busfpath}/driver/unbind && {
				fp detach $busfpath successfully
			} || {
				fp detach $busfpath failed
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
		[[ $vender_dev ]] && echo "echo $vender_dev > /sys/bus/pci/drivers/vfio-pci/new_id" && \
		echo $vender_dev > /sys/bus/pci/drivers/vfio-pci/new_id && fp attach $bus successfully
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

diskcreate() {
	# for performance: use raw
	qemu-img create -f raw -o preallocation=full /data/img/win10-disk0.img 60G
}

hugepagecreate() {
	# Temporarily Enabling 1 GB Hugepages
	echo 2 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages

}


cmdrun() {
	cmd=(
		taskset -c 14-17,32-35
		qemu-system-x86_64 
		-enable-kvm
		-machine type=q35, accel=kvm
		-nic none
		-vga none
		-serial none
		-parallel none 
		-nographic
		-cpu host,kvm=off
		-rtc base=localtime,clock=host
		-daemonize
		-k en-us
		-m 16G,slots=2 -mem-prealloc 
		-object memory-backend-file,size=16G,share=on,mem-path=/dev/hugepages,share=on,id=node0
		-numa node,nodeid=0,memdev=node0
		-smp cpus=16,cores=16,sockets=1
		-device pcie-root-port,chassis=0,id=pci.0,multifunction=on
		-device vfio-pci,host=65:00.0,bus=pci.0
		-device pcie-root-port,chassis=1,id=pci.1,multifunction=on
		-device vfio-pci,host=65:00.1,bus=pci.1
		-device pcie-root-port,chassis=2,id=pci.2,multifunction=on
		-device vfio-pci,host=b3:00.0,bus=pci.2
		-drive id=disk0,if=virtio,cache=none,format=raw,file=/data/img/win10-disk0.img
		-drive file=/data/iso/Windows10-Jun19-2022.iso,index=1,media=cdrom
		-boot dc

	)


}

main() {
	modinstall
	devpthr
}

main
