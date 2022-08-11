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
   
<li>BIOS virtualization feature enabled: VT-x and VT-d</li>
<li>UEFI BOOT enabled</li>
<li>Motherboard integrated VGA supported and set as default graphic</li>
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




<h2 name="refer">References</h2>
<ol>
<li>
<a href="https://www.heiko-sieger.info/running-windows-10-on-linux-using-kvm-with-vga-passthrough">https://www.heiko-sieger.info/running-windows-10-on-linux-using-kvm-with-vga-passthrough</a>
</li>



</ol>
