# Autodesk Vault — System Requirements (2011–2027)

Complete reference compiled from Autodesk's official per-version system
requirements articles.

- Index: <https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-Vault-products.html>
- Retrieved: 2026-08-13

> **Vault 2016 is missing.** Autodesk's article for 2016 returns HTTP 404 even
> though the index page still links to it. See [Vault 2016](#vault-2016) below.

## Contents

Modern era (uniform table format): [2027](#vault-2027) · [2026](#vault-2026) ·
[2025](#vault-2025) · [2024](#vault-2024) · [2023](#vault-2023) · [2022](#vault-2022) ·
[2021](#vault-2021) · [2020](#vault-2020)

Legacy era: [2019](#vault-2019) · [2018](#vault-2018) · [2017](#vault-2017) ·
[2016](#vault-2016) · [2015](#vault-2015) · [2014](#vault-2014) ·
[2013](#vault-2013) · [2012](#vault-2012) · [2011](#vault-2011)

Summaries: [Cross-version comparison](#cross-version-comparison)

---

## General notes

- **64-bit only** from Vault 2019 onward. Vault 2011–2018 articles list separate
  32-bit and 64-bit OS support; 32-bit server support ends after 2014, and 32-bit
  client support ends after 2017.
- Autodesk does **not test or certify** local or cloud virtualization solutions;
  best-effort support only, and you may be referred to your virtualization vendor
  *(stated explicitly in the 2024–2027 articles)*.
- Disk requirements grow with the vault; size for future consumption.
- Vault server RAM also depends on the SQL Server configuration.
- SQL **Express** is supported for single-site only — replication requires
  Standard or Enterprise (all versions).
- OS support is bounded by the
  [Autodesk Product Support Lifecycle](https://www.autodesk.com/support/account/manage/versions/support-lifecycle).
- The Vault server should not be a domain controller (Vault 2011 article
  recommends a dedicated non-DC member server).

---

## Vault 2027

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2027-products> (updated Apr 3, 2026)
Products: Vault Basic, Vault Professional

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2022 Standard/Datacenter<br>Windows Server 2025 Standard/Datacenter<br>Windows 11 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2022 Express\*/Standard/Enterprise (CU18) |
| Database — Full Replication | SQL Server 2022 Standard/Enterprise (CU18) |
| CPU — Single Site | 2.5 GHz+ (min) / 3 GHz+ (rec) |
| CPU — Full Replication | 2.5 GHz+ (min) / 3.3 GHz+ (rec) |
| Memory — Single Site | 8 GB (min) / 16 GB (rec) |
| Memory — Full Replication | 16 GB (min) / 32 GB (rec) |
| Disk — Single Site | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication | 300 GB (min) / 500 GB (rec) |

\* SQL 2022 Express RTM installs by default with Vault Server; download and apply
the listed Cumulative Update. See Microsoft docs for Express edition limits.

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2022 Standard/Datacenter<br>Windows Server 2025 Standard/Datacenter |
| CPU | 2 GHz+ (min) / 3 GHz+ (rec) |
| Memory | 16 GB (min) / 32 GB (rec) |
| Disk | 300 GB (min) / 500 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 11 Professional/Enterprise |
| CPU | 1.6 GHz+ (min) / 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 10 GB (min) / 30 GB (rec) |

### Thin Client

Browsers: Microsoft Edge, Google Chrome, Mozilla Firefox, Apple Safari

---

## Vault 2026

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2026-products> (updated Feb 1, 2026)
Products: Vault Basic, Vault Professional

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter<br>Windows 10 Professional/Enterprise *(Vault Basic only)*<br>Windows 11 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2019 Express/Standard/Enterprise (CU29)<br>SQL Server 2022 Express\*/Standard/Enterprise (CU16) |
| Database — Full Replication | SQL Server 2019 Standard/Enterprise (CU29)<br>SQL Server 2022 Standard/Enterprise (CU16) |
| CPU — Single Site | 2.5 GHz+ (min) / 3 GHz+ (rec) |
| CPU — Full Replication | 2.5 GHz+ (min) / 3.3 GHz+ (rec) |
| Memory — Single Site | 8 GB (min) / 16 GB (rec) |
| Memory — Full Replication | 16 GB (min) / 32 GB (rec) |
| Disk — Single Site | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication | 300 GB (min) / 500 GB (rec) |

\* SQL 2022 Express RTM installs by default with Vault Server; apply the listed CU.

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter |
| CPU | 2 GHz+ (min) / 3 GHz+ (rec) |
| Memory | 16 GB (min) / 32 GB (rec) |
| Disk | 300 GB (min) / 500 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 10 Professional/Enterprise<br>Windows 11 Professional/Enterprise |
| CPU | 1.6 GHz+ (min) / 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 10 GB (min) / 30 GB (rec) |

### Thin Client

Browsers: Microsoft Edge, Google Chrome, Mozilla Firefox, Apple Safari

---

## Vault 2025

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2025-products> (updated Mar 20, 2025)
Products: Vault Basic, Vault Professional

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter<br>Windows 10 Professional/Enterprise *(Vault Basic only)*<br>Windows 11 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2017 Express\*/Standard/Enterprise (CU31)<br>SQL Server 2019 Express/Standard/Enterprise (CU23)<br>SQL Server 2022 Express/Standard/Enterprise (CU10) |
| Database — Full Replication | SQL Server 2017 Standard/Enterprise (CU31)<br>SQL Server 2019 Standard/Enterprise (CU23)<br>SQL Server 2022 Standard/Enterprise (CU10) |
| CPU — Single Site | 2.5 GHz+ (min) / 3 GHz+ (rec) |
| CPU — Full Replication | 2.5 GHz+ (min) / 3.3 GHz+ (rec) |
| Memory — Single Site | 8 GB (min) / 16 GB (rec) |
| Memory — Full Replication | 16 GB (min) / 32 GB (rec) |
| Disk — Single Site | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication | 300 GB (min) / 500 GB (rec) |

\* SQL 2017 Express RTM installs by default with Vault Server; apply the listed CU.

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter |
| CPU | 2 GHz+ (min) / 3 GHz+ (rec) |
| Memory | 16 GB (min) / 32 GB (rec) |
| Disk | 300 GB (min) / 500 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 10 Professional/Enterprise<br>Windows 11 Professional/Enterprise |
| CPU | 1.6 GHz+ (min) / 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 10 GB (min) / 30 GB (rec) |

### Thin Client

Browsers: Microsoft Edge, Google Chrome, Mozilla Firefox, Apple Safari

---

## Vault 2024

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2024-products> (updated Mar 28, 2024)
Products: Vault Basic, Vault Professional

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter<br>Windows 10 Professional/Enterprise *(Vault Basic only)*<br>Windows 11 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2016 Express/Standard/Enterprise (SP3)<br>SQL Server 2017 Express/Standard/Enterprise (CU31)<br>SQL Server 2019 Express/Standard/Enterprise (CU18, CU23) |
| Database — Full Replication | SQL Server 2016 Standard/Enterprise (SP3)<br>SQL Server 2017 Standard/Enterprise (CU31)<br>SQL Server 2019 Standard/Enterprise (CU18, CU23) |
| CPU — Single Site | 2.5 GHz+ (min) / 3 GHz+ (rec) |
| CPU — Full Replication | 2.5 GHz+ (min) / 3.3 GHz+ (rec) |
| Memory — Single Site | 8 GB (min) / 16 GB (rec) |
| Memory — Full Replication | 16 GB (min) / 32 GB (rec) |
| Disk — Single Site | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication | 300 GB (min) / 500 GB (rec) |

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter |
| CPU | 2 GHz+ (min) / 3 GHz+ (rec) |
| Memory | 16 GB (min) / 32 GB (rec) |
| Disk | 300 GB (min) / 500 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 10 Professional/Enterprise<br>Windows 11 Professional/Enterprise |
| CPU | 1.6 GHz+ (min) / 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 10 GB (min) / 30 GB (rec) |

### Thin Client

Browsers: Microsoft Edge, Google Chrome, Mozilla Firefox, Apple Safari

---

## Vault 2023

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2023-products> (updated Mar 28, 2024)
Products: Vault Products (all editions)

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2016 Standard/Datacenter<br>Windows Server 2019 Standard/Datacenter<br>Windows 10 Professional/Enterprise *(Vault Basic only)*<br>Windows 11 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2016 Express/Standard/Enterprise (SP3)<br>SQL Server 2017 Express/Standard/Enterprise (CU27, CU31)<br>SQL Server 2019 Express/Standard/Enterprise (CU13, CU23) |
| Database — Full Replication | SQL Server 2016 Standard/Enterprise (SP3)<br>SQL Server 2017 Standard/Enterprise (CU27, CU31)<br>SQL Server 2019 Standard/Enterprise (CU13, CU23) |
| CPU — Single Site | 2.5 GHz+ (min) / 3 GHz+ (rec) |
| CPU — Full Replication | 2.5 GHz+ (min) / 3.3 GHz+ (rec) |
| Memory — Single Site | 8 GB (min) / 16 GB (rec) |
| Memory — Full Replication | 16 GB (min) / 32 GB (rec) |
| Disk — Single Site | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication | 300 GB (min) / 500 GB (rec) |

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2016 Standard/Datacenter<br>Windows Server 2019 Standard/Datacenter |
| CPU | 2 GHz+ (min) / 3 GHz+ (rec) |
| Memory | 16 GB (min) / 32 GB (rec) |
| Disk | 300 GB (min) / 500 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 10 Professional/Enterprise<br>Windows 11 Professional/Enterprise |
| CPU | 1.6 GHz+ (min) / 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 10 GB (min) / 30 GB (rec) |

### Thin Client

Browsers: Microsoft Edge, Google Chrome, Mozilla Firefox, Apple Safari

---

## Vault 2022

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2022-products> (updated Mar 28, 2024)
Products: Vault Basic, Vault Office, Vault Professional, Vault Workgroup

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2016 Standard/Datacenter<br>Windows Server 2019 Standard/Datacenter<br>Windows 10 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2016 Express/Standard/Enterprise (CU15 for 2016 SP3)<br>SQL Server 2017 Express/Standard/Enterprise (CU22, CU27, CU31)<br>SQL Server 2019 Express/Standard/Enterprise (CU8, CU13, CU18) |
| Database — Full Replication | SQL Server 2016 Standard/Enterprise (CU15 for 2016 SP3)<br>SQL Server 2017 Standard/Enterprise (CU22, CU27, CU31)<br>SQL Server 2019 Standard/Enterprise (CU8, CU13, CU18) |
| CPU — Single Site | Intel i7 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| CPU — Full Replication | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory — Single Site | 8 GB (min) / 16 GB (rec) |
| Memory — Full Replication | 16 GB (min) / 32 GB (rec) |
| Disk — Single Site | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication | 300 GB (min) / 500 GB (rec) |

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2016 Standard/Datacenter<br>Windows Server 2019 Standard/Datacenter |
| CPU | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 16 GB (min) / 32 GB (rec) |
| Disk | 300 GB (min) / 500 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 10 Professional/Enterprise |
| Browser | Internet Explorer 11 |
| CPU | Intel i3 or AMD equivalent, 2 GHz+ (min)<br>Intel i7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 6 GB (min) / 10 GB (rec) |

### Thin Client

Browsers: Apple Safari, Google Chrome, Microsoft Edge, Mozilla Firefox

---

## Vault 2021

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2021-products> (updated Oct 8, 2023)
Products: Vault Basic, Vault Office, Vault Professional, Vault Workgroup

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2016 Standard/Datacenter<br>Windows Server 2019 Standard/Datacenter<br>Windows 10 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2014 Express/Standard/Enterprise (CU14 for 2014 SP2)<br>SQL Server 2016 Express/Standard/Enterprise (CU15 for 2016 SP2)<br>SQL Server 2017 Express/Standard/Enterprise (RTM, CU31) |
| Database — Full Replication | SQL Server 2014 Standard/Enterprise (CU14 for 2014 SP2)<br>SQL Server 2016 Standard/Enterprise (CU15 for 2016 SP2)<br>SQL Server 2017 Standard/Enterprise (RTM, CU31) |
| CPU — Single Site | Intel i5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| CPU — Full Replication | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory — Single Site | 8 GB (min) / 16 GB (rec) |
| Memory — Full Replication | 16 GB (min) / 32 GB (rec) |
| Disk — Single Site | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication | 300 GB (min) / 500 GB (rec) |

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2016 Standard/Datacenter<br>Windows Server 2019 Standard/Datacenter |
| CPU | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 16 GB (min) / 32 GB (rec) |
| Disk | 300 GB (min) / 500 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 10 Professional/Enterprise |
| Browser | Internet Explorer 11 |
| CPU | Intel i3 or AMD equivalent, 1.6 GHz+ (min)<br>Intel i7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 6 GB (min) / 10 GB (rec) |

### Thin Client

Browsers: Internet Explorer 11, Microsoft Edge, Chrome

---

## Vault 2020

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2020-products>

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2012 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2012 R2 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2016 Standard/Datacenter<br>Windows 7 Professional/Enterprise (SP1) *(Vault Basic only)*<br>Windows 10 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2014 Express/Standard/Enterprise (SP2, CU14 for 2014 SP2)<br>SQL Server 2016 Express/Standard/Enterprise (SP1, CU15 for 2016 SP2)<br>SQL Server 2017 Express/Standard/Enterprise (RTM, CU12) |
| Database — Full Replication | SQL Server 2014 Standard/Enterprise (SP2, CU14 for 2014 SP2)<br>SQL Server 2016 Standard/Enterprise (SP1, CU15 for 2016 SP2)<br>SQL Server 2017 Standard/Enterprise (RTM, CU12) |
| CPU — Single Site | Intel i5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| CPU — Full Replication | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory — Single Site | 8 GB (min) / 16 GB (rec) |
| Memory — Full Replication | 16 GB (min) / 32 GB (rec) |
| Disk — Single Site | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication | 300 GB (min) / 500 GB (rec) |

**Article notes:**

1. Autodesk's Windows OS support is synchronized with Microsoft's Mainstream
   Support End Date.
2. Microsoft does not support SQL Server 2017 Express on Windows 7. SQL Server
   2017 Express is installed by Vault Server when no Vault SQL instance is found
   — so Vault Basic on Windows 7 requires SQL Server 2014 pre-installed.
3. SQL Server follows the Modern Servicing Model.

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2012 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2012 R2 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2016 Standard/Datacenter |
| CPU | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 16 GB (min) / 32 GB (rec) |
| Disk | 300 GB (min) / 500 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 7 Professional/Enterprise (SP1)<br>Windows 10 Professional/Enterprise (1803 or higher) |
| Browser | Internet Explorer 11 |
| CPU | Intel i3 or AMD equivalent, 1.6 GHz+ (min)<br>Intel i7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 6 GB (min) / 10 GB (rec) |

### Thin Client

Browsers: Internet Explorer 11, Microsoft Edge, Chrome

---

## Vault 2019

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2019-products>

All supported operating systems and databases are **64-bit**.

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2012 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2012 R2 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2016 Essentials/Standard/Datacenter<br>Windows 7 Professional/Enterprise (SP1) *(Vault Basic only)*<br>Windows 8.1 Professional/Enterprise *(Vault Basic only)*<br>Windows 10 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2014 Express/Standard/Enterprise (SP2, CU14 for 2014 SP2)<br>SQL Server 2016 Express/Standard/Enterprise (SP1, CU10 for 2016 SP2)<br>SQL Server 2017 Express/Standard/Enterprise (RTM, CU12) |
| Database — Full Replication | SQL Server 2014 Standard/Enterprise (SP2, CU14 for 2014 SP2)<br>SQL Server 2016 Standard/Enterprise (SP1, CU10 for 2016 SP2)<br>SQL Server 2017 Standard/Enterprise (RTM, CU12) |
| CPU — Single Site | Intel i5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| CPU — Full Replication | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Memory — Full Replication (ADMS + SQL) | 16 GB (min) / 32 GB (rec) |
| Disk | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication (ADMS + SQL) | 300 GB (min) / 500 GB (rec) |

### Vault File Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2012 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2012 R2 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2016 Essentials/Standard/Datacenter |
| CPU | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 150 GB (min) / 300 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 7 Professional/Enterprise (SP1)<br>Windows 8.1 Professional/Enterprise<br>Windows 10 Professional/Enterprise |
| CPU | Intel i3 or AMD equivalent, 1.6 GHz+ (min)<br>Intel i7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 2 GB (min) / 4 GB (rec) |
| Disk | 6 GB (min) / 10 GB (rec) |
| Browser | Internet Explorer 11 |

---

## Vault 2018

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2018-products>
Products: Vault Basic, Vault Office, Vault Professional, Vault Workgroup

All supported operating systems and databases are **64-bit**.

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2012 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2012 R2 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2016 Essentials/Standard/Datacenter<br>Windows 7 Professional/Enterprise (SP1) *(Vault Basic only)*<br>Windows 8.1 Professional/Enterprise *(Vault Basic only)*<br>Windows 10 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2012 Express/Standard/Enterprise (SP3)<br>SQL Server 2014 Express/Standard/Enterprise (SP2, CU14 for 2014 SP2)<br>SQL Server 2016 Express/Standard/Enterprise (SP1, CU10 for 2016 SP2) |
| Database — Full Replication | SQL Server 2012 Standard/Enterprise (SP3)<br>SQL Server 2014 Standard/Enterprise (SP2, CU14 for 2014 SP2)<br>SQL Server 2016 Standard/Enterprise (SP1, CU10 for 2016 SP2) |
| CPU — Single Site | Intel i5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| CPU — Full Replication | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Memory — Full Replication (ADMS + SQL) | 16 GB (min) / 32 GB (rec) |
| Disk | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication (ADMS + SQL) | 300 GB (min) / 500 GB (rec) |

### Vault File Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2012 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2012 R2 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2016 Essentials/Standard/Datacenter |
| CPU | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 150 GB (min) / 300 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 7 Professional/Enterprise (SP1)<br>Windows 8.1 Professional/Enterprise<br>Windows 10 Professional/Enterprise |
| CPU | Intel i3 or AMD equivalent, 1.6 GHz+ (min)<br>Intel i7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 2 GB (min) / 4 GB (rec) |
| Disk | 6 GB (min) / 10 GB (rec) |
| Browser | Internet Explorer 11 |

---

## Vault 2017

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2017-products> (updated Oct 8, 2023)

Server and database entries are **64-bit**. The Vault Client still supports
32-bit on Windows 7 and 8.1.

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2012 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2012 R2 Foundation/Essentials/Standard/Datacenter<br>Windows 7 Professional/Enterprise (SP1) *(Vault Basic only)*<br>Windows 8.1 Professional/Enterprise *(Vault Basic only)*<br>Windows 10 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2012 Express/Standard/Enterprise (SP2 & SP3)<br>SQL Server 2014 Express/Standard/Enterprise (SP1 & SP2) |
| Database — Full Replication | SQL Server 2012 Standard/Enterprise (SP2 & SP3)<br>SQL Server 2014 Standard/Enterprise (SP1 & SP2) |
| CPU — Single Site | Intel i5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| CPU — Full Replication | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Memory — Full Replication (ADMS + SQL) | 16 GB (min) / 32 GB (rec) |
| Disk | 100 GB (min) / 200 GB (rec) |
| Disk — Full Replication (ADMS + SQL) | 300 GB (min) / 500 GB (rec) |

### Vault File Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2012 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2012 R2 Foundation/Essentials/Standard/Datacenter |
| CPU | Intel Xeon E5 or AMD equivalent, 2 GHz+ (min)<br>Intel Xeon E7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 150 GB (min) / 300 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 7 Professional/Enterprise (SP1) — 32-bit and 64-bit<br>Windows 8.1 Professional/Enterprise — 32-bit and 64-bit<br>Windows 10 Professional/Enterprise — 64-bit only |
| CPU | Intel i3 or AMD equivalent, 1.6 GHz+ (min)<br>Intel i7 or AMD equivalent, 3 GHz+ (rec) |
| Memory | 2 GB (min) / 4 GB (rec) |
| Disk | 6 GB (min) / 10 GB (rec) |
| Browser | Internet Explorer 11 |

---

## Vault 2016

**Not available.** Autodesk's article
(`System-requirements-for-Autodesk-Vault-2016-products.html`) returns **HTTP 404**,
and the CloudHelp install-guide page for Vault 2016 is likewise gone, even though
the requirements index page still links to both. The Wayback Machine is not
reachable from this environment.

What is confirmed about Vault 2016 from Autodesk's own materials and Autodesk
Community discussion:

- **Databases:** SQL Server 2012 SP2 and SQL Server 2014. SQL Server 2012 Express
  SP2 is installed by default when no prior SQL instance is detected and no remote
  instance is specified.
- **Server OS:** Windows Server 2012 supported. **Windows Server 2008 R2 dropped** —
  it is not supported by Vault 2016 or any later release.
- Running ADMS on a workstation OS supports roughly ten simultaneous Vault clients.

Vault 2016 sits between the [2015](#vault-2015) and [2017](#vault-2017) entries
above, which bracket it. Treat the bullets above as indicative and confirm with
Autodesk support before relying on them for a deployment decision.

---

## Vault 2015

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2015-products> (updated Oct 8, 2023)

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System (64-bit) | Windows 2008 Server R2 Standard/Enterprise (SP1)<br>Windows 2011 Small Business Server Essentials/Standard<br>Windows Server 2012 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2012 R2 Essentials/Standard/Datacenter |
| Operating System (32-bit and 64-bit) | Windows 7 Professional/Enterprise (SP1) *(Vault Basic only)*¹<br>Windows 8 Professional/Enterprise *(Vault Basic only)*¹<br>Windows 8.1 Professional/Enterprise *(Vault Basic only)*¹ |
| Database — Single Site | SQL Server 2008 Express/Workgroup/Standard/Enterprise (SP3)<br>SQL Server 2008 R2 Express/Standard/Enterprise (SP2)<br>SQL Server 2012 Express/Standard/Enterprise (SP1 & SP3)<br>*(all 32-bit and 64-bit)* |
| Database — Replication | SQL Server 2008 Standard/Enterprise (SP3)<br>SQL Server 2008 R2 Standard/Enterprise (SP2)<br>SQL Server 2012 Standard/Enterprise (SP1 & SP3) |
| CPU — Single Site | Intel Pentium 4 or AMD Athlon, 2 GHz+ (min)<br>Intel Pentium 4 or AMD 64-bit Dual Core, 3 GHz+ (rec) |
| CPU — Replication | Intel Pentium 4 or AMD Athlon, 3 GHz+ (min)<br>Intel Pentium 4 or AMD 64-bit Dual Core, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Memory — Remote Site (ADMS only) | 4 GB (min) / 8 GB (rec) |
| Memory — Full Replication (ADMS + SQL) | 8 GB (min) / 16 GB (rec) |
| Disk | 100 GB (min) / 200 GB (rec) |
| Disk — Remote Site (ADMS only) | 150 GB (min) / 300 GB (rec) |
| Disk — Full Replication (ADMS + SQL) | 300 GB (min) / 500 GB (rec) |

¹ Operating system not supported with Vault replication.

### Vault File Server

| Item | Requirement |
| --- | --- |
| Operating System (64-bit) | Windows 2008 Server R2 Standard/Enterprise (SP1)<br>Windows 2011 Small Business Server Essentials/Standard<br>Windows Server 2012 Foundation/Essentials/Standard/Datacenter<br>Windows Server 2012 R2 Essentials/Standard/Datacenter |
| CPU | Intel Pentium 4 or AMD Athlon, 2 GHz+ (min)<br>Intel Pentium 4 or AMD 64-bit Dual Core, 3 GHz+ (rec) |
| Memory | 4 GB (min) / 8 GB (rec) |
| Disk | 150 GB (min) / 300 GB (rec) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System (32-bit and 64-bit) | Windows 7 Professional/Enterprise (SP1)<br>Windows 8 Professional/Enterprise<br>Windows 8.1 Professional/Enterprise |
| CPU | Intel Pentium 4 or AMD Athlon, 1.6 GHz+ (min) / 2 GHz+ (rec) |
| Memory | 2 GB (min) / 4 GB (rec) |
| Disk | 6 GB (min) / 10 GB (rec) |
| Microsoft Office (Excel, PowerPoint, Word) | Office 2010 (SP1), 32-bit or 64-bit |
| Microsoft Outlook | Outlook 2010 (SP1), 32-bit or 64-bit |
| Browser | Internet Explorer 9, 10, 11<br>Mozilla Firefox 25<br>Google Chrome 31 |

---

## Vault 2014

Source: <https://www.autodesk.com/support/technical/article/System-Requirements-for-Autodesk-Vault-2014-Products> (updated Oct 8, 2023)
Products: Vault Basic, Vault Professional, Vault Workgroup

### Autodesk Data Management Server (ADMS)

**32-bit ADMS operating systems**

- Windows 8 Professional/Enterprise *(Vault Basic only)*
- Windows 7 Business/Professional/Ultimate/Enterprise (SP1)
- Windows 2008 Server Standard/Enterprise (SP2)
- Windows 2008 Small Business Server Standard/Premium

**64-bit ADMS operating systems**

- Windows 8 Professional/Enterprise *(Vault Basic only)*
- Windows 7 Business/Professional/Ultimate/Enterprise (SP1)
- Windows Server 2012 Foundation/Essentials/Standard/Datacenter
- Windows 2011 Small Business Server Standard/Enterprise
- Windows 2008 Server Standard/Enterprise (SP2)
- Windows 2008 Server R2 Standard/Enterprise (SP1)
- Windows 2008 Small Business Server Standard/Premium

**Single site requirements**

- SQL Server 2008 Express/Workgroup/Standard/Enterprise (SP3), 32-bit or 64-bit
- SQL Server 2008 R2 Express/Standard/Enterprise (SP2), 32-bit or 64-bit
- SQL Server 2012 Express (SP1), 32-bit or 64-bit
- SQL Server 2012 Standard/Enterprise (SP1), 32-bit or 64-bit
- CPU: Intel Pentium 4 or AMD Athlon, 2 GHz+ (Pentium 4 or AMD 64-bit dual-core, 3 GHz+ recommended)
- Memory: 2 GB (4 GB recommended)
- Disk: 100 GB (200 GB recommended)

**Replication requirements**

- SQL Server 2008 Standard/Enterprise (SP3), 32-bit or 64-bit
- SQL Server 2008 R2 Standard/Enterprise (SP2), 32-bit or 64-bit
- SQL Server 2012 Standard/Enterprise (SP1), 32-bit or 64-bit
- CPU: Pentium 4 or Athlon, 3 GHz+ (Pentium 4 or AMD 64-bit dual-core, 3 GHz+ recommended)

**Remote site for multisite replication (ADMS installation)**

- Memory: 2 GB (4 GB recommended)
- Disk: 150 GB (300 GB recommended)

**Full replication (ADMS + SQL installation)**

- Memory: 4 GB (8 GB recommended)
- Disk: 300 GB (500 GB recommended)

**Microsoft SharePoint integration:** SharePoint 2010 Standard and Enterprise editions

### Vault Client

Operating systems (both 32-bit and 64-bit):

- Windows 7 Home/Business/Professional/Ultimate/Enterprise (SP1)
- Windows 8 Professional/Enterprise

| Item | Requirement |
| --- | --- |
| CPU | Pentium 4 or Athlon, 1.6 GHz+ (2 GHz+ recommended) |
| Memory | 2 GB (4 GB recommended) |
| Disk | 6 GB (10 GB recommended) |
| Office add-in (Excel, PowerPoint, Word) | Office 2007 (SP2); Office 2010 (SP1), 32-bit or 64-bit |
| Outlook add-in | Outlook 2007 (SP2); Outlook 2010 (SP1), 32-bit or 64-bit |
| Browser | Internet Explorer 8, 9, or 10; Mozilla Firefox 18; Apple Safari 5; Google Chrome 23 |

---

## Vault 2013

Source: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2013-products>

### Autodesk Data Management Server (ADMS)

**32-bit ADMS operating systems**

- Windows 2003 Server Standard (SP2), Enterprise (SP2)
- Windows 2003 Server R2 Standard (SP2), R2 Enterprise (SP2)
- Windows 2003 Small Business Server Standard (SP2), Premium (SP2)
- Windows 2003 Small Business Server R2 Standard, R2 Premium
- Windows 2008 Server Standard (SP2), Enterprise (SP2)
- Windows 2008 Small Business Server Standard, Premium
- Windows XP Professional (SP3)¹
- Windows 7 Business / Professional / Ultimate / Enterprise (SP1)¹

**64-bit ADMS operating systems**

- Windows 2003 Server Standard (SP2), Enterprise (SP2)
- Windows 2003 Server R2 Standard (SP2), R2 Enterprise (SP2)
- Windows 2008 Server Standard (SP2), Enterprise (SP2)
- Windows 2008 Server R2 Standard (SP1), R2 Enterprise (SP1)
- Windows 2008 Small Business Server Standard, Premium
- Windows 2011 Small Business Server Essentials, Standard
- Windows XP Professional (SP2)¹
- Windows 7 Business / Professional / Ultimate / Enterprise (SP1)¹

¹ Operating system not supported with a Vault fully replicated environment.

**Databases — single site** (32-bit or 64-bit)

- SQL Server 2008 Express Edition (SP2 or SP3)
- SQL Server 2008 Workgroup Edition (SP2 or SP3)
- SQL Server 2008 Standard & Enterprise Edition (SP2 or SP3)
- SQL Server 2008 R2 Express Edition (SP1)
- SQL Server 2008 R2 Standard & Enterprise Edition (SP1)

**Databases — replication** (32-bit or 64-bit)

- SQL Server 2008 Standard & Enterprise Edition (SP2 or SP3)
- SQL Server 2008 R2 Standard & Enterprise Edition (SP1)

**Microsoft SharePoint integration:** SharePoint 2010 Standard or higher

| Item | Requirement |
| --- | --- |
| CPU — Single Site | Intel Pentium 4 or AMD Athlon, 2 GHz+ (min)<br>Intel Pentium 4 or AMD 64-bit Dual Core, 3 GHz+ (rec) |
| CPU — Replication | Intel Pentium 4 or AMD Athlon, 3 GHz+ (min)<br>Intel Pentium 4 or AMD 64-bit Dual Core, 3 GHz+ (rec) |
| Memory | 1 GB (min) / 4 GB (rec) |
| Memory — Remote Site (ADMS only) | 2 GB (min) / 3 GB (rec) |
| Memory — Full Replication (ADMS + SQL) | 4 GB (min) / 8 GB (rec) |
| Disk | 100 GB (min) / 200 GB (rec) |
| Disk — Remote Site (ADMS only) | 150 GB (min) / 300 GB (rec) |
| Disk — Full Replication (ADMS + SQL) | 300 GB (min) / 500 GB (rec) |

### Vault Client

**32-bit operating systems**

- Windows XP Home Editions (SP3), XP Professional (SP3)
- Windows 7 Home Editions / Business / Professional / Ultimate / Enterprise (SP1)

**64-bit operating systems**

- Windows XP Professional (SP2)
- Windows 7 Home Editions / Business / Professional / Ultimate / Enterprise (SP1)

| Item | Requirement |
| --- | --- |
| CPU | Intel Pentium 4 or AMD Athlon, 1.6 GHz+ (min) / 2 GHz+ (rec) |
| Memory | 1 GB (min) / 2 GB (rec) |
| Disk | 1 GB (min) / 4 GB (rec) |
| Microsoft Office (Excel, PowerPoint, Word) | Office 2003 (SP3), 2007 (SP2); Office 2010 (SP1), 32-bit or 64-bit |
| Microsoft Outlook | Outlook 2007 (SP2); Outlook 2010 (SP1), 32-bit or 64-bit |
| Browser | Internet Explorer 8, 9; Mozilla Firefox 6; Apple Safari 4, 5; Google Chrome 13 |

---

## Vault 2012

Source: <https://www.autodesk.com/support/technical/article/System-Requirements-for-Autodesk-Vault-2012-products>

### Autodesk Data Management Server (ADMS)

**32-bit ADMS operating systems**

- Windows 2003 Server Standard/Enterprise (SP2)
- Windows 2003 Server R2 Standard/Enterprise (SP2)
- Windows 2003 Small Business Server Standard/Premium (SP2)
- Windows 2003 Small Business Server R2 Standard/Premium (SP2)
- Windows 2008 Server Standard/Enterprise (SP2)
- Windows 2008 Small Business Server Standard/Premium
- Windows XP Professional (SP3)\*
- Windows Vista Business/Ultimate/Enterprise (SP2)\*
- Windows 7 Business/Professional/Ultimate/Enterprise\*

**64-bit ADMS operating systems**

- Windows 2003 Server Standard/Enterprise (SP2)
- Windows 2003 Server R2 Standard/Enterprise (SP2)
- Windows 2008 Server Standard/Enterprise (SP2)
- Windows 2008 Server R2 Standard/Enterprise (SP1)
- Windows 2008 Small Business Server Standard/Premium
- Windows XP Professional (SP2)\*
- Windows Vista Business/Ultimate/Enterprise (SP2)\*
- Windows 7 Business/Professional/Ultimate/Enterprise\*

\* Operating system is not supported in a replicated environment.

**Single site requirements**

- SQL Server 2008 Express/Workgroup/Standard/Enterprise (SP2)
- SQL Server 2008 R2 Express/Standard/Enterprise
- CPU: Intel Pentium 4 or AMD Athlon, 2 GHz+ (Pentium 4 or AMD 64-bit Dual Core, 3 GHz+ recommended)
- Memory: 1 GB (4 GB recommended)
- Disk: 100 GB (200 GB recommended)

**Replication requirements**

- SQL Server 2008 Standard & Enterprise (32-bit or 64-bit, SP2)
- SQL Server 2008 R2 Standard & Enterprise (32-bit or 64-bit)
- CPU: Intel Pentium 4 or AMD Athlon, 3 GHz+ (Pentium 4 or AMD 64-bit Dual Core, 3 GHz+ recommended)
- Remote site for multisite replication (ADMS): 2 GB RAM (3 GB rec), 150 GB disk (300 GB rec)
- Full replication (ADMS + SQL): 4 GB RAM (8 GB rec), 300 GB disk (500 GB rec)

### Vault Client

**32-bit:** Windows XP Home/Professional (SP3); Windows Vista Home/Business/Ultimate/Enterprise (SP2); Windows 7 Home/Business/Professional/Ultimate/Enterprise

**64-bit:** Windows XP Professional (SP3); Windows Vista Home/Business/Ultimate/Enterprise (SP2); Windows 7 Home/Business/Professional/Ultimate/Enterprise

| Item | Requirement |
| --- | --- |
| CPU | Intel Pentium 4 or AMD Athlon, 1.6 GHz+ (2 GHz+ recommended) |
| Memory | 1 GB (2 GB recommended) |
| Disk | 1 GB (4 GB recommended) |
| Office add-in (Excel, PowerPoint, Word) | Office 2003 or 2007; Office 2010 (32-bit) |
| Outlook add-in | Outlook 2007; Outlook 2010 (32-bit) |
| Browser | Internet Explorer 7 or 8; Mozilla Firefox 3.6; Apple Safari 4 or 5; Google Chrome 7 |

---

## Vault 2011

Source: <https://www.autodesk.com/support/technical/article/System-Requirements-for-Autodesk-Vault-2011-products>

### Operating systems

**32-bit**

- Windows 2008 Server Standard (SP2), Enterprise (SP2)
- Windows 2003 Server Standard (SP2), Standard R2 (SP2)
- Windows 2003 Server Enterprise (SP2), Enterprise R2 (SP2)
- Windows 2003 Server Small Business Standard Edition (SP2), Small Business Standard R2 (SP2)
- Windows XP Professional (SP2, SP3)
- Windows Vista Ultimate / Enterprise / Business (SP1, SP2)
- Windows 7 Ultimate / Enterprise / Business

**64-bit**

- Windows 2008 Server Standard (SP2), Enterprise (SP2)
- Windows 2008 Server R2 Standard, R2 Enterprise
- Windows 2003 Server Standard (SP2), Standard R2 (SP2)
- Windows 2003 Server Enterprise (SP2), Enterprise R2 (SP2)
- Windows XP Professional (SP2, SP3)
- Windows Vista Ultimate / Enterprise / Business (SP1, SP2)
- Windows 7 Ultimate / Enterprise / Business

> For best performance on servers, Autodesk recommends a dedicated member
> (non-domain-controller) server. For data management client add-ins, the system
> requirements are those of the design application.

### Microsoft SQL requirements

Same list for 32-bit and 64-bit operating systems:

- SQL Server 2005 Express / Standard / Enterprise / Workgroup Edition (SP3)
- SQL Server 2008 Express / Standard / Enterprise Edition (SP1 or SP2\*)

\* SP2 is only supported when combined with the Vault Performance hotfix and SQL
2008 SP2 Cumulative Update 6 (Microsoft KB 2582285).

**Upgrade note:** Vault 2010 installed SQL 2005 Express. The minimum requirement
for Vault 2011 is SQL 2005 Express SP3, which must be applied *before* installing
Vault 2011. If no SQL instance exists, SQL 2005 Express SP3 is installed
automatically.

### Hardware

| Role | Minimum | Recommended |
| --- | --- | --- |
| Vault Client | Pentium 4 / Xeon / Athlon 64 / Opteron 1.6 GHz, 1 GB RAM, 1 GB disk | 2 GHz, 2 GB RAM, 4 GB disk |
| Vault Server | Pentium 4 / Xeon / Athlon 64 / Opteron 2.0 GHz, 2 GB RAM, 100 GB disk | 3.0 GHz, 4 GB RAM, 200 GB disk |
| Replication (Vault Server + SQL Server) | 3.0 GHz, 4 GB RAM, 300 GB disk | 3.0 GHz, 8 GB RAM, 500 GB disk |
| Replication (Vault Server only) | 3.0 GHz, 2 GB RAM, 150 GB disk | 3.0 GHz, 3 GB RAM, 300 GB disk |

### Other requirements

- A DVD drive is required to install from disc.
- Operating system installation media.
- Internet connection for web downloads and Subscription Aware access.
- Microsoft Internet Explorer 6 SP1 or later.
- Allow Windows to manage virtual memory; keep at least twice as much free disk
  space as system memory.

---

## Cross-version comparison

### Vault Server operating systems

| Version | Windows Server | Desktop OS (Vault Basic only) |
| --- | --- | --- |
| 2027 | 2022, 2025 | Windows 11 |
| 2026 | 2019, 2022 | Windows 10, 11 |
| 2025 | 2019, 2022 | Windows 10, 11 |
| 2024 | 2019, 2022 | Windows 10, 11 |
| 2023 | 2016, 2019 | Windows 10, 11 |
| 2022 | 2016, 2019 | Windows 10 |
| 2021 | 2016, 2019 | Windows 10 |
| 2020 | 2012, 2012 R2, 2016 | Windows 7 SP1, Windows 10 |
| 2019 | 2012, 2012 R2, 2016 | Windows 7 SP1, 8.1, 10 |
| 2018 | 2012, 2012 R2, 2016 | Windows 7 SP1, 8.1, 10 |
| 2017 | 2012, 2012 R2 | Windows 7 SP1, 8.1, 10 |
| 2016 | *(article unavailable — Server 2012 confirmed; 2008 R2 dropped)* | — |
| 2015 | 2008 R2 SP1, 2011 SBS, 2012, 2012 R2 | Windows 7 SP1, 8, 8.1 |
| 2014 | 2008 SP2, 2008 R2 SP1, 2008 SBS, 2011 SBS, 2012 | Windows 7 SP1, Windows 8 |
| 2013 | 2003, 2003 R2, 2003 SBS, 2008, 2008 R2, 2008 SBS, 2011 SBS | Windows XP, Windows 7 SP1 |
| 2012 | 2003, 2003 R2, 2003 SBS, 2008, 2008 R2, 2008 SBS | Windows XP, Vista SP2, Windows 7 |
| 2011 | 2003, 2003 R2, 2003 SBS, 2008 SP2, 2008 R2 | Windows XP, Vista, Windows 7 |

### SQL Server support

| Version | Supported SQL Server versions (with CU/SP level) |
| --- | --- |
| 2027 | 2022 (CU18) |
| 2026 | 2019 (CU29), 2022 (CU16) |
| 2025 | 2017 (CU31), 2019 (CU23), 2022 (CU10) |
| 2024 | 2016 (SP3), 2017 (CU31), 2019 (CU18/CU23) |
| 2023 | 2016 (SP3), 2017 (CU27/CU31), 2019 (CU13/CU23) |
| 2022 | 2016 (CU15 for SP3), 2017 (CU22/27/31), 2019 (CU8/13/18) |
| 2021 | 2014 (CU14 for SP2), 2016 (CU15 for SP2), 2017 (RTM, CU31) |
| 2020 | 2014 (SP2, CU14), 2016 (SP1, CU15 for SP2), 2017 (RTM, CU12) |
| 2019 | 2014 (SP2, CU14), 2016 (SP1, CU10 for SP2), 2017 (RTM, CU12) |
| 2018 | 2012 (SP3), 2014 (SP2, CU14), 2016 (SP1, CU10 for SP2) |
| 2017 | 2012 (SP2 & SP3), 2014 (SP1 & SP2) |
| 2016 | *(article unavailable — 2012 SP2 and 2014 confirmed)* |
| 2015 | 2008 (SP3), 2008 R2 (SP2), 2012 (SP1 & SP3) |
| 2014 | 2008 (SP3), 2008 R2 (SP2), 2012 (SP1) |
| 2013 | 2008 (SP2/SP3), 2008 R2 (SP1) |
| 2012 | 2008 (SP2), 2008 R2 |
| 2011 | 2005 (SP3), 2008 (SP1 or SP2 + hotfix) |

### Vault Server hardware by version

| Version | CPU (single site) min/rec | RAM min/rec | Disk min/rec |
| --- | --- | --- | --- |
| 2023–2027 | 2.5 GHz / 3 GHz | 8 GB / 16 GB | 100 GB / 200 GB |
| 2022 | i7 2 GHz / Xeon E7 3 GHz | 8 GB / 16 GB | 100 GB / 200 GB |
| 2020–2021 | i5 2 GHz / Xeon E7 3 GHz | 8 GB / 16 GB | 100 GB / 200 GB |
| 2017–2019 | i5 2 GHz / Xeon E7 3 GHz | 4 GB / 8 GB | 100 GB / 200 GB |
| 2015 | P4 2 GHz / dual-core 3 GHz | 4 GB / 8 GB | 100 GB / 200 GB |
| 2014 | P4 2 GHz / dual-core 3 GHz | 2 GB / 4 GB | 100 GB / 200 GB |
| 2013 | P4 2 GHz / dual-core 3 GHz | 1 GB / 4 GB | 100 GB / 200 GB |
| 2012 | P4 2 GHz / dual-core 3 GHz | 1 GB / 4 GB | 100 GB / 200 GB |
| 2011 | 2.0 GHz / 3.0 GHz | 2 GB / 4 GB | 100 GB / 200 GB |

### Vault Client hardware by version

| Version | CPU min/rec | RAM min/rec | Disk min/rec |
| --- | --- | --- | --- |
| 2023–2027 | 1.6 GHz / 3 GHz | 4 GB / 8 GB | 10 GB / 30 GB |
| 2022 | i3 2 GHz / i7 3 GHz | 4 GB / 8 GB | 6 GB / 10 GB |
| 2020–2021 | i3 1.6 GHz / i7 3 GHz | 4 GB / 8 GB | 6 GB / 10 GB |
| 2017–2019 | i3 1.6 GHz / i7 3 GHz | 2 GB / 4 GB | 6 GB / 10 GB |
| 2014–2015 | P4 1.6 GHz / 2 GHz | 2 GB / 4 GB | 6 GB / 10 GB |
| 2012–2013 | P4 1.6 GHz / 2 GHz | 1 GB / 2 GB | 1 GB / 4 GB |
| 2011 | 1.6 GHz / 2 GHz | 1 GB / 2 GB | 1 GB / 4 GB |

### Full replication (ADMS + SQL) sizing by version

| Version | RAM min/rec | Disk min/rec |
| --- | --- | --- |
| 2020–2027 | 16 GB / 32 GB | 300 GB / 500 GB |
| 2017–2019 | 16 GB / 32 GB | 300 GB / 500 GB |
| 2015 | 8 GB / 16 GB | 300 GB / 500 GB |
| 2011–2014 | 4 GB / 8 GB | 300 GB / 500 GB |

### Thin client / web browser support

| Version | Browsers |
| --- | --- |
| 2022–2027 | Edge, Chrome, Firefox, Safari |
| 2020–2021 | Internet Explorer 11, Edge, Chrome |
| 2017–2019 | Internet Explorer 11 *(Vault Client browser requirement)* |
| 2015 | Internet Explorer 9/10/11, Firefox 25, Chrome 31 |
| 2014 | Internet Explorer 8/9/10, Firefox 18, Safari 5, Chrome 23 |
| 2013 | Internet Explorer 8/9, Firefox 6, Safari 4/5, Chrome 13 |
| 2012 | Internet Explorer 7/8, Firefox 3.6, Safari 4/5, Chrome 7 |
| 2011 | Internet Explorer 6 SP1 or later |

### Microsoft Office / Outlook add-in support

| Version | Office | Outlook |
| --- | --- | --- |
| 2015 | Office 2010 (SP1), 32/64-bit | Outlook 2010 (SP1), 32/64-bit |
| 2014 | Office 2007 (SP2); Office 2010 (SP1) | Outlook 2007 (SP2); Outlook 2010 (SP1) |
| 2013 | Office 2003 (SP3), 2007 (SP2), 2010 (SP1) | Outlook 2007 (SP2), 2010 (SP1) |
| 2012 | Office 2003, 2007; Office 2010 (32-bit) | Outlook 2007; Outlook 2010 (32-bit) |

*(Office/Outlook add-in requirements are not listed in the 2016+ articles.)*

### SharePoint integration

| Version | SharePoint |
| --- | --- |
| 2014 | SharePoint 2010 Standard and Enterprise |
| 2013 | SharePoint 2010 Standard or higher |

---

## Related Autodesk articles

- [Optimal Memory Configuration For Vault](https://www.autodesk.com/support/technical/article/Optimal-Memory-Configuration-For-Vault)
- [What is the recommended CPU configuration for Vault?](https://www.autodesk.com/support/technical/article/What-is-the-recommended-CPU-configuration-for-Vault)
- [Recommended server hardware configuration for Vault](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Recommended-server-hardware-configuration-for-Vault.html)
- [Using a single Inventor Project with Vault](https://www.autodesk.com/support/technical/article/Using-Autodesk-Vault-with-a-Single-Inventor-Project)
