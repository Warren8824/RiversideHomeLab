# 📁 documentation/environment-setup.md
## 🧾 Purpose
This document outlines the setup of the virtual lab environment hosted on Hyper-V. It includes the virtual networking, switch configurations, VM details, and roles/services installed. The environment is used as a sandbox to learn IT support fundamentals and enterprise Windows infrastructure.

## 🖥️ Host Machine

Component	Spec
OS	Windows 11 Pro
CPU	Intel(R) Core(TM) i5-8350U CPU @ 1.70GHz   1.90 GHz
RAM	32GB DDR4
Storage	500GB External SSD
Virtualization Platform	Hyper-V (Native Windows)


## 🧵 Virtual Networking
Private Switches: Four private switches simulate isolated site networks.

Internal Switch: Provides controlled internet access for VMs via NAT.


|Switch Name	|Type	|Purpose|
----------|-----------|---------------------|
|MAN-SW01	|Private	|Manchester office|
|LEE-SW01	|Private	|Leeds office|
|LIV-SW01	|Private	|Liverpool office|
|HUL-SW01	|Private	|Hull office|
|NATSwitch	|Internal	|NAT for internet access|

![HyperV Config](images/VSwitches.png)

## 🧱 Virtual Machines
DC01 – Domain Controller
OS: Windows Server 2025

vCPU: 4 | RAM: 4GB | Storage: 80GB

Network: 5 adapters – one per office, plus NAT

Services:

- AD DS

- DNS

- DHCP

- RRAS (Routing/NAT)

![DC01 Creation](images/DC01Creation.png)

Optional Clients

- Windows 11 Pro, named per office eg MAN-LAP-01 / MAN-PC-01

- Domain joined to riverside.local

- Used for helpdesk practice and GPO testing

## 🧠 Learning Goals for Environment
- Build confidence with core Windows Server roles

- Understand domain structure, DNS, DHCP, routing

- Practice troubleshooting and helpdesk scenarios

- Use GPOs to apply policy across sites

- Write scripts to automate common tasks