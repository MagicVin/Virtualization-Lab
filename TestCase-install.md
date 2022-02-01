**Test Case: virt-install** 

**Targets**
  1. Setup virtualization env
  2. Manually install vm
  3. Automating install vm
 
**Test Env**
  1. Laptop: Thinkpad x390
  2. Ethernet does work
  3. Alpine Linux(5.15.12-0-lts) as the host OS
  4. CentOS 8 as the guest OS

**Test date**  
Jan 31, 2022

# Table
1. [Software Env](#softwareenv)
2. [VM installation](#vm-installation)
3. [Appendix: Get the kickstart file](#appendix)
 

## SoftwareEnv

### Install virtualization softwares
  ```
  # apk add virt-manager virt-viewer virt-install  
  # apk add libvirt-daemon libvirt-client  
  # apk add qemu-img qemu-system-x86_64 qemu-modules  
  # apk openrc cdrkit
  ```
### Enableing the virtualization env
  1. Enable **VT-d** feature on BIOS setup
  2. Enable **intel_iommu=on** for kernel grub    
  3. Install virtualization modules 
  ```
  # modprobe tun vfio fuse vhost_net
  ```
  4. Enable and start the **libvirtd** service
  ```
  # rc-update add libvirtd  
  # rc-service libvirtd start
  ```
  5. Valify the host KVM requirements
  ```
  # virt-host-validate
  ```
  6. Download the **CentOS-8-x86_64-1905-dvd1.iso** ISO and then store properly 

### Install Apache web server and mount ISO for remote installation
  1. Install apache2 package
  ```
  # apk add apache2
  ```
  2. Enable and start the apache web server
  ```
  # rc-update add apache2  
  # rc-service start apache2  
  ```
  3. Mount the ISO for the apache server
  ```
  # mkdir /var/www/localhost/htdocs/iso
  # mount /media/qemu/CentOS-8-x86_64-1905-dvd1.iso /var/www/localhost/htdocs/iso
  ```
  4. Get the host ip first
  ```
  # ip a | grep inet
  inet 127.0.0.1/8 scope host **lo**
  inet 192.168.10.10/24 brd 192.168.10.255 scope global **wlan0**
  inet 192.168.122.1/24 brd 192.168.122.255 scope global **virbr0**
  ```
  Non-localhost IPs: 192.168.10.10 and 192.168.122.1, pick up one of them for the test  
  5. Open the host's browser to check the web site does work, input  
  * http://127.0.0.1/iso  
  * http://localhost/iso  
  * http://192.168.10.10/iso  
  * http://192.168.122.1/iso  
  
## VM-installation
### Manually install
* Manually install from **CDROM**, commands as the following shows
```
# virt-install --debug --virt-type kvm --name kvm-cdrom --vcpus 2 --ram 2048 --os-variant rhel8.0 --cdrom /media/CentOS-8-x86_64-1905-dvd1.iso --network default --graphics vnc --disk size=10
```
* Manually install from **Location**(very similar with **CDROM**), commands as the following shows
```
# virt-install --debug --virt-type kvm --name kvm-location --vcpus 2 --ram 2048 --os-variant rhel8.0 --location /media/CentOS-8-x86_64-1905-dvd1.iso --network default --graphics vnc --disk size=10 --extra-args ro
```
(**DNF error:** error in posttrans scriptlet in rpm package kernel-core, workaround by adding **--extra-args ro**)
* Manually install from **Network**, commands as the following shows  
  
  Use the wlan0's IP or use the virbr0's IP
```
# virt-install --debug --virt-type kvm --name kvm-net --vcpus 2 --ram 2048 --os-variant rhel8.0 --location http://192.168.10.10/iso --network default --graphics vnc --disk size=10
```
```
# virt-install --debug --virt-type kvm --name kvm-net-virbr --vcpus 2 --ram 2048 --os-variant rhel8.0 --location http://192.168.122.1/iso --network default --graphics vnc --disk size=10
```
### Automating install -- use kickstart file
* Automting install from **ISO** , commands as the following shows  
(kickstart file: ks.cfg from kvm-cdrom)
```
# virt-install --debug --virt-type kvm --name kvm-auto-location --vcpus 2 --ram 2048 --os-variant rhel8.0 --location /media/CentOS-8-x86_64-1905-dvd1.iso --network default --graphics vnc --disk size=10 -x ks=http://192.168.122.1/ks.cfg
```
* Automting install from **Network** , commands as the following shows  
(kickstart file: ks.cfg from kvm-net-virbr)
```
# virt-install --debug --virt-type kvm --name kvm-auto-net --vcpus 2 --ram 2048 --os-variant rhel8.0 --location http://192.168.122.1/iso --network default --graphics vnc --disk size=10 -x ks=http://192.168.122.1/ks.cfg
```
### Batch install
Automating create **five VMs**, script: batch-vm.sh
```
#!/bin/bash
cmds=(
  virt-install
  --debug
  --virt-type kvm
  --vcpus 2
  --ram 2048
  --os-variant rhel8.0
  --location http://192.168.122.1/iso
  --network default
  --graphics vnc
  --disk size=10
  -x "ks=http://192.168.122.1/ks.cfg"
)
for i in {1..5} ;{
  vms=(${cmds[@]} --name kvm-$i)
  echo ${vms[@]} && echo ${vms[@]}
  sleep 10
}
```
Perform the script and then wait it done.

## Appendix
(Get the kickstart file)
1. Create the virtual disk  
```
# qemu-img create -f qcow2 /media/qemu/data.qcow2 10G
```  
2. Make filesystem  
```
# mkfs.ext4 /media/qemu/data.qcow2
```  
3. Add the vdisk for the vm(e.g., **kvm-cdrom**)  
```
# virsh edit kvm-cdrom
```  
(Merge the following xml configs```<disk>...</disk>``` into the vm xml between with the ```<devices> ... </devices>``` )  
```
<devices>
 ...
  <disk type='file' device='disk'>
    <driver name='qemu' type='raw'/>
    <source file='/media/qemu/data.qcow2'/>
    <target dev='vdb' bus='virtio'/>
    <address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
  </disk>
 ...
</devices>
```
4. Start the vm  
```
# virsh start kvm-cdrom
```  
5. Login the vm  
```
# virt-viewer
```  
6. Mount the vdisk which name is vdb  
```
# mount /dev/vdb /mnt
```
7. Copy the kickstart file: /root/anaconda.cfg  
```
# cp /root/anaconda.cfg /mnt/ks.cfg
```  
8. Umount and shutdown the vm  
```
# umount /mnt && poweroff
```
9. Host the ks.cfg
```
# mount /media/qemu/data.qcow2 /mnt 
# cp /mnt/ks.cfg /var/www/localhost/htdocs/ks.cfg
# chmod +r /var/www/localhost/htdocs/ks.cfg
# umount /mnt
