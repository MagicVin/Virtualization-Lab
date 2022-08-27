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
	)
	
	[ ${#devlist[@]} -gt 0 ] && bus_ids=(`lspci | egrep $(echo "${devlist[@]}" | sed 's/ /|/g') | awk '{print $1}'`)
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

cmdrun() {
	cmd=(
		taskset -c 14-17,32-35
		qemu-system-x86_64 
		-name win10,debug-threads=on
		-enable-kvm
		-machine type=q35,accel=kvm,hmat=on
		-nic none
		-vga none
		-serial none
		-parallel none 
		-cpu Cascadelake-Server,kvm=off,hv_relaxed,hv_vapic,hv_time,hv_spinlocks=0x1fff
		-rtc base=localtime,clock=host
		-daemonize
		-k en-us

		-m 16G,maxmem=256G,slots=2 -mem-prealloc -overcommit mem-lock=on
		-smp cpus=8,sockets=1,cores=4,threads=2

		-object memory-backend-file,id=mem,size=16G,mem-path=/dev/hugepages,prealloc=on,share=off,discard-data=on,host-nodes=0,policy=bind,align=1G,merge=on
		-numa node,memdev=mem,cpus=0-7,nodeid=0,initiator=0

		-numa cpu,node-id=0,socket-id=0,core-id=0,thread-id=0
		-numa cpu,node-id=0,socket-id=0,core-id=1,thread-id=0
		-numa cpu,node-id=0,socket-id=0,core-id=2,thread-id=0
		-numa cpu,node-id=0,socket-id=0,core-id=3,thread-id=0
		-numa cpu,node-id=0,socket-id=0,core-id=0,thread-id=1
		-numa cpu,node-id=0,socket-id=0,core-id=1,thread-id=1
		-numa cpu,node-id=0,socket-id=0,core-id=2,thread-id=1
		-numa cpu,node-id=0,socket-id=0,core-id=3,thread-id=1

		-boot order=dc,menu=on
		-bios /usr/share/ovmf/OVMF.fd
	)

	echo ${cmd[@]}
}
		#-device vfio-pci,host=b4:00.0,bus=pcie.0
		#-device ioh3420,bus=pcie.0,addr=1c.0,multifunction=on,port=1,chassis=1,id=root.1
		#-device vfio-pci,host=65:00.0,bus=root.1,addr=00.0,multifunction=on,x-vga=on
		#-device vfio-pci,host=65:00.1,bus=root.1,addr=00.1
		#-drive file=/data/iso/Windows10-Jun19-2022.iso,index=0,media=cdrom
		#-drive file=/data/drv/virtio-win.iso,index=2,media=cdrom
		#-device nvme,drive=nvme0,serial=deadbeaf,max_ioqpairs=8
		#-drive file=/data/img/win10-nvme0-os.img,if=none,format=raw,cache=none,aio=native,id=nvme0,index=1,media=disk
		#-drive file.driver=nvme,file.device=0000:b3:00.0,file.namespace=1,media=disk

main() {
	#modinstall
	#devpthr
	cmdrun
}

main
