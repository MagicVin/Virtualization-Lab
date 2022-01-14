
# Virtualization-Lab


## Linux Virtualization
Virtualization is a concept that creates virtualized resources and maps them to physical resources.   
👀the book ***[Mastering KVM Virtualization](https://www.packtpub.com/product/mastering-kvm-virtualization-second-edition/9781838828714)***
> [I'm here:](https://github.com/MagicVin) Virtualization is a resource management technology, it's a management subject 😃.  

## Type of virtualization
### What you are virtualizing -- five different types of virtualization
1. #### Desktop virtualization
	> It is technology that lets users simulate a workstation load to access a desktop from a connected device.  [[Citrix]](https://www.citrix.com/solutions/vdi-and-daas/what-is-desktop-virtualization.html) 
	
	**The types of Desktop Virtualization**
	* Virtual desktop infrastructure (VDI)  
	* Remote desktop services (RDS)         
	* Desktop-as-a-Service (DaaS)            
	
 2. #### Server virtualization
    > It is the process of dividing a physical server into multiple unique and isolated virtual servers by means of a software application. Each virtual server can run its own operating systems independently. [[VMware](https://www.vmware.com/topics/glossary/content/server-virtualization.html)]
   
	**The types of Server virtualization**
	* Full Virtualization        
	* Para-Virtualization     
	* OS-Level Virtualization        

3. #### Application virtualization
   > It is technology that allows users to access and use an application from a separate computer than the one on which the application is installed. [[Citrix]](https://www.citrix.com/solutions/vdi-and-daas/what-is-application-virtualization.html)
4. #### Network virtualization 
   > It is the transformation of a network that was once hardware-dependent into a network that is software-based. Like all forms of IT virtualization, the basic goal of network virtualization is to introduce a layer of abstraction between physical hardware and the activities that utilize that hardware. [[RedHat](https://www.redhat.com/en/topics/virtualization/what-is-network-virtualization)]  
  
    A cloud-based concept called **Software-Defined Networking(SDN)**. This is a technology that creates virtual networks that are independent of the physical networking devices, such as switchs. On a much bigger scale, SDN is an extension of the network virtualization idea that can span across multiple sites, locations, or data centers. In terms of the concept of SDN, entire network configuration is done in software, without you neccessarily needing a specific physical netwoking configuration. The biggest advantage of network virtualization is how easy it is for you to manage complex networks that span multiple locations without having to massive, physical network reconfiguration for all the physical devices on the network data path.
5. #### Storage virtualization
   > It is the process of presenting a logical view of the physical storage resources to a host computer system, treating all storage media(hard disk, optical disk, tape, etc.) in the enterprise as a single pool of storage.[[Wikipedia]](https://en.wikipedia.org/wiki/Storage_virtualization)

    A newer concept **Software-Defined Storage(SDS)**. This is a technology that creates virtual storage devices out of pooled, physical storage device that we can centrally manage as a single storage device. This means that we're creating some of sort of abstraction layer that's going to isolate the internal functionality of storage devices from computers, applications, and other types of resources.

### How we are virtualizing -- there are different types of virtualization
1. #### Partitioning
   > This is a type of virtualization in which a CPU is divided into different parts, and each part works as an individual system. This type of virtualization solution isolates a server into partitions, each of which can run a speparate OS.

2. #### Full virtualization
   > A virtual machine is used to simulate regular hardware while not being aware of the fact that it's virtualized. We don't have to modify the guest OS(use Native OS). 
3. #### Software-based
   > Uses binary translation to virtualize the execution of sensitive instruction sets while emulating hardware using software, which increases overhead and impacts scalability.
4. #### Hardware-based
   > Removes binary translation from the equation while interfacing with a CPU's virtualization features(AMD-V, Intel-VT), which means that instruction sets are being executed directly on the host CPU. This is what KVM does(as well as other popular htpervisors, such as ESXi, Hyper-V and Xen).
5. #### Paravirtualization
   > This is a type of virtualization in which the guest OS understands the fact that it's being virtualized and needs to be modified, along with its drivers, so that it can run on top of the virtualization solution. At the same time, it doesn't need CPU virtualization extensions to able to run a virtual machine. For example, Xen can work as a paravirtualized solution.
6. #### Hybrid virtualization
   > This is a type of virtualization that uses full virtualization and paravirtualization's biggest virtues - the fact that the guest OS can be run unmodified(full), and the fact that we can insert additional paravirtualizatied drivers into the virtual machine to work with some specific aspects of virtual machine work(most often, I/O intensive memory workloads). Xen and ESXi can also work in hybrid virtualization mode.
7. #### Container-based virtualization
   > This is a type of application virtualization that uses containers. A container is an object that packages an application and all its dependencies so that the application can be scaled out and rapidly deployed without needing a virtual machine or a hypervisor. Keep in mind that there are technologies that can operate as both a hypervisor and a container host at the same time. Some examples of this type of technology include Docker and Podman(a replacement for Docker in RedHat Enterprise Linux 8).

## Using the hypervisor/virtual machine manager
### What is Hypervisor/VMM ?
> As its name suggests, the Virtual Machine Manager(VMM) or hypersior is a piece of software that is responsible for monitoring and controlling virtual machines or guest OSes. 

The hypervisor/VMM is responsible for 
* Ensuring different virtualization management tasks, such as providing virtual hardware, virtual machine lift cycle management, migrating virtual machines, allocating resources in real time, defining policies for virtual machine management, and so on.  
* Efficiently controlling pyhsical platform resources, shuch as memory translation and I/O mapping.  
* Allocating the resources requested by these guest OSes.  

The system hardware, such as the processor, memory, and so on, must be allocated to these guest OSes according to their configuration, and the VMM can take care of this task. Due to this, the VMM is a critical component in a virtualization environment.

### Two types of hypervisor
> Hypervisors are mainly categorized as either type 1 or type 2 hypervisors, based on where they reside in the systems or, in other terms, whether the underlying OS is present in the system or not. But there is no clear or standard definition of type 1 and type 2 hypervisors.  

* Type 1 Hypervisor
  > If the VMM/hypervisor runs directly on top of the hardware, its generally considered to be a type 1 hypervisor.It doesn't need any host OS. You can directly install it on a bare-metal system and make it ready to host virtual machines. Type 1 hypervisor directly interacts with the system hardware. Type 1 hypervisors are also called bare-metal, embedded, or native hypervisors.  
 
   Layer of type 1:  
      3️L  VM1 ... VMn   
      2L  Hpervisor    
      1L  Hardware   

* Type 2 Hypervisor
  > If there is an OS present, and if the VMM/hypervisor operates as a separate layer, and it resides on the top of the OS, it will be considered as a type 2 hypervisor. Type 2 hypervisor are knowns as hosted hypervisors that are dependent on the host OS for their operations. The main advantage of type 2 hypervisors is the wide range of hardware support, because the underlying host OS controls hardware access.  

   | Layer | Type 1      | Type 2     |
   | :-----| :-----------| :----------|
   |4L     | /           |VM1 &#124; VM2 | 
   |3L     | VM1 &#124; VM2 |Hypervisor  |
   |2L     | Hypervisor  |Host OS     |
   |1L     | Hardware    |Hardware    |  
## Open source virtualization projects
The following table is a list of open source virtualization projects in Linux:
| Project        | Virtualization type         | 
| :--------------| :---------------------------|
| KVM            | Full virtualization         |
| VirtualBox     | Full virtualization         |
| Xen            | Full and Paravirtualization |
| ...            | ...                         |

* Xen 
  > Xen originated at the University of Cambridge as a research project. The first public release of Xen was in 2003. On 15 Apirl 2013, the Xen project was moved to the Linux Foundation as a collaborative project.  
 
  There are four main building items for Xen:  
  * Xen hypervisor: The integral part of Xen that handles intercommunication between the physical hardware and virtual machine(s). It handles all interrupts, times, CPU and memory requests, and hardware iteraction.
  * Dom0: Xen's control domain, which controls a virtual machine's environment. The main part of it is called QEMU, a piece of software that emulates a regular computer system by doing binary translation to emulate a CPU.
  * Management utilities: Command-line utilities and GUI utilities that we use to manage the overall Xen environment.
  * Virtual machines(unprivileged domains, DomU): Guests that we're running on Xen.

* KVM
  > KVM represents the latest generation of open source virtulization. The goal of the project was to create a modern hypervisor that builds on the experience of previous generations of technologies and leverages the modern hardware available today(VT-x, AMD-V, and so on). 
  > KVM simply turns the Linux kernel into a hypervisor when you install the KVM kernel module. However, as the standard Linux kernel is the hypervisor, it benefits from the changes that were made to the standard kernel(memory support, scheduler, and so on).
  > For I/O emulations, KVM uses a userland software, QEMU, this is a userland program that does hardware emulation.
