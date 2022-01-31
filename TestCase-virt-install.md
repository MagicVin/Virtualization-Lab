# Test Case: virt-install 

Targets: 
  1. Setup virtualization env
  2. Create the first vm
  3. Automating installation
 
Test Env:
  1. Laptop: Thinkpad x390
  2. Ethernet does work
  3. Alpine Linux as the host OS
  4. CentOS 8 as the guest OS

Test date:  
  Jan 31, 2022
 


## Software Env
### Install softwares
  1. Install virtualization software  
     ```
     # apk add virt-manager virt-viewer virt-install  
     # apk add libvirt-daemon libvirt-client  
     # apk add qemu-img qemu-system-x86_64 qemu-modules  
     # apk openrc cdrkit
     ```
  2. Install Apache web server
    ```
    # apk add apache2
    ```
### Enableing the virtualization env
  1. Enable **VT-d** feature on BIOS setup
  2. Enable **intel_iommu=on** for kernel grub    
  3. Install virtualization modules ```# modprobe tun vfio fuse vhost_net```
  4. Enable and start the **libvirtd** service
     ```
     # rc-update add libvirtd  
     # rc-service libvirtd start
     ```
  5. Valify the host KVM requirements```# virt-host-validate```
  6. Download the **CentOS 8** ISO and then store properly 

  
## VM installation
### Install the first VM
  1. Create Script: firstvm.sh  
     ```  
     #!/bin/bash  
     cmds=(  
       virt-install  
       --virt-type=kvm  
       --name MasteringKVM01  
       --vcpus 2  
       --ram 2048  
       --os-variant=rhel8.0  
       --cdrom=/media/CentOS-Stream-8-x86_64-latest-dvd1.iso  
       --network=default  
       --graphics vnc  
       --disk size=10  
       )  
       
     echo ${cmds[@]}  
     ${cmds[@]}  
     ```
  2. Perform the script with root user```# bash firstvm.sh```
  3. Pass the installing progress

### Automating installation
  1. Copy the kickstart file from /root/anaconda.cfg on the first vm
  2. Enable and start the apache web server
     ```
     # rc-update add apache2  
     # rc-service start apache2  
     ```
  3. Stop and disable firewalld 
  4. Rename the anaconda.cfg by ks.cfg and move it to /var/www/localhost/htdocs and give it read permission
  5. Open browser and go to **http://localhost/ks.cfg** to verify the apache server web does work
  6. Create the automating installation script: autovm.sh
     * Use the absolute file path( needs isoinfo provided by cdrkit)
       ```
       #!/bin/bash
       cmds=(  
         virt-install  
         --debug  
         --virt-type=kvm  
         --name MasteringKVM02  
         --vcpus 2  
         --ram 2048  
         --network=default  
         --location "/iso/CentOS-Stream-8-x86_64-latest-dvd1.iso"  
         --os-variant rhel8.0  
         --graphics vnc  
         --disk size=10  
         -x "ks=http://localhost/ks.cfg"  
         )  
     
       echo ${cmds[@]}  
       ${cmds[@]}  
       ```
     * (Trial, needs to change ks.cfg) Use the url path( needs the tree info of the ISO, create the tree topology)
       ```
       #!/bin/bash
       mount -t iso9660 /iso/CentOS-Stream-8-x86_64-latest-dvd1.iso /var/www/localhost/htdocs/iso
       cmds=(  
         virt-install  
         --debug  
         --virt-type=kvm  
         --name MasteringKVM02  
         --vcpus 2  
         --ram 2048  
         --network=default  
         --location "http://localhost/iso"  
         --os-variant rhel8.0  
         --graphics vnc  
         --disk size=10  
         -x "ks=http://localhost/ks.cfg"  
         )  
     
       echo ${cmds[@]}  
       ${cmds[@]}  
       ```
    
  7. Perform the script with root user```# bash autovm.sh```
  8. Wait it done
  
