

## Goal of the article
- I want to get into build and selling QubesOS laptop as secure devices
- This would include the building of the Nyx laptop
- To build up the secure feature, I like to create a series of articles that look at different aspects of QubesOS and my it put using a laptop ...
## QubesOS A Hypervisor as a Desktop

### Intro
- Running a desktop in a hypervisor is not new and you have been able to do it for a long time
- In the comsumer/home lab area,  VMwaare Workstation and VirtualBox are popular ways to play with Hypervisors on a laptop.
- The run inside of an existing OS like Windows. Linux or Mac and allow you to play with other OS without giving up your primary system
- There are a class of Hypervisor like VMware ESXi, Zen, KVM and others that run as the OS of the device (bare metal)
- The VM here work together to form business process like webserver, database server, application servers
- Whit is a bare metal hypervision was installed on a laptop and a different set of VM so form a desktop

### QubesOS 
- QwbesOS is a Zen Hypervisor installed on bare metal that creates groups of VM working together to create a desktop enviroment
- On the surface level this seem like a waste of resources and  would make a weird zone of application the feels awkware to use, but it not
- As a traditional hypervision allow you to create VM to create business process, QubesOS allow you take you daily takes and break them into Qubes Apss based on security

### Qubes Apps
Qubes Apps are the grouping of different appication in a VM to create different level of security

## Classes of Hypervisors
- A  
