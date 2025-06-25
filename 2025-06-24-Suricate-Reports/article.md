# Suricata report

- Earlir in the series, we install Suricata as part of the initial robot build
- We added a few basic rules and felt it there
- Now that most of the base application as installed it is time to monitor what the network traffic is doing.
- But why on the robot?

## What is Suricata
- Suricata is a application that does deep packet inspection of network traffic and apply rule on how the log or capture the traffic
- How is this different from firewall
  - firewall, at the basic level are gatekeeps bases on IPs, ports, protocols, and simple rules
  - by default, Suricate is in Intrusion Detection System, report on network traffic but it can be configure to do Intrusion Prevention System
- For now, we will look at Intrusion Detection

## Suricata Rules
- One feature of Suricata is to define rules that trigger alerts
- these alerts can be based on 