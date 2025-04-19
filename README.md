# Riverside Manufacturing Hyper-V Lab Environment

## Overview
This document describes the current Windows Server 2019 Hyper-V lab environment that simulates a multi-site network for Riverside Manufacturing. This lab will be used to develop and demonstrate core IT administration skills.

## Lab Environment Specifications

### Recommended Host System
- **Operating System**: Windows 10/11 Pro (or Windows Server 2019)
- **CPU**: Intel/AMD with virtualization support
- **RAM**: 16GB or higher (recommended)
- **Storage**: 500GB SSD or higher
- **Network**: Single physical adapter with internet access

### Current Used Host System
- **Operating System**: Windows 11 Pro
- **CPU**: Intel(R) Core(TM) i5-8350U CPU @ 1.70GHz   1.90 GHz
- **RAM**: 32GB
- **Storage**: 500GB External SSD
- **Network**: Intel(R) Dual Band Wireless-AC 8265

## Usage Scenarios
This lab environment will be used to practice and demonstrate the following IT administration skills:

### Active Directory Management
- [ ] Creating and managing Organizational Units (OUs)
- [ ] Creating and managing user accounts
- [ ] Managing security groups and distribution groups
- [ ] Password resets and account unlocks

### Group Policy Administration
- [ ] Creating and applying GPOs
- [ ] Configuring security settings
- [ ] Managing software installation
- [ ] Configuring desktop settings

### Network Services Management
- [ ] DNS configuration and troubleshooting
- [ ] DHCP scope management
- [ ] Network routing configuration

### System Administration
- [ ] Server management and monitoring
- [ ] Event log analysis
- [ ] Backup and recovery procedures
- [ ] Windows Update management

## Next Steps for Lab Development

### Phase 1: Active Directory Structure Implementation
- Create organizational unit structure
- Define security groups
- Create test user accounts
- Document permissions model

### Phase 2: Group Policy Implementation
- Configure password policies
- Set up desktop standardization
- Implement security baselines
- Configure software restrictions

### Phase 3: File Server Implementation
- Add a file server VM
- Configure shared folders
- Set up DFS namespaces
- Implement access controls

### Phase 4: Monitoring and Reporting
- Configure performance monitoring
- Set up event log forwarding
- Create administration reports
- Implement alerting

## Appendices

### Implementation Checklist
- [x] Virtual network configuration
- [x] Domain controller installation
- [x] DNS configuration
- [x] DHCP configuration
- [x] Routing configuration
- [ ] OU structure creation
- [ ] Group Policy implementation
- [ ] File server setup
- [ ] Client configuration

### Troubleshooting Common Issues
#### Domain Join Issues
1. Verify DNS settings on client
2. Check network connectivity
3. Ensure time synchronization
4. Verify user has permissions to join domain

#### Network Connectivity Issues
1. Check virtual switch configuration
2. Verify IP configuration
3. Test connectivity using ping and tracert
4. Verify routing tables

#### DNS Resolution Problems
1. Check DNS server service
2. Verify zone configuration
3. Clear DNS cache
4. Check client DNS settings