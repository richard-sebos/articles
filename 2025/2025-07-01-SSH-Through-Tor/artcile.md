# SSH over Tor - Cool, Practicle or Just Tinhat

- When I first saw this topic idea my first thougts where 
  - Sounds cool
  - Sounds complicated
- The idea of route SSH traffic through the dark web would put me one step closer to being a hacker right?

## Tor
- Tor for some, is that Dark Web took used but criminal, spy and bad actores to hide their traffic from ISP and goverment agency.
- Tor or The Onion Router, is a software system router that routes encrypted network traffice through multiple relay to hide the orginal source and destination of traffic 
- The simples way to look at it, Tor routes to network request to a different random part of the world hiding were the traffic is comong from.

## Why Tor and SSH
- With Tor, you can creata a local proxy server and route your SSH traffic you through Tor
- In my case, I create a Oracle Linux server in US using Google Cloud
- From my home in Canada, the Tor proxy routed my traffic SSH through multiple relay and ended up in France
- From France, my SSH traffic traveled back to North Americal and connented to the Linux server in the US
- So what did this extra protection give me
> A local proxy server, in our case, was taking SSH traffic and sending it out through Tor

## So Why do this
- This is where the cool, practicle or just tinfoilhat comes in
- Without Tor my, my traffic and any point could be review to see the network metadata which not encrypted
  - Where it is coming from and going to 
  - what port is being used
  - it is the SSH protocol
  - as well as other things
- Google Clound would also be able to see that information
- with Tor, it is not until it leave the Tor relays does it look like SSH traffic.
- So in my case, between my laptop and the relay in France, the SSH traffic was wrappered in Tor packets
- From France to US, it looks like SSH traffic but the source looks like France and not Canada

## How to setup
- From my Mac laptop, it was easy to install by installing `Tor` and `connect` a local proxy server wrapper

```bash
## Install Tor
brew install tor torsocks

## install connect
## a proxy-aware connector 
## used to wrap non-proxy-aware programs (like SSH) to work over SOCKS or HTTPS proxies
brew install connect
```

- Starting a local Tor proxy server
```bash
## Start the Tor proxy server
brew services start tor
```

- Edited my .ssh/config file to use the `connect` to send ssh traffic to the Tor proxy server
```bash
#added to .ssh/config
Host rhel_jump
    HostName 34.135.249.184
    User richard
    Port 22
    IdentityFile ~/.ssh/includes.d/rhel_jump/rhel_jump
    ProxyCommand connect -S 127.0.0.1:9050 -4 %h %p
```
- the using `torsocks ssh rhel_jump` command I can connect to the remote Google Cloud server
- to make it simpler, I created an alais so all I need to type is `tssh rhel_jump"

```bash
## Added alias in .zshrc
alias tssh='torsocks ssh'
```

> Once this is setup you can use the Tor proxy server to route your browser traffic also

## Conclusion
- So is this the magical tool of hackers, not really
- It does add a layer of protection.
- Would I use these everyday? For `SSH`, no but it would be a good tool to use in pentesting you system since it hide where the traffic is comeing from
- So cool, practical or tinfoil hat
  - It was fun to build and test so cool
  - It has uses in pentesting and network testing so practical
  - If you are using it for everything then tinhat

