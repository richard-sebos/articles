# Suricata report

- Earlir in the series, we install Suricata as part of the initial robot build
- We added a few basic rules and lelt it there
- Now that most of the base application as installed it is time to monitor what the network traffic is doing.
- But why on the robot?

## Robts and Suricata
- A robot can have a multiple network connect
- RJ45 ethernet connection login in to terminal
- WiFi access for remote ROS2 command and mobile web access 
- It can create an Access Point ROS2 commands and remote monitoring 
- Cellurer access when not in WiFi range
- with all these type of access, it is important to keep track of who is accessing the robot and using what application port

## What is Suricata
- Suricata is a application that does deep packet inspection of network traffic and apply rule on how the log or capture the traffic
- How is this different from firewall
  - firewall, at the basic level are gatekeeps bases on IPs, ports, protocols, and simple rules
  - by default, Suricate is in Intrusion Detection System, report on network traffic but it can be configure to do Intrusion Prevention System
- For now, we will look at Intrusion Detection

## Suricata Rules
- One feature of Suricata is to define rules that trigger alerts
- these alerts can be based on <something>
- when network traffic triggers one of the rules, a enter is put into the log
```bash
## Rule example

# SROS 2 
alert udp any 49152:65535 -> any any (msg:"[ROS2-02] OutgoingDDS Data Traffic Detected"; sid:100002; rev:1;classtype:not-suspicious;)
alert udp any any -> any 7400:7500 (msg:"[ROS2-03] Incoming DDS Discovery Traffic to ROS2 Node"; sid:100001; rev:2;classtype:not-suspicious;)
alert udp any 7400:7500 -> any any (msg:"[ROS2-04] Outgoing DDS Discovery Packet from ROS2 Node"; sid:100003; rev:1;classtype:notsuspicious;)

```
- the Suricata can start send lots of data to the log.
- so how to keep track of it

## Python Distiller

- create a Python script to distill the log entries into a more mana
- this summarizes the log entries between the robot and other devices by IP address and gives a count for the numvber of records.
```csv
Application,Classification,Source IP,Destination IP,Count
[ROS2-02] OutgoingDDS Data Traffic Detected,Not Suspicious Traffic,192.168.178.11,8.8.8.8,127
[ROS2-02] OutgoingDDS Data Traffic Detected,Not Suspicious Traffic,192.168.178.11,185.125.190.58,21
[SSH-10] Incoming SSH Connection Attempt,Attempted Administrator Privilege Gain,192.168.178.1,192.168.178.11,2
[ROS2-03] Incoming DDS Discovery Traffic to ROS2 Node,Not Suspicious Traffic,192.168.178.10,192.168.178.11,2
[ROS2-03] Incoming DDS Discovery Traffic to ROS2 Node,Not Suspicious Traffic,192.168.178.11,192.168.178.10,2
[DNS] 007-30 High Volume DNS Requests From Robot,Attempted Information Leak,192.168.178.11,8.8.8.8,1
[ROS2-03] Incoming DDS Discovery Traffic to ROS2 Node,Not Suspicious Traffic,192.168.178.10,239.255.0.1,1
[ROS2-03] Incoming DDS Discovery Traffic to ROS2 Node,Not Suspicious Traffic,192.168.178.11,239.255.0.1,1
```
- find Python code [here]()
- the summarizer show some interesting outgoing to traffic I will need to follow up with 
```
[ROS2-03] Incoming DDS Discovery Traffic 192.168.178.10,239.255.0.1,1
[ROS2-03] Incoming DDS Discovery Traffic 192.168.178.11,239.255.0.1,1
[ROS2-02] OutgoingDDS Data Traffic 192.168.178.11,185.125.190.58,21

```

- the above summary was to show an example of the traffic Suricata could catch
- for better monitoring and data collect a tool like ELK Stack or Graylog

- It may see overkill to use Surucata to monitor the network traffic of a robot but from at least  developement part of the project, it would be good to see where the network traffic is coming and going to
- robotic project are a collection of hardware and software drives and it would be add to verify where they are calling out to or receiving external data from.

