### Virtual Network Configuration

#### Virtual Switches
| Switch Name | Type | Purpose |
|-------------|------|---------|
| MAN-SW01 | Private | Manchester site network segment |
| LEE-SW01 | Private | Leeds site network segment |
| LIV-SW01 | Private | Liverpool site network segment |
| HUL-SW01 | Private | Hull site network segment |
| NATSwitch | Internal | Provides internet connectivity for VMs |

#### IP Addressing Scheme
| Network | Subnet | Purpose | IP Range |
|---------|--------|---------|----------|
| Manchester | 10.90.10.0/24 | Head Office | 10.90.10.1 - 10.90.10.254 |
| Leeds | 10.90.20.0/24 | Branch Office | 10.90.20.1 - 10.90.20.254 |
| Liverpool | 10.90.30.0/24 | Branch Office | 10.90.30.1 - 10.90.30.254 |
| Hull | 10.90.40.0/24 | Branch Office | 10.90.40.1 - 10.90.40.254 |
| NAT Network | 192.168.100.0/24 | Internet Connectivity | 192.168.100.1 - 192.168.100.254 |


### Virtual Machines

#### Domain Controller
- **Name**: DC01
- **OS**: Windows Server 2019 Standard
- **vCPU**: 2
- **vRAM**: 4GB
- **Storage**: 80GB
- **Network Adapters**:
  - Adapter 1: MAN-SW01 (10.90.10.1)
  - Adapter 2: LEE-SW01 (10.90.20.1)
  - Adapter 3: LIV-SW01 (10.90.30.1)
  - Adapter 4: HUL-SW01 (10.90.40.1)
  - Adapter 5: NATSwitch (192.168.100.2)
- **Roles Installed**:
  - Active Directory Domain Services
  - DNS Server
  - DHCP Server
  - Routing and Remote Access Service

#### Client Workstations (Optional/As needed)
- **Names**: MAN-PC-01, LEE-PC-01, LIV-PC-01, HUL-PC-01
- **OS**: Windows 10/11 Pro
- **vCPU**: 1
- **vRAM**: 2GB
- **Storage**: 40GB
- **Network**: Connected to respective site switch
- **Domain Joined**: Yes, to riverside.local

## Current Configuration

### Domain Configuration
- **Domain Name**: riverside.local
- **NetBIOS Name**: RIVERSIDE
- **Forest/Domain Functional Level**: Windows Server 2019
- **FSMO Roles**: All on DC01

### DNS Configuration
- Primary DNS server: DC01 (10.90.10.1)
- Forward lookup zone: riverside.local
- Reverse lookup zones configured for all subnets

### DHCP Configuration
- DHCP server: DC01
- Scopes configured:
  - Manchester: 10.90.10.20 - 10.90.10.250
  - Leeds: 10.90.20.20 - 10.90.20.250
  - Liverpool: 10.90.30.20 - 10.90.30.250
  - Hull: 10.90.40.20 - 10.90.40.250
- Scope options:
  - Router (003): Site's respective default gateway
  - DNS Servers (006): 10.90.10.1
  - Domain Name (015): riverside.local

### Routing and Remote Access Configuration
- Enabled for LAN routing between subnets
- NAT configured for internet access through NATSwitch
- Interface types:
  - Site networks: Internal
  - NATSwitch: Internet


### Network Diagram
#### Virtual Network Diagram
![HyperV Configuration](./images/Riverside%20Virtual%20Topology.drawio.png)
#### Physical Network Idea
![Physical Network](./images/Riverside%20Physical%20Topology.drawio.png)