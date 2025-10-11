

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
- With social media, software as a service (SAAS) and other web interactions, the internet is now a critical technology
- The risk is become greater that one miss step can cause sensity information to be expose, stolen or ranson
- Qubes Apps are the grouping of different appication in a VM to create different level of security.
- the Qube App levels are `untrusted`, `personal`, `work` and `vault`

#### Vaults Qubes
`Vaults` are examples qubes with not network access and their own storage space
- like a qubes, you can clone a default provided qube and create a personal or work `vault`
- these are greate for password and shared note apps.

#### Work Qubes
- As a content creater, I need ways of isolating my write life from my research life
- There is a security that come with the isolcaton of the qube but there is also a socologoly factor.
- When I am using the `work` cube, I am more focus and am else likes to do other distractive multtask things
- It helps the laptop I am using has crappy speakers.
- I could pair my bluetooth headset or speaker but it feels like it defeats the purpose os using QubosOS for security reason.

#### Personal
- For me and my use, this is were QubesOS gets interesting
- I clone the `person` into `bills` and `social` qubes
- This allows me to keeps my banksing information saft and personal social media seperate from my work social media

#### Untrusted
- `untrusted` is were QubesOS really shines by providing an area to isolate you from the risk of the web.
- now a days, we are always one click away from opening up an unsecure actions
- The will only become worste was AI us used to create target threats.
- Unsecure provides a place to navegate this the web
- It can also be configure to opens the URL in a Disposable VM (DispVM)

### Who is the For
- As a person who works in the IT work, I help people with their computer needs so I see how people use computers.
- Do most people need something like QubesOS to keep them secure?
- Yes, would they use it right?
- I think you need a secure first mindset to want to use OS like QubesOS
- 
