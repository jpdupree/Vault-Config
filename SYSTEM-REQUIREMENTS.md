# Autodesk Vault — System Requirements

Reference extracted from Autodesk's official system requirements articles.

- Hub: <https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-Vault-products.html>
- Retrieved: 2026-08-13

**Universal rules (all versions):**

- Autodesk Vault supports **64-bit operating systems only**.
- Autodesk does **not test or certify** any local or cloud-based virtual environment
  solution, but provides best-effort support. Users may be directed to their
  virtualization provider for case-by-case issues. *(stated 2024–2027 articles)*
- Disk space requirements grow as the Vault grows — plan for future consumption.
- Vault server RAM needs also vary with the SQL Server configuration.
- OS/product support is bounded by Autodesk's
  [Product Support Lifecycle](https://www.autodesk.com/support/account/manage/versions/support-lifecycle).
- Autodesk recommends installing the latest product updates (Autodesk Account
  portal or Autodesk Access app).

---

## Vault 2027

Article: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2027-products> (updated Apr 3, 2026)
Products: Vault Basic, Vault Professional

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2022 Standard/Datacenter<br>Windows Server 2025 Standard/Datacenter<br>Windows 11 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2022 Express\*/Standard/Enterprise (CU18) |
| Database — Full Replication | SQL Server 2022 Standard/Enterprise (CU18) |
| CPU — Single Site | 2.5 GHz+ (min) / 3 GHz+ (recommended) |
| CPU — Full Replication | 2.5 GHz+ (min) / 3.3 GHz+ (recommended) |
| Memory — Single Site | 8 GB (min) / 16 GB (recommended) |
| Memory — Full Replication | 16 GB (min) / 32 GB (recommended) |
| Disk — Single Site | 100 GB (min) / 200 GB (recommended) |
| Disk — Full Replication | 300 GB (min) / 500 GB (recommended) |

\* SQL 2022 Express RTM installs by default with Vault Server; download and install
the listed Cumulative Update. See Microsoft docs for Express edition limitations.

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2022 Standard/Datacenter<br>Windows Server 2025 Standard/Datacenter |
| CPU | 2 GHz+ (min) / 3 GHz+ (recommended) |
| Memory | 16 GB (min) / 32 GB (recommended) |
| Disk | 300 GB (min) / 500 GB (recommended) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 11 Professional/Enterprise |
| CPU | 1.6 GHz+ (min) / 3 GHz+ (recommended) |
| Memory | 4 GB (min) / 8 GB (recommended) |
| Disk | 10 GB (min) / 30 GB (recommended) |

### Thin (Web) Client

Browsers: Microsoft Edge, Google Chrome, Mozilla Firefox, Apple Safari

---

## Vault 2026

Article: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2026-products> (updated Feb 1, 2026)
Products: Vault Basic, Vault Professional

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter<br>Windows 10 Professional/Enterprise *(Vault Basic only)*<br>Windows 11 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2019 Express/Standard/Enterprise (CU29)<br>SQL Server 2022 Express\*/Standard/Enterprise (CU16) |
| Database — Full Replication | SQL Server 2019 Standard/Enterprise (CU29)<br>SQL Server 2022 Standard/Enterprise (CU16) |
| CPU — Single Site | 2.5 GHz+ (min) / 3 GHz+ (recommended) |
| CPU — Full Replication | 2.5 GHz+ (min) / 3.3 GHz+ (recommended) |
| Memory — Single Site | 8 GB (min) / 16 GB (recommended) |
| Memory — Full Replication | 16 GB (min) / 32 GB (recommended) |
| Disk — Single Site | 100 GB (min) / 200 GB (recommended) |
| Disk — Full Replication | 300 GB (min) / 500 GB (recommended) |

\* SQL 2022 Express RTM installs by default with Vault Server; apply the listed CU.

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter |
| CPU | 2 GHz+ (min) / 3 GHz+ (recommended) |
| Memory | 16 GB (min) / 32 GB (recommended) |
| Disk | 300 GB (min) / 500 GB (recommended) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 10 Professional/Enterprise<br>Windows 11 Professional/Enterprise |
| CPU | 1.6 GHz+ (min) / 3 GHz+ (recommended) |
| Memory | 4 GB (min) / 8 GB (recommended) |
| Disk | 10 GB (min) / 30 GB (recommended) |

### Thin (Web) Client

Browsers: Microsoft Edge, Google Chrome, Mozilla Firefox, Apple Safari

---

## Vault 2025

Article: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2025-products> (updated Mar 20, 2025)
Products: Vault Basic, Vault Professional

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter<br>Windows 10 Professional/Enterprise *(Vault Basic only)*<br>Windows 11 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2017 Express\*/Standard/Enterprise (CU31)<br>SQL Server 2019 Express/Standard/Enterprise (CU23)<br>SQL Server 2022 Express/Standard/Enterprise (CU10) |
| Database — Full Replication | SQL Server 2017 Standard/Enterprise (CU31)<br>SQL Server 2019 Standard/Enterprise (CU23)<br>SQL Server 2022 Standard/Enterprise (CU10) |
| CPU — Single Site | 2.5 GHz+ (min) / 3 GHz+ (recommended) |
| CPU — Full Replication | 2.5 GHz+ (min) / 3.3 GHz+ (recommended) |
| Memory — Single Site | 8 GB (min) / 16 GB (recommended) |
| Memory — Full Replication | 16 GB (min) / 32 GB (recommended) |
| Disk — Single Site | 100 GB (min) / 200 GB (recommended) |
| Disk — Full Replication | 300 GB (min) / 500 GB (recommended) |

\* SQL 2017 Express RTM installs by default with Vault Server; apply the listed CU.

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter |
| CPU | 2 GHz+ (min) / 3 GHz+ (recommended) |
| Memory | 16 GB (min) / 32 GB (recommended) |
| Disk | 300 GB (min) / 500 GB (recommended) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 10 Professional/Enterprise<br>Windows 11 Professional/Enterprise |
| CPU | 1.6 GHz+ (min) / 3 GHz+ (recommended) |
| Memory | 4 GB (min) / 8 GB (recommended) |
| Disk | 10 GB (min) / 30 GB (recommended) |

### Thin (Web) Client

Browsers: Microsoft Edge, Google Chrome, Mozilla Firefox, Apple Safari

---

## Vault 2024

Article: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2024-products> (updated Mar 28, 2024)
Products: Vault Basic, Vault Professional

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter<br>Windows 10 Professional/Enterprise *(Vault Basic only)*<br>Windows 11 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2016 Express/Standard/Enterprise (SP3)<br>SQL Server 2017 Express/Standard/Enterprise (CU31)<br>SQL Server 2019 Express/Standard/Enterprise (CU18, CU23) |
| Database — Full Replication | SQL Server 2016 Standard/Enterprise (SP3)<br>SQL Server 2017 Standard/Enterprise (CU31)<br>SQL Server 2019 Standard/Enterprise (CU18, CU23) |
| CPU — Single Site | 2.5 GHz+ (min) / 3 GHz+ (recommended) |
| CPU — Full Replication | 2.5 GHz+ (min) / 3.3 GHz+ (recommended) |
| Memory — Single Site | 8 GB (min) / 16 GB (recommended) |
| Memory — Full Replication | 16 GB (min) / 32 GB (recommended) |
| Disk — Single Site | 100 GB (min) / 200 GB (recommended) |
| Disk — Full Replication | 300 GB (min) / 500 GB (recommended) |

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2019 Standard/Datacenter<br>Windows Server 2022 Standard/Datacenter |
| CPU | 2 GHz+ (min) / 3 GHz+ (recommended) |
| Memory | 16 GB (min) / 32 GB (recommended) |
| Disk | 300 GB (min) / 500 GB (recommended) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 10 Professional/Enterprise<br>Windows 11 Professional/Enterprise |
| CPU | 1.6 GHz+ (min) / 3 GHz+ (recommended) |
| Memory | 4 GB (min) / 8 GB (recommended) |
| Disk | 10 GB (min) / 30 GB (recommended) |

### Thin (Web) Client

Browsers: Microsoft Edge, Google Chrome, Mozilla Firefox, Apple Safari

---

## Vault 2023

Article: <https://www.autodesk.com/support/technical/article/System-requirements-for-Autodesk-Vault-2023-products> (updated Mar 28, 2024)
Products: Vault Products (all editions)

### Vault Server

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2016 Standard/Datacenter<br>Windows Server 2019 Standard/Datacenter<br>Windows 10 Professional/Enterprise *(Vault Basic only)*<br>Windows 11 Professional/Enterprise *(Vault Basic only)* |
| Database — Single Site | SQL Server 2016 Express/Standard/Enterprise (SP3)<br>SQL Server 2017 Express/Standard/Enterprise (CU27, CU31)<br>SQL Server 2019 Express/Standard/Enterprise (CU13, CU23) |
| Database — Full Replication | SQL Server 2016 Standard/Enterprise (SP3)<br>SQL Server 2017 Standard/Enterprise (CU27, CU31)<br>SQL Server 2019 Standard/Enterprise (CU13, CU23) |
| CPU — Single Site | 2.5 GHz+ (min) / 3 GHz+ (recommended) |
| CPU — Full Replication | 2.5 GHz+ (min) / 3.3 GHz+ (recommended) |
| Memory — Single Site | 8 GB (min) / 16 GB (recommended) |
| Memory — Full Replication | 16 GB (min) / 32 GB (recommended) |
| Disk — Single Site | 100 GB (min) / 200 GB (recommended) |
| Disk — Full Replication | 300 GB (min) / 500 GB (recommended) |

### Vault File Server (File Replication)

| Item | Requirement |
| --- | --- |
| Operating System | Windows Server 2016 Standard/Datacenter<br>Windows Server 2019 Standard/Datacenter |
| CPU | 2 GHz+ (min) / 3 GHz+ (recommended) |
| Memory | 16 GB (min) / 32 GB (recommended) |
| Disk | 300 GB (min) / 500 GB (recommended) |

### Vault Client

| Item | Requirement |
| --- | --- |
| Operating System | Windows 10 Professional/Enterprise<br>Windows 11 Professional/Enterprise |
| CPU | 1.6 GHz+ (min) / 3 GHz+ (recommended) |
| Memory | 4 GB (min) / 8 GB (recommended) |
| Disk | 10 GB (min) / 30 GB (recommended) |

### Thin (Web) Client

Browsers: Microsoft Edge, Google Chrome, Mozilla Firefox, Apple Safari

---

## Cross-version quick comparison

### Vault Server operating systems

| Version | Windows Server | Desktop OS (Vault Basic only) |
| --- | --- | --- |
| 2027 | 2022, 2025 | Windows 11 |
| 2026 | 2019, 2022 | Windows 10, Windows 11 |
| 2025 | 2019, 2022 | Windows 10, Windows 11 |
| 2024 | 2019, 2022 | Windows 10, Windows 11 |
| 2023 | 2016, 2019 | Windows 10, Windows 11 |

### SQL Server support

| Version | Supported SQL Server versions (with CU/SP level) |
| --- | --- |
| 2027 | 2022 (CU18) |
| 2026 | 2019 (CU29), 2022 (CU16) |
| 2025 | 2017 (CU31), 2019 (CU23), 2022 (CU10) |
| 2024 | 2016 (SP3), 2017 (CU31), 2019 (CU18/CU23) |
| 2023 | 2016 (SP3), 2017 (CU27/CU31), 2019 (CU13/CU23) |

Express edition is supported for **Single Site** only — Full Replication requires
Standard or Enterprise.

### Hardware (unchanged across 2023–2027)

| Role | CPU min / rec | RAM min / rec | Disk min / rec |
| --- | --- | --- | --- |
| Vault Server — Single Site | 2.5 GHz / 3 GHz | 8 GB / 16 GB | 100 GB / 200 GB |
| Vault Server — Full Replication | 2.5 GHz / 3.3 GHz | 16 GB / 32 GB | 300 GB / 500 GB |
| Vault File Server — File Replication | 2 GHz / 3 GHz | 16 GB / 32 GB | 300 GB / 500 GB |
| Vault Client | 1.6 GHz / 3 GHz | 4 GB / 8 GB | 10 GB / 30 GB |

---

## Older versions

Autodesk publishes separate articles for Vault 2011–2022. Index:
<https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/System-requirements-for-Autodesk-Vault-products.html>

## Related Autodesk articles

- [Optimal Memory Configuration For Vault](https://www.autodesk.com/support/technical/article/Optimal-Memory-Configuration-For-Vault)
- [What is the recommended CPU configuration for Vault?](https://www.autodesk.com/support/technical/article/What-is-the-recommended-CPU-configuration-for-Vault)
- [Recommended server hardware configuration for Vault](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Recommended-server-hardware-configuration-for-Vault.html)
