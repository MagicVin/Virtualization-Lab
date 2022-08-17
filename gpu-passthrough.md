<h2>GPU passthrough</h2>

* Agenda  
    * [Test environment](#test)
    * [Platform virtualization support](#platform)
    * [Kernel passthrough support](#kernel_pthr)
    * [Driver and PCIe device configuration](#drv_conf)
    * [Performance tuning](#perf)
    * [Qemu-kvm setup](#qemu_setup)
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
    * x1 PCIe riser card
    * x4 16G 2400MHz samsung DDR4
    * x1 QQ8Q(6240) CLX CPU
    * x1 500W power supply
    * x1 USB wifi connector
    * x2 NF-A6x25 PWM PREMIUM FANs

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
        </ol>

- Grub settings

    ```
    # vim /etc/default/grub
    GRUB_CMDLINE_LINUX="selinux=0 console=ttyS0,115200 iommu=pt intel_iommu=on kvm.ignore_msrs=1 pcie_acs_override=downstream,multifunction vfio_iommu_type1.allow_unsafe_interrupts=1 modprobe.blacklist=nvidiafb,nouveau,snd_hda_intel"
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
</ol>


