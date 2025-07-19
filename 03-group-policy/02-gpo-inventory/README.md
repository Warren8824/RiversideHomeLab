# GPO Inventory

This is where we will define the simple GPOs that will be designed and applied in the homelab to reflect standard operating practices.

## Polices appied at OU = AllComputers

---

### Sec_Pre Logon UI Settings

The first GPO created was this, and it was used to standardise the look and functionality of ALL computers pre logon. Check it out using [this link](pre-logon-ui-settings.md)

### Sec_Allow Internal Ping

This gpo changes the Windows Firewall rule to Enable client PCs tp respond to ICMPv4 Echo Requests from certain IP ranges, in order for IT to be able to troubleshoot issues. Check it out using [this link](allow-internal-ping.md)