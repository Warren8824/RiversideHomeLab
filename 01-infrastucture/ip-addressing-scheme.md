##  IP Addressing Scheme

###  Purpose  
This document details the internal IP addressing scheme used across the virtual lab network. Each site (Manchester, Leeds, Liverpool, Hull) is logically segmented into its own subnet to simulate real-world office branch networking. The goal is to mirror common enterprise setups for Active Directory, DHCP, and inter-site routing practices.

---

###  Subnet Overview

| Site         | Network        | Subnet Mask   | IP Range              | Purpose        |
|--------------|----------------|---------------|------------------------|----------------|
| Manchester   | 10.90.10.0     | 255.255.255.0 | 10.90.10.1 – .254      | Head Office    |
| Leeds        | 10.90.20.0     | 255.255.255.0 | 10.90.20.1 – .254      | Branch Office  |
| Liverpool    | 10.90.30.0     | 255.255.255.0 | 10.90.30.1 – .254      | Branch Office  |
| Hull         | 10.90.40.0     | 255.255.255.0 | 10.90.40.1 – .254      | Branch Office  |
| NAT Network  | 192.168.100.0  | 255.255.255.0 | 192.168.100.1 – .254   | Internet NAT   |

---

###  Addressing Conventions

- **.1** reserved for DC01’s interface on that subnet (acting as default gateway + DHCP relay)
- **.2 – .19** reserved for infrastructure (future additions like file servers, printers, etc.)
- **.20 – .250** reserved for dynamic DHCP lease pool
- **.251 – .254** reserved for static/manual assignments if needed (e.g., firewall, test servers)

---

###  Routing Design

- All subnets are routed via DC01
- RRAS service enabled on DC01 for inter-site routing and internet NAT
- NAT is handled via internal adapter connected to `192.168.100.2/24` (NATSwitch)

![NAT](images/NAT.png)\
*Routing and Remote Access - DC01*

---

###  DHCP Configuration (via DC01)

| Subnet       | Scope Range             | Default Gateway | DNS Server     | Domain Name       |
|--------------|--------------------------|------------------|----------------|--------------------|
| Manchester   | 10.90.10.20 – .250       | 10.90.10.1       | 10.90.10.1     | riverside.local    |
| Leeds        | 10.90.20.20 – .250       | 10.90.20.1       | 10.90.10.1     | riverside.local    |
| Liverpool    | 10.90.30.20 – .250       | 10.90.30.1       | 10.90.10.1     | riverside.local    |
| Hull         | 10.90.40.20 – .250       | 10.90.40.1       | 10.90.10.1     | riverside.local    |

![DHCP](images/DHCP.png)\
*DHCP Scopes - DC01*

---
### DNS Configuration on DC01 - 10.90.10.1

The lab environment utilizes a single DNS server running on the multi-homed Domain Controller. Primary DNS services are provided through the Manchester Head Office NIC (10.90.10.1), which all DHCP scopes across subnets will reference. The DC's primary network interface is configured with loopback address 127.0.0.1 for DNS resolution, with external queries forwarded to Google DNS (8.8.8.8) and Cloudflare DNS (1.1.1.1).

#### DNS Server Configuration Table

| Configuration Item | Value | Notes |
|-------------------|-------|-------|
| Primary DNS Interface | 10.90.10.1 (Manchester) | All client DNS requests directed here |
| Domain Name | riverside.local | Primary AD domain |
| DNS Server Service Binding | All interfaces | DNS service responds on all internal NICs |
| Loopback Configuration | 127.0.0.1 | Used on primary NIC |
| DNS Forwarders | 8.8.8.8, 1.1.1.1 | Google DNS, Cloudflare DNS |
| Conditional Forwarders | None configured | Can be added if external domain resolution is needed |

#### DNS Zones Table

| Zone Type | Zone Name | Subnet | Notes               |
|-----------|-----------|--------|---------------------|
| Forward Lookup | riverside.local | All | Primary domain zone |
| Reverse Lookup | 10.90.10.in-addr.arpa | 10.90.10.0/24 | Manchester subnet   |
| Reverse Lookup | 10.90.20.in-addr.arpa | 10.90.20.0/24 | Leeds subnet        |
| Reverse Lookup | 10.90.30.in-addr.arpa | 10.90.30.0/24 | Liverpool subnet    |
| Reverse Lookup | 10.90.40.in-addr.arpa | 10.90.40.0/24 | Hull subnet         |

![DNS Zones](images/DNS.png)\
*Reverse Look-up Zones - DC01*

--- 

#### DNS Registration and Scavenging

| Setting | Value | Notes |
|---------|-------|-------|
| Dynamic Updates | Secure only | AD-integrated secure updates |
| Scavenging Period | Default (7 days) | Recommended baseline setting |
| Aging/Refresh Interval | Default (7 days) | Recommended baseline setting |
| NIC Registration | All internal NICs | 10.90.10.1, 10.90.20.1, 10.90.30.1, 10.90.40.1 |

###  Lessons Learned

- Simulating multi-site routing on a single host was harder than expected but rewarding
- Needed to manually configure static IPs on server NICs to match role and subnet layout
- DHCP relay wasn't needed since DC01 has an interface in each subnet

---

###  Client Configuration

![Client with DHCP Lease](images/ipconfigMAN-LAP-01.png)\
*This is the configuration handed to a client on the Manchester site subnet (10.90.10.x/24).*
