<h2>GPU passthrough</h2>

* Agenda  
    * [Test environment](#test)
    * [Platform virtualization support](#platform)
    * [Kernel passthrough support](#kernel_pthr)
    * [Driver and PCIe device configuration](#drv_conf)
    * [Performance tuning](#perf)
    * [Qemu-kvm setup](#qemu_setup)
    * [Best Practicesl](#bestprac)
    * [Refernces](#refer)


<h2>Test environment</h2>
    
* Hardware list
    * x1 Inspur NF5212M5 x86 server
    * x1 Dell UltraSharp 24 Monitor
    * x1 Dell GTX 1060 6G graphic card
    * x1 mini 8pin GPU power cable
    * x1 Keyboard
    * x1 Mouse
    * x1 USB HUB
    * x1 500G samsung SSD
    * x2 PCIe riser card
    * x1 256G NVMe M.2 SSD
    * x1 USB wireless adapters for vm
    * x1 USB wireless adapters for host
    * x4 16G 2400MHz samsung DDR4
    * x1 QQ8Q(6240) CLX CPU
    * x1 500W power supply
    * x1 USB wifi connector
    * x2 NF-A6x25 PWM PREMIUM FANs
    * x1 PCIe card for extend x4 ports USB 3.0 support
    * x1 PCIe card for convert NVMe M.2 interface to PCIe

* Software list
    * OS: Ubuntu 22.04 TLS
    * Kernel: Linux 5.15.0-43-generic
    * DM: lightdm
    * WM: Awesome
    * X server: xorg
    * Term: xterm


<h2 name="platform">Platform virtualization support</h2>
<ol>
   
<li>CPU Hyperthreading enabled</li>   
<li>BIOS virtualization feature enabled: VT-x and VT-d</li>
<li>UEFI BOOT enabled</li>
<li>Motherboard integrated video device supported and set as default graphic</li>

    BIOS: Processor/Processor Configuration/Hyper Threading Technology -> Enabled
    BIOS: Processor/Processor Configuration/VMX -> Enabled
    BIOS: Processor/IIO Configuration/Intel VT for Directed I/O(VT-d) -> Enabled
    BIOS: Chipset/Miscellaneous Configuration/VGA Priority -> Onboard Device
    BIOS: Advanced/PCI Subsystem Settings/Above 4GB Decoding -> Enabled
    BIOS: Advanced/PCI Subsystem Settings/SR-IOV Support -> Enabled
    BIOS: Advanced/CSM Configuration/Boot Mode -> UEFI Mode

<li>CPU virtualization supported, the following result must be greater than zero</li>
       
    # egrep -c '(vmx|svm)' /proc/cpuinfo
    72
<li>KVM Virtualization supported</li>

    # ls -l /dev/kvm
    crw-rw----+ 1 root kvm 10, 232 Aug  7 13:36 /dev/kvm
    
</ol>

<h2 name="kernel_pthr">Kernel passthrough support</h2>

- Grub config list 
    - Disable selinux

        ```
        selinux=0
        ```
    - Enable console for debugging purpose
        ```
        console=ttyS0,115200
        ```
    - Enable IOMMU(virtualization technoligy)

        The **pt** option only enables IOMMU for devices used in passthrough and will provide better host performance. However, the option may not be supported on all hardware. Revert to previous option if the pt option doesn't work for your host. [From](https://access.redhat.com/documentation/en-us/red_hat_virtualization/4.1/html/installation_guide/appe-configuring_a_hypervisor_host_for_pci_passthrough)
        ```
        iommu=pt intel_iommu=on
        ```
    - Enable ACS override patch
        
        There are multiple devices in the same IOMMU group, this patch allows each device to be placed into its own IOMMU group
        ```
        pcie_acs_override=downstream,multifunction
        ```
    - IOMMU Interrupt Remapping

        All systems using an Intel processor and chipset that have support for Intel Virtualization Technology for Directed I/O (VT-d), but do not have support for interrupt remapping will see such an error. Interrupt remapping support is provided in newer processors and chipsets (both AMD and Intel).

        To identify if your system has support for interrupt remapping:

        ```
        # dmesg | grep 'remapping'
        AMD: "AMD-Vi: Interrupt remapping enabled"
        Intel: "DMAR-IR: Enabled IRQ remapping in x2apic mode"
        ```

        If the passthrough fails because the hardware does not support interrupt remapping, you can consider enabling the **allow_unsafe_interrupts** option if the virtual machines are trusted. The **allow_unsafe_interrupts** is not enabled by default because enabling it potentially exposes the host to MSI attacks from virtual machines
        
        Add following to /etc/default/grub [From](https://forum.proxmox.com/threads/iommu-unsafe-interrupts-enabled-still-error-message.67341/)

        ```
        vfio_iommu_type1.allow_unsafe_interrupts=1
        ``` 
        or add following to /etc/modprobe.d/kvm.conf [From](https://access.redhat.com/articles/66747)
        ```
        options kvm allow_unsafe_assigned_interrupts=1
        ```
        or If you wish to continue using PCI passthrough without interrupt remapping for KVM guests, the previous, vulnerable behavior can be restored by running the following command as root
        ```
        echo 1 > /sys/module/kvm/parameters/allow_unsafe_assigned_interrupts
        ```
    
    - Ignore guest access to unhandled MSRs.
    
        ```
        kvm.ignore_msrs=1
        ```

    
    - Isolate GPU modules and PCIe devices for passthrough
        
        <ol>
            <li>Check GPU info</li>
            
        <ul>
            <li>Check the GPU driver</li>
       
        ```
        # lspci -v | awk -F': ' '/NVIDIA/,/Kernel modules/ { if ( $0 ~ /Kernel modules/ ) { gsub(",","");printf("%-s ", $NF) }} END { print }'
        nvidiafb nouveau snd_hda_intel
        ```
        <li>Check the GPU vender_id and device_id</li>
        
        ```
        # lspci -nn | sed -n 's|^.*NVIDIA.*\[\([[:alnum:]]\{4\}\)\:\([[:alnum:]]\{4\}\)\].*$|\1:\2|p'
        10de:1c03
        10de:10f1
        ```
        </ul>
        
        
        <li>Methods to Isolate GPU</li>
        <ul>
        <li>Blacklisting the aboving drives/modules</li>

        This setting tells the kernel prevent to use those hardwares which need to load drivers during loading process 
 
        ``` 
        # echo "install nvidiafb /bin/true" >> /etc/modprobe.d/local-blacklist.conf
        # echo "install nouveau /bin/true" >> /etc/modprobe.d/local-blacklist.conf
        # echo "install snd_hda_intel /bin/true" >> /etc/modprobe.d/local-blacklist.conf
        ```
        **Warning:**  (Re)move /etc/modprobe.conf, if present, as it supersedes anything in /etc/modprobe.d/* unless you add include /etc/modprobe.d [From](https://wiki.debian.org/KernelModuleBlacklisting)

        <li>Using kernel command line</li>
        
        ```
        modprobe.blacklist=nvidiafb,nouveau,snd_hda_intel
        ```

        <li>Use vfio driver to pre-handle GPU devices during kernel loading <a href="https://mathiashueber.com/windows-virtual-machine-gpu-passthrough-ubuntu/">From</a></li>
        <ol>
        <li>
        Include vfio* drivers in initramfs, they will be loaded at boot time in the order below</li>

        ```
        # echo "vfio vfio_iommu_type1 vfio_virqfd vfio_pci ids=10de:1c03,10de:10f1" >> /etc/initramfs-tools/modules
        ```
        <li>The vfio* drvivers should be loaded at boot time</li>
        
        ```
        # echo "vfio vfio_iommu_type1 vfio_pci ids=10de:1c03,10de:10f1" >> /etc/modules
        ```

        <li>Set higher loading priority than GPU drivers</li>
        
        ```
        # echo "softdep nouveau pre: vfio-pci" >> /etc/modprobe.d/nvidia.conf
        # echo "softdep nvidiafb pre: vfio-pci" >> /etc/modprobe.d/nvidia.conf
        # echo "softdep snd_hda_intel pre: vfio-pci" >> /etc/modprobe.d/nvidia.conf
        ```

        <li>Update vfio module changes</li>

        ```
        # echo "options vfio-pci ids=10de:1c03,10de:10f1" >> /etc/modprobe.d/vfio.conf
        # update-initramfs -u -k all
        # reboot
        ```
        **Note:** This method is much more complex but more safely 

        </ol>
        </ul>
        <li>Enabling huge pages</li>
        Setup 32G hugepages, 16G for guest using and the rest for other purpose

        ```
        default_hugepagesz=1G hugepagesz=1G hugepages=32
        ```
        </ol>

- Grub settings

    ```
    # vim /etc/default/grub
    GRUB_CMDLINE_LINUX="selinux=0 console=ttyS0,115200 iommu=pt intel_iommu=on kvm.ignore_msrs=1 pcie_acs_override=downstream,multifunction vfio_iommu_type1.allow_unsafe_interrupts=1 modprobe.blacklist=nvidiafb,nouveau,snd_hda_intel default_hugepagesz=1G hugepagesz=1G hugepages=32"
    # update-grub && reboot
    ```

<h2 name="drv_conf">Driver and PCIe device configuration</h2>

1. GPU iommu groub check
     

    ```
    # iommu_group() { for i in /sys/kernel/iommu_groups/*/devices/*;do printf "%-12s %-4s" "IOMMU_GROUP" "`echo $i | sed 's|^.*iommu_groups/\([0-9]*\)/dev.*$|\1 |'`"; lspci -nns ${i##*/} ;done }
    # iommu_group | grep -i nvidia
    IOMMU_GROUP  71  65:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP106 [GeForce GTX 1060 6GB] [10de:1c03] (rev a1)
    IOMMU_GROUP  71  65:00.1 Audio device [0403]: NVIDIA Corporation GP106 High Definition Audio Controller [10de:10f1] (rev a1)
    ```
2. Install modules
    ```
    # modprobe vfio
    # modprobe vfio_pci
    # modprobe msr
    # modprobe kvm
    # modprobe kvm_intel
    ```
3. Bind devices
    ```
    # echo 10de 1c03 > /sys/bus/pci/drivers/vfio-pci/new_id
    # echo 10de 10f1 > /sys/bus/pci/drivers/vfio-pci/new_id
    # # ls /dev/vfio/
    71  vfio
    ```

<h2 name="perf">Performance tuning</h2>

1. Increase the memory lock limit on the host (maxsize memory set to 32G)   
    ```
    # ulimit -l 33554432
    # ulimit -l
    33554432
    ```
2. Confirm HugePages
    ```
    # grep -i huge /proc/meminfo
    AnonHugePages:         0 kB
    ShmemHugePages:        0 kB
    FileHugePages:         0 kB
    HugePages_Total:      32
    HugePages_Free:       32
    HugePages_Rsvd:        0
    HugePages_Surp:        0
    Hugepagesize:    1048576 kB
    Hugetlb:        33554432 kB
    # free -h
                   total        used        free      shared  buff/cache   available
    Mem:            62Gi        35Gi        26Gi        10Mi       572Mi        26Gi
    Swap:          8.0Gi          0B       8.0Gi
    ```
3. Mount if there is no hugepage on the mount point
    ```
    # mount -t hugetlbfs hugetlbfs /dev/hugepages
    # mount | grep -i huge
    hugetlbfs on /dev/hugepages type hugetlbfs (rw,relatime,pagesize=1024M)
    ```
    **optional: release the hugepage**
    ```
    # sysctl vm.nr_hugepages=0
    # umount /dev/hugepages
    ```
4. Enable OVMF for UEFI support on QEMU

    OVMF is a port of Intel's tianocore firmware to the qemu virtual machine. This allows easy debugging and experimentation with UEFI firmware; either for testing Ubuntu or using the (included) EFI shell. [From](https://wiki.ubuntu.com/UEFI/OVMF)

    ```
    # apt install ovmf 
    ```

<h2 name="qemu_setup">Qemu-kvm setup</h2>
    
1. Install qemu 
    ```
    # apt-get install virt-manager libvirt-daemon -y 
    ```
2. qemu cmd
    ```
    # taskset -c 14-17,32-35 qemu-system-x86_64 \
    -enable-kvm \ 
    -machine type=q35, accel=kvm \
    -nic none \
    -vga none \
    -serial none \
    -parallel none \
    -nographic \
    -cpu host,kvm=off \
    -rtc base=localtime,clock=host \
    -daemonize \
    -m 16G,slots=2 -mem-prealloc \
    -object memory-backend-file,size=16G,share=on,mem-path=/dev/hugepages,share=on,id=node0 \
    -numa node,nodeid=0,memdev=node0 \
    -smp cpus=8,cores=8,sockets=1 \
    -device pcie-root-port,chassis=0,id=pci.0,multifunction=on \
    -device vfio-pci,host=65:00.0,bus=pci.0 \
    -device pcie-root-port,chassis=1,id=pci.1,multifunction=on \
    -device vfio-pci,host=65:00.1,bus=pci.1 \
    -device pcie-root-port,chassis=2,id=pci.2,multifunction=on \
    -device vfio-pci,host=b3:00.0,bus=pci.2 \
    -drive id=disk0,if=virtio,cache=none,format=raw,file=/data/img/win10-disk0.img \
    -drive file=/data/iso/Windows10-Jun19-2022.iso,index=1,media=cdrom \
    -boot dc \
    -bios /usr/share/ovmf/OVMF.fd

    ```

<h2 name="bestprac">Best Practices</h2>

1. Install software
    ```
    # apt-get install qemu-system-x86 virt-manager libvirt-daemon ovmf -y
    # qemu-system-x86_64 --version
    QEMU emulator version 6.2.0 (Debian 1:6.2+dfsg-2ubuntu6.3)
    Copyright (c) 2003-2021 Fabrice Bellard and the QEMU Project developers
    ```
2. Update /etc/default/grub 
    * disable selinux
    * enable console serial output
    * enable virtualization
    * enable iommu
    * bypass unhandle msr
    * enable acs group
    * enable IOMMU Interrupt Remapping
    * blakclist nvidiafb,nouveau,snd_hda_intel during kernel booting
    * set default hugepages size by 1G
    * set 32G hugepage pool
    ```
    GRUB_CMDLINE_LINUX="selinux=0 console=ttyS0,115200 iommu=pt intel_iommu=on kvm.ignore_msrs=1 pcie_acs_override=downstream,multifunction vfio_iommu_type1.allow_unsafe_interrupts=1 modprobe.blacklist=nvidiafb,nouveau,snd_hda_intel default_hugepagesz=1G hugepagesz=1G hugepages=32"
    ```
3. Update grub config and make the config works during the next boot
    ```
    # update-grub
    # reboot
    ```
3. Define iommu group function
    ```
    # iommu_group() { for i in /sys/kernel/iommu_groups/*/devices/*;do printf "%-12s %-4s" "IOMMU_GROUP" "`echo $i | sed 's|^.*iommu_groups/\([0-9]*\)/dev.*$|\1 |'`"; lspci -nns ${i##*/} ;done }
    ```
4. Check out GPU iommu group
    ```
    # iommu_group | grep NVIDIA
    IOMMU_GROUP  71  65:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP106 [GeForce GTX 1060 6GB] [10de:1c03] (rev a1)
    IOMMU_GROUP  71  65:00.1 Audio device [0403]: NVIDIA Corporation GP106 High Definition  Audio Controller [10de:10f1] (rev a1)
    ```
5. Check out additional USB3.0 controller installed from PCIe extend card
    ```
    # iommu_group | grep VIA
    IOMMU_GROUP  90  b4:00.0 USB controller [0c03]: VIA Technologies, Inc. VL805/806 xHCI USB  3.0 Controller [1106:3483] (rev 01)
    ```
6. Check out NVMe controller
    ```
    # iommu_group | grep 6100p
    IOMMU_GROUP  89  b3:00.0 Non-Volatile memory controller [0108]: Intel Corporation SSD Pro 7600p/760p/E 6100p Series [8086:f1a6] (rev 03)
    ```
7. Detach additinal USB3.0 controller and NVMe SSD controller from OS
    ```
    echo 0000:b4:00.0 > /sys/bus/pci/devices/0000:b4:00.0/driver/unbind
    echo 0000:b3:00.0 > /sys/bus/pci/devices/0000:b3:00.0/driver/unbind
    ```
8. Install modules
    ```
    # modprobe vfio
    # modprobe vfio_pci
    # modprobe msr
    # modprobe kvm
    # modprobe kvm_intel
    ```
9. Check vfio group
    ```
    # ls /dev/vfio
    vfio
    ```
10. Attach devices to vfio group
    ```
    # echo 10de 1c03 > /sys/bus/pci/drivers/vfio-pci/new_id
    # echo 10de 10f1 > /sys/bus/pci/drivers/vfio-pci/new_id
    # echo 1106 3483 > /sys/bus/pci/drivers/vfio-pci/new_id
    # echo 8086 f1a6 > /sys/bus/pci/drivers/vfio-pci/new_id
    ```
11. Check vfio group again
    ```
    # ls /dev/vfio
    71  89  90  vfio
    ```
12. Increase the memory lock limit
    ```
    # ulimit -l 33554432
    # ulimit -l
    33554432
    ```
13. Unlimit the max number of user processes
    ```
    # ulimit -u unlimited
    # ulimit -u
    unlimited
    ```
14. Create VM image
    ```
    # mkdir /data
    # qemu-img create -f raw -o preallocation=full /data/img/win10-disk0.img 60G
    Formatting '/data/img/win10-disk0.img', fmt=raw size=64424509440 preallocation=full
    ```
15. Download virtio-win drive
    
    To enable the virtio drive support for window
    ```
    # wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.221-1/virtio-win.iso
    # ls -l /data/drv/virtio-win.iso
    -rw-r--r-- 1 root root 531486720 Jul 24 11:28 /data/drv/virtio-win.iso
    ```

16. Start OS installation
    ```
    cmd=(
        taskset -c 14-17,32-35
        qemu-system-x86_64
        -enable-kvm
        -machine type=q35,accel=kvm
        -nic none
        -vga none
        -serial none
        -parallel none
        -cpu Cascadelake-Server,kvm=off
        -rtc base=localtime,clock=host
        -daemonize
        -k en-us
        -smp cpus=16,sockets=1,cores=8,threads=2
        -m 16G,maxmem=256G,slots=2 -mem-prealloc -overcommit mem-lock=on

        -object memory-backend-file,id=mem,size=16G,mem-path=/dev/hugepages,prealloc=on,share=on
        -numa node,nodeid=0,memdev=mem

        -device pcie-root-port,chassis=0,id=pci.0,multifunction=on
        -device vfio-pci,host=65:00.0,bus=pci.0

        -device pcie-root-port,chassis=1,id=pci.1,multifunction=on
        -device vfio-pci,host=65:00.1,bus=pci.1

        -device pcie-root-port,chassis=3,id=pci.3,multifunction=on
        -device vfio-pci,host=b4:00.0,bus=pci.3

        -drive file=/data/img/win10-disk0.img,if=virtio,format=raw,cache=none,index=3,media=disk

        -drive file=/data/drv/virtio-win.iso,index=2,media=cdrom
        -drive file=/data/iso/Windows10-Jun19-2022.iso,index=1,media=cdrom
        -boot dc
        -bios /usr/share/ovmf/OVMF.fd
    )


    ${cmd[@]}
    ```
16. Switch the monitor to the passthroughed GPU card
17. Connect the keyboard and mouse to the PCIe extend card which has USB support 
18. Install virtio driver during windows installation progress
    
    ```
    Steps:
    1. Where do you want to install Windows? 
    2. Load driver
    3. Select the driver to install 
        RedHat VirtIO SCSI controller(E:\amd64\win10\viostor.inf)
    4. Next
    ```
19. Check hugepage usage on the host 

    There is 32G hugepage totally, 16G is using for the vm and another 16G is free for others
    ```
    # grep -i huge /proc/meminfo
    AnonHugePages:      2048 kB
    ShmemHugePages:        0 kB
    FileHugePages:         0 kB
    HugePages_Total:      32
    HugePages_Free:       16
    HugePages_Rsvd:        0
    HugePages_Surp:        0
    Hugepagesize:    1048576 kB
    Hugetlb:        33554432 kB
    
    # free -h
                   total        used        free      shared  buff/cache   available
    Mem:            62Gi        36Gi        20Gi        10Mi       5.3Gi        25Gi
    Swap:          8.0Gi          0B       8.0Gi
    ```

<h2 name="refer">References</h2>
<ol>
<li>
<a href="https://www.heiko-sieger.info/running-windows-10-on-linux-using-kvm-with-vga-passthrough">https://www.heiko-sieger.info/running-windows-10-on-linux-using-kvm-with-vga-passthrough</a>
</li>
<li>
<a href="https://www.gnu.org/software/grep/manual/html_node/Character-Classes-and-Bracket-Expressions.html">https://www.gnu.org/software/grep/manual/html_node/Character-Classes-and-Bracket-Expressions.html</a>
</li>
<li>
<a href="https://wiki.archlinux.org/title/Kernel_module">https://wiki.archlinux.org/title/Kernel_module</a>
</li>
<li>
<a href="https://unix.stackexchange.com/questions/276392/how-to-block-drivers-built-into-kernel-i-e-drivers-who-are-not-a-module">https://unix.stackexchange.com/questions/276392/how-to-block-drivers-built-into-kernel-i-e-drivers-who-are-not-a-module</a>
</li>
<li>
<a href="https://www.kernel.org/doc/html/v4.10/admin-guide/kernel-parameters.html">https://www.kernel.org/doc/html/v4.10/admin-guide/kernel-parameters.html</a>
</li>

<li>
<a href="https://www.golinuxcloud.com/disable-blacklist-kernel-module-centos-7-8/">https://www.golinuxcloud.com/disable-blacklist-kernel-module-centos-7-8/</a>
</li>

<li>
<a href="https://documentation.suse.com/sles/12-SP4/html/SLES-all/cha-mod.html">https://documentation.suse.com/sles/12-SP4/html/SLES-all/cha-mod.html</a>
</li>
<li>
<a href="https://pve.proxmox.com/wiki/Pci_passthrough">https://pve.proxmox.com/wiki/Pci_passthrough</a>
</li>
<li>
<a href="https://www.kernel.org/doc/html/latest/admin-guide/mm/hugetlbpage.html#">https://www.kernel.org/doc/html/latest/admin-guide/mm/hugetlbpage.html#</a>
</li>
<li>
<a href="https://events.linuxfoundation.org/wp-content/uploads/2022/03/Huge-Page-Concepts.pdf">https://events.linuxfoundation.org/wp-content/uploads/2022/03/Huge-Page-Concepts.pdf</a>
</li>
<li>
<a href="https://www.qemu.org/docs/master/system/qemu-block-drivers.html">https://www.qemu.org/docs/master/system/qemu-block-drivers.html</a>
</li>
<li>
<a href="https://www.qemu.org/docs/master/system/images.html#nvme-disk-images">https://www.qemu.org/docs/master/system/images.html#nvme-disk-images</a>
</li>
<li>
<a href="https://blogs.oracle.com/linux/post/how-to-emulate-block-devices-with-qemu">https://blogs.oracle.com/linux/post/how-to-emulate-block-devices-with-qemu</a>
</li>
<li>
<a href="https://events19.lfasiallc.com/wp-content/uploads/2017/11/Storage-Performance-Tuning-for-FAST-Virtual-Machines_Fam-Zheng.pdf">https://events19.lfasiallc.com/wp-content/uploads/2017/11/Storage-Performance-Tuning-for-FAST-Virtual-Machines_Fam-Zheng.pdf</a>
</li>
<li>
<a href="https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md">https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md</a>
</li>
<li>
<a href="https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/">https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/</a>
</li>
<li>
<a href="https://qemu-project.gitlab.io/qemu/system/qemu-cpu-models.html">https://qemu-project.gitlab.io/qemu/system/qemu-cpu-models.html</a>
</li>
<li>
<a href="https://events19.linuxfoundation.org/wp-content/uploads/2017/12/Kashyap-Chamarthy_Effective-Virtual-CPU-Configuration-OSS-EU2018.pdf">https://events19.linuxfoundation.org/wp-content/uploads/2017/12/Kashyap-Chamarthy_Effective-Virtual-CPU-Configuration-OSS-EU2018.pdf</a>
</li>
</ol>


