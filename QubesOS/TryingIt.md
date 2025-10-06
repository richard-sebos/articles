- A few years a good, an IT professional I trusted, said Linux is not secure.
- His claim was not, it was more or less secure than other systems just that the default Linux system had issues like all OS
- No not sure how many times I teases Windows uses about they security and now someone I trusted did to me.
- The myth was shattered in my mind
- That started me down the path of `what can I do to better secure my systems`
- Years later, I am typing the article on QubesOS

## Qubes OS
- QubesOS marketing is `A reasonably secure operating system`, which does come off a vag but is some how ackurit.
- I've seen different article and video claiming it is the most secure Linux Distro, which is a big claim since there are some very harden and Ephemeral Linux distro.
- At a high level, QubosOS security is based on:
  - Qubes OS relies on modern CPUs that support hardware virtualization (Intel VT-x/VT-d or AMD-V/AMD-Vi) to enforce strong isolation between virtual machines.
  - dom0 (Domain 0): When you log in, you’re in dom0. This is the minimal, highly restricted domain that runs the desktop environment and the Qubes Manager. It does not have network access.
  - Qubes (VMs): All applications and services run inside separate, predefined qubes (virtual machines). Each qube is isolated, so if one is compromised, the others remain protected.
  - Networking: Not all qubes have internet access—networking is routed through special “service qubes” (like sys-net and sys-firewall) to control and limit exposure.
- this philosophy for security provides a sense of security and a bit of head scratching when you it.
- In a very positive way, I would say `QubesOS give you the place do something dumb when needed`, which is a good thing.

## When a Qube doesn't Feel like a VM
- When I first starting looking into `QubesOS` my though it was just another Hypervisor.
- Everything is a VM and why not just use Proxmox, Qemu or other homelab VM application?
- What is the `magic sause` that makes `QubesOS` different beside the specific hardware?
- When you run an app in a `Qube` you don't feel like you are in a VM and if give it a true desktop experances which is nice
- So why do you need `Qubes`

## Why have Qubes
- I like yto think of Qubes as zones on a firewall, but where firewall zone can filter traffic `Qubes` give you an isolated space to run apps
- They allow you to create a custom enviroments to running applications in, including what apps and custom firewall rules if needed.
- `Work Qube`, which I am using now, I use for writing and publishing related task.
- `Personal Qube`, I have setup my email Thunderbird.
- `Untrusted Qube`, I opened a shell, installed `ClamAV` and scanned a thumb drive.
- Each one feels like you are running an application and not VM, beside a minor delay when starting but I am running it on older hardware.
- Copying files between two `Untrusted` file manager works, which should sound surprising but again, they are running outside the VM host windows.
- Alt-Tab between windows in that are really in different `Qubes` works.

## So What's The Bad
- I've only been using `QubesOS` for 2 days so far but the bad far isn't that bad.
- The first step back was when I boot up the fresh install plugged in a mouse and was greeted with a message asking to allow it access to `Dom0`, flash back to Windows Vista
- There is a `sys-usb` which is a `Qube` where the  mouse dungle gets mounted, isolation in actions
- It is a bit of a pain but now when you pop in a thumb drive, it is treated the same what which is good
> Note: I really should have install Clam globally and added to the `sys-usb` and scanned the drive before adding it to untrusted.
- Copy and Paste between `Qubes` is allowed but you need to create rules for it, which is expected
- Opening Firefox or other application can be slow if the `Qube` they running in isn't started, which again is expected but if you start the `Qube` first, it faster.
- Since `Qubes` are isolated, Firefox in each `Qube` will have its own set of favourites, which could be a pain but again I like for the security

## Who is this for:
- `QubesOS` is target it journalist, activist and cybersecurity professional.
- Installs with encrypted harddrive
- Since `Qubes` can be cloned, created, backup, restore and deleted this makes sense.
- It makes it easy to clone a `Qube` do what you need, send it off throught the web and destroy the `Qube`
- It was easy to added a OpenVPN config file and once started, all the `Qube` had VPN access
- There was a list of VPN providers, I used OpenVPN because my provider was not there

## Overall
- I thought `QubesOS` security would be the wow factor, which is there but how the `Qube` applications windows file like you using the desktop was nice.
- Not be able Copy and Paste between `Qubes` will take time to get use to but that is small compared to the isolation security of`Qubes`
- `QubesOS` addes enough friction when doing things that you stop and ask youself, what is the security and what I want to add.
- So it is `A reasonably secure operating system`



