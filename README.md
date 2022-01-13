


> Written with [StackEdit](https://stackedit.io/).

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
