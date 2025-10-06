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
- 
