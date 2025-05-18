# Active Directory Group Structure & Nesting Plan
**Client:** Riverside Manufacturing – Fictional\
**Prepared by:** Warren Bebbington\
**Date:** 18/05/2025

Overview
To support Riverside Manufacturing’s distributed operations across Manchester, Leeds, Liverpool, Hull, and Head Office (HO), a robust Active Directory group design is implemented. This structure enables efficient access control, targeted policy application, and clear delegation aligned with site, department, and role. The approach ensures logical nesting, reusability, and scalability as the organisation evolves.

This document outlines a comprehensive AD group structure that:

- Adheres to the AGDLP model (Accounts > Global > Domain Local > Permissions)

- Supports layered targeting by department, site, and function

- Utilises consistent naming conventions for clarity and automation

- Enables clear group membership and delegation auditing

- Is extensible to future sites, departments, or cloud integration

## Group Naming Convention
Prefixes:

- `G_` – Global groups (user membership-based)

- `DL_` – Domain Local groups (used for resource permissions)

Site Abbreviations:

- `MAN` = Manchester

- `LEE` = Leeds

- `LIV` = Liverpool

- `HUL` = Hull

- `HO` = Head Office

Department Labels:

`Scanning`, `Machining`, `3DPrinting`, `IT`, `Finance`, `Executive`, `Site`

## Global Groups – Base Membership
These are the groups where actual user accounts are directly assigned.

### Manchester Site
- G_MAN_Scanning_Operators

- G_MAN_Scanning_Managers

- G_MAN_Machining_Operators

- G_MAN_Machining_Managers

- G_MAN_3DPrinting_Operators

- G_MAN_3DPrinting_Managers

- G_MAN_Site_Operators

- G_MAN_Site_Managers

### Leeds Site
- G_LEE_Scanning_Operators

- G_LEE_Scanning_Managers

- G_LEE_Machining_Operators

- G_LEE_Machining_Managers

- G_LEE_3DPrinting_Operators

- G_LEE_3DPrinting_Managers

- G_LEE_Site_Operators

- G_LEE_Site_Managers

### Liverpool Site
- G_LIV_Scanning_Operators

- G_LIV_Scanning_Managers

- G_LIV_Machining_Operators

- G_LIV_Machining_Managers

- G_LIV_3DPrinting_Operators

- G_LIV_3DPrinting_Managers

- G_LIV_Site_Operators

- G_LIV_Site_Managers

### Hull Site
- G_HUL_Scanning_Operators

- G_HUL_Scanning_Managers

- G_HUL_Machining_Operators

- G_HUL_Machining_Managers

- G_HUL_3DPrinting_Operators

- G_HUL_3DPrinting_Managers

- G_HUL_Site_Operators

- G_HUL_Site_Managers

### Head Office
- G_HO_IT_Operators

- G_HO_IT_Managers

- G_HO_Finance_Operators

- G_HO_Finance_Managers

- G_HO_Executive_CEO

## Global Groups – Site Aggregate
Aggregate groups used to group staff by site-wide role or department.

### Example: Manchester
- G_MAN_All_Users

- G_MAN_All_Operators

- G_MAN_All_Managers

- G_MAN_All_Scanning

- G_MAN_All_Machining

- G_MAN_All_3DPrinting

(Equivalent sets exist for LEE, LIV, HUL, and HO.)

## Global Groups – Function Aggregate
These groups unify similar roles across all sites.

- G_All_Scanning_Operators

- G_All_Scanning_Managers

- G_All_Scanning_Users

- G_All_Machining_Operators

- G_All_Machining_Managers

- G_All_Machining_Users

- G_All_3DPrinting_Operators

- G_All_3DPrinting_Managers

- G_All_3DPrinting_Users

- G_All_Site_Operators

- G_All_Site_Managers

- G_All_Site_Users

- G_All_IT_Operators

- G_All_IT_Managers

- G_All_IT_Users

- G_All_Finance_Operators

- G_All_Finance_Managers

- G_All_Finance_Users

## Global Groups – Organisation-Wide
Top-tier aggregates for broadest inclusion.

- G_All_Sites_Users — All users across the four operational sites (excludes HO)

- G_All_Operators — All operators (any site, any department)

- G_All_Managers — All managers (any site, any department)

- G_All_Users — All users company-wide, including HO

## Group Nesting Design
Group membership follows simple and consistent nesting logic:

### Base Level
Users are directly placed in one primary group only.\
Example: John Smith is added to `G_MAN_Scanning_Operators`

### Site Aggregates
Base groups are members of corresponding site-level aggregates:\
`G_MAN_Scanning_Operators` ⟶ `G_MAN_All_Users`, `G_MAN_All_Operators`, `G_MAN_All_Scanning`

### Function Aggregates
Same base group is added to function-level aggregates:\
`G_MAN_Scanning_Operators` ⟶ `G_All_Scanning_Operators`

### Organisation-Wide Groups
Aggregates flow up into top-level groups:\
`G_All_Scanning_Operators` ⟶ `G_All_Operators`
`G_MAN_All_Users` ⟶ `G_All_Users`

Note: Over-nesting is avoided for performance and clarity.

## Computer Groups
Mirroring user group structure for device management:

- G_MAN_Scanning_Computers

- G_MAN_All_Computers

- G_All_Scanning_Computers

- G_All_Computers
(Pattern repeats for each site and department.)

## Domain Local Groups (Resource Access)
Resources (file shares, printers, applications) are assigned permissions via DL_ groups:\

- DL_Scanning_Files_Modify

- DL_Machining_Share_Read

- DL_3DPrinting_Apps_Install

Membership: These DL_ groups include appropriate G_ function or site groups.

## Targeting Use Cases
|Use Case|	Method|
|--------|--------|
|Apply GPO to all 3D printing operators|`G_All_3DPrinting_Operators`|
|File share access for all scanning staff|Add `G_All_Scanning_Users` to `DL_Scanning_Files_Modify`
|Software deployment to Manchester 3D printing devices|Filter GPO to `G_MAN_3DPrinting_Computers`
|Delegate permissions to IT|Grant `G_All_IT_Managers` access via DL_ groups or OU delegation

## Implementation Examples
*Example 1*: Add New Scanning Operator (Manchester)

- Create user account in OU

- Add to `G_MAN_Scanning_Operators`

- Inherits all access via nesting

*Example 2*: Deploy Software to 3D Printing

- Create GPO with deployment

- Link at domain/root

- Scope to `G_All_3DPrinting_Computers`

*Example 3*: Access Control for File Share

- Create DL_Scanning_Files_Modify

- Add `G_All_Scanning_Users` to DL group

- Assign modify permissions on share
- 
## Group Nesting Overview

### Users

---

```Markdown
G_All_Users
│
├── G_All_Sites_Users
│   ├── G_MAN_All_Users
│   │   ├── G_MAN_Scanning_Operators
│   │   ├── G_MAN_Scanning_Managers
│   │   ├── G_MAN_Machining_Operators
│   │   ├── G_MAN_Machining_Managers
│   │   ├── G_MAN_3DPrinting_Operators
│   │   ├── G_MAN_3DPrinting_Managers
│   │   ├── G_MAN_Site_Operators
│   │   └── G_MAN_Site_Managers
│   │
│   ├── G_LEE_All_Users
│   │   └── (Same pattern as Manchester)
│   │
│   ├── G_LIV_All_Users
│   │   └── (Same pattern as Manchester)
│   │
│   └── G_HUL_All_Users
│       └── (Same pattern as Manchester)
│
├── G_HO_All_Users
│   ├── G_HO_IT_Operators
│   ├── G_HO_IT_Managers
│   ├── G_HO_Finance_Operators
│   ├── G_HO_Finance_Managers
│   └── G_HO_Executive_CEO
│
├── G_All_Operators
│   ├── G_All_Scanning_Operators
│   │   ├── G_MAN_Scanning_Operators
│   │   ├── G_LEE_Scanning_Operators
│   │   ├── G_LIV_Scanning_Operators
│   │   └── G_HUL_Scanning_Operators
│   │
│   ├── G_All_Machining_Operators
│   │   └── (Same pattern across all sites)
│   │
│   ├── G_All_3DPrinting_Operators
│   │   └── (Same pattern across all sites)
│   │
│   ├── G_All_Site_Operators
│   │   └── (Same pattern across all sites)
│   │
│   └── G_All_IT_Operators
│       └── G_HO_IT_Operators
│
├── G_All_Managers
│   └── Same as above (Managers instead of Operators)
│
└── G_All_Department_Users
    ├── G_All_Scanning_Users
    │   ├── G_All_Scanning_Operators
    │   └── G_All_Scanning_Managers
    ├── G_All_Machining_Users
    │   └── ...
    ├── G_All_3DPrinting_Users
    │   └── ...
    ├── G_All_Site_Users
    │   └── ...
    ├── G_All_IT_Users
    │   └── ...
    └── G_All_Finance_Users
        └── ...
```

### Computers

---
```Markdown
G_All_Computers
│
├── G_All_Site_Computers
│   ├── G_MAN_All_Computers
│   │   ├── G_MAN_Scanning_Computers
│   │   ├── G_MAN_Machining_Computers
│   │   ├── G_MAN_3DPrinting_Computers
│   │   └── G_MAN_Site_Computers
│   │
│   ├── G_LEE_All_Computers
│   │   ├── G_LEE_Scanning_Computers
│   │   ├── G_LEE_Machining_Computers
│   │   ├── G_LEE_3DPrinting_Computers
│   │   └── G_LEE_Site_Computers
│   │
│   ├── G_LIV_All_Computers
│   │   ├── G_LIV_Scanning_Computers
│   │   ├── G_LIV_Machining_Computers
│   │   ├── G_LIV_3DPrinting_Computers
│   │   └── G_LIV_Site_Computers
│   │
│   └── G_HUL_All_Computers
│       ├── G_HUL_Scanning_Computers
│       ├── G_HUL_Machining_Computers
│       ├── G_HUL_3DPrinting_Computers
│       └── G_HUL_Site_Computers
│
└── G_HO_All_Computers
    ├── G_HO_IT_Computers
    ├── G_HO_Finance_Computers
    └── G_HO_Executive_Computers
```
## Final Summary

This document outlines a complete, scalable, and well-nested Active Directory global group structure designed for a fictional company, "Riverside", operating across five locations (Manchester, Leeds, Liverpool, Hull, and Head Office). The group design follows Microsoft's **AGDLP** best practices, ensuring that users are only ever members of base-level global groups and permissions are granted via nested domain local groups. This setup offers a clean, auditable, and highly flexible system for assigning access and deploying policies by **site**, **department**, and **role**.

We’ve used a consistent naming convention (`G_` for global groups and `DL_` for domain locals), and structured the groups into **base**, **site aggregates**, **function aggregates**, and **organisation-wide** layers.

In total, this structure consists of:

- **37 base-level global groups** (where user accounts are assigned)
- **27 site aggregate groups** (e.g. all users, operators, managers per site)
- **18 function-level aggregates** (e.g. all scanning operators across all sites)
- **4 org-wide user aggregates** (all users, all operators, etc.)
- **17 global computer groups**, including:
  - 12 by site & department (e.g. `G_MAN_Scanning_Computers`)
  - 4 site-wide (e.g. `G_LIV_All_Computers`)
  - 1 full-org group: `G_All_Computers`

> 🔢 **Total group count: 103 global groups**

This structure allows for:

- **Clear targeting of GPOs**, login scripts, software deployments, etc.
- **Straightforward user onboarding** (one group membership per user)
- **Simplified auditing** (permissions can be traced through logical nesting)
- **Scalability** — easy to expand with new sites, departments, or roles
- **Efficient permissioning** via reusable DL_ groups

By keeping group memberships clean, avoiding unnecessary nesting, and maintaining consistent naming, this approach lays a solid foundation for managing a growing Active Directory environment in an enterprise-grade homelab or production network.

---
