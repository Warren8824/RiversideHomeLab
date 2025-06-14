# Global Security Group Structure & Inheritance Plan

**Client:** Riverside Manufacturing - Fictional\
**Prepared by:** Warren Bebbington\
**Date:** 26/05/2025

---

> This document outlines the global security group strategy used at Riverside Manufacturing. It complements the OU structure and focuses on a clean, logical, and scalable design for permission assignment, policy filtering, and administrative delegation across departments, roles, and sites.

---

## Purpose

To create a structured group system that provides:

* Simple user group assignments
* Granular and flexible targeting
* Minimal administrative overhead
* Maximum scalability across new departments, roles, or sites

---

## Why This Structure?

The approach taken here aims to balance **simplicity and granularity**:

* Users are only assigned to **one primary group** that clearly represents their job role, department, and site. No need to manually add users to multiple levels.
* From that single group, **nesting** is used to allow access to broader categories (site-wide, department-wide, role-wide, etc.).
* Admins can target policies, file permissions, software deployments, or mail groups at the most appropriate level without ambiguity.
* It allows any new department or site to be bolted onto the system without reworking the whole hierarchy.

This structure reduces clutter and human error, while supporting rich targeting scenarios like:

* All Managers
* All 3D Printing staff at Leeds
* All users in Hull
* All Scanning Operators across all sites

---

## Group Inheritance Model

Users are assigned to the **most specific group**:

> `SITE_DEPT_ROLE`
> e.g., `MAN_Scanning_Operator`

### Inheritance Chain

Each group feeds into higher-level categories:

```
MAN_Scanning_Operator
├──> MAN_Scanning
│    └──> MAN
│         └──> All_Users
└──> All_Scanning_Operator
     └──> All_Operator
```

This allows access to any of the following:

* All users at Manchester
* All Scanning users at Manchester
* All Scanning Operators across all sites
* All Operators across the company

---

## Naming Convention

Group names follow a clear and consistent pattern:

### Components

* **Sites:** `MAN`, `LEE`, `LIV`, `HUL`, `HO`
* **Departments:** `3DPrinting`, `Machining`, `Scanning`, `Office`, `IT`, `Finance`, `Executive`
* **Roles:** `Operator`, `Manager`, `CEO`

### Group Levels

| Level | Example                 | Description                         |
| ----- | ----------------------- | ----------------------------------- |
| 1     | `MAN_Scanning_Operator` | Users are assigned here             |
| 2     | `MAN_Scanning`          | All users in Scanning at Manchester |
| 3     | `MAN`                   | All users at Manchester             |
| 4     | `All_Users`             | All users company-wide              |
| 5     | `All_Scanning_Operator` | All Scanning Operators across sites |
| 6     | `All_Operator`          | All Operators company-wide          |

Special roles (HO only):

* `HO_IT_Manager`, `HO_Executive_CEO`, etc.

---

## Diagram

```
User: John Smith (Leeds, Machining, Manager)

Assigned to:
  LEE_Machining_Manager

Which inherits:
├──> LEE_Machining
│    └──> LEE
│         └──> All_Users
└──> All_Machining_Manager
     └──> All_Manager
```

---

## Use Cases

| Target                                 | Group to Use                      |
| -------------------------------------- | --------------------------------- |
| All Scanning Managers across all sites | `All_Scanning_Manager`            |
| All users in Hull                      | `HUL`                             |
| All Managers company-wide              | `All_Manager`                     |
| All 3D Printing users at Leeds         | `LEE_3DPrinting`                  |
| All IT staff at HO                     | `HO_IT_Manager`, `HO_IT_Operator` |

---

## Administration Notes

* **User assignment** is always at the most specific level (Site + Dept + Role).
* **Nesting** handles everything else.
* Scripts will validate nesting and enforce consistency.
* All groups are **Global Security Groups**.
* Domain Local Groups (e.g., for FileServer permissions) will reference these global groups and are defined separately.

---

## Next Steps

| Task                                   | Status |
| -------------------------------------- | ------ |
| Create group nesting script            | \[ ]   |
| Document domain-level groups           | \[ ]   |
| Create import CSV for group creation   | \[ ]   |
| Populate security groups for each user | \[ ]   |

---

## Notes

* Consistency is critical — follow the naming pattern exactly.
* Group-based targeting is used instead of relying on AD attributes.
* This structure can be used with PowerShell, GPO, folder permissions, and even cloud sync mappings.

---

> This group strategy is designed to be bulletproof at scale. If a new site or department is added, just follow the same rules — no rewrites, no redesigns.
