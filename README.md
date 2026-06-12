# Vault Configuration Dashboard

A single‑file, offline tool for **documenting and reviewing an Autodesk Vault Pro
configuration**. It captures the settings a consultant or administrator needs to
hand off, review, or standardize a Vault deployment — and can read a real Vault
**Global Settings (`.cfg`)** export, edit it, and write key sections back out so
the file re‑imports into Vault.

> The whole tool is one HTML file: **`vault-config-dashboard.html`**. No install,
> no server, no internet connection required. Open it in any modern browser.

---

## What it's for

- **Document a Vault configuration** in a clean, structured, printable form.
- **Review / audit** an environment by loading its real `.cfg` and walking the sections.
- **Standardize** new deployments from a known‑good baseline.
- **Hand off** a configuration as a polished multi‑page **PDF** and/or a portable JSON file.

It is a **documentation and editing aid**, not a live connection to Vault. Nothing
it shows is pushed to a server automatically — see *Data & privacy* below.

---

## What's in it

The left sidebar covers the configuration areas:

| Section | What it captures |
|---|---|
| **Overview** | Vault details, third‑party connectors/integrations, completion progress |
| **Server & Database** | Server, file store, database, Job Processor, Thin Client |
| **Users & Groups** | Vault users and groups (with roles) |
| **Roles & Permissions** | Roles in the Vault |
| **Security Policies** | Password policy |
| **Lifecycles** | Lifecycle workflow editor — state/transition **flowchart**, per‑state security, and per‑transition settings (criteria, actions, jobs, security, peer review, email) |
| **Categories** | File / Folder / Item / Custom Object category definitions |
| **Category Rules** | Auto‑assignment rules per entity type |
| **Revision Schemes** | Revision scheme definitions and value‑list sequences |
| **Numbering Schemes** | File numbering schemes |
| **Revision Table** | Drawing revision‑table control: column mappings, content, filters (documented) |
| **Property Definitions** | Properties (System vs UDP) and their content‑source mappings |
| **Folder Structure** | Planned folder tree, with library‑folder marking |
| **CAD Integration** | CAD applications and per‑app workspace |
| **Email & Notifications** | Vault email (SMTP) configuration |
| **Vault Connector (Fusion Manage)** | Tenant, property mappings, attachment options, state mappings |
| **Backup & Restore** | Backup settings and script |
| **General Settings** | File‑handling options (unique names, duplicate search, trash bin, etc.) |
| **Notes & Change Log** | Free‑form notes and a change log |
| **Manual Checklist** | Punch list of settings the `.cfg` can't apply — must be set by hand in Vault |

---

## Getting started

1. Open **`vault-config-dashboard.html`** in a browser (double‑click it, or use the hosted URL if your team publishes it).
2. The dashboard opens with **sample data** so you can explore.
3. Edit fields directly, or **load a real configuration** (next section).
4. Save your work in the browser with **💾 Save**, or export it (see *Exporting*).

Your data lives only in **your browser** until you export it. Use **↺ Reset** to
return to the shipped sample data.

---

## Loading real Vault data

Use **📂 Load Data** (top right). Three formats are accepted:

1. **Vault `.cfg` (Global Settings export)** — produced in the Vault client via
   **File ▸ Export**. This is the richest source: lifecycles, properties,
   categories, revision schemes, numbering, category rules, and property mappings
   are all read in. When a `.cfg` is loaded, an **⬇ Export .cfg** button appears
   (see below).
2. **This dashboard's own JSON** — a file previously created with **⬇ Download Current as JSON**.
3. **Raw Vault API output** — JSON produced by the included PowerShell script.

**Replace toggle** (next to Load Data):
- **On** — sections missing from the file are cleared (clean full replace).
- **Off** — merge; current data is kept for sections the file doesn't contain.

> Users & Groups are environment‑specific and are **not** carried in a `.cfg`, so
> they are never cleared by a `.cfg` import.

---

## Exporting

- **⬇ Download Current as JSON** — portable snapshot for re‑loading into the dashboard.
- **⬇ Export .cfg** *(only shown after loading a `.cfg`)* — preserves the original
  package and patches your edits back into the relevant XML sections so the file
  **re‑imports into Vault**. A reminder dialog lists exactly what the `.cfg` will
  and won't update.
- **🖨 Print / PDF** — generates a stylized, multi‑page configuration document
  (cover sheet + each section). System‑default objects are omitted to keep it focused.

---

## Manual checklist (what the `.cfg` can't apply)

The Global Settings `.cfg` only carries a subset of a Vault configuration
(properties, lifecycles, categories, category rules, revision/numbering schemes,
property mappings). Many other settings live in the Vault database or in connector
add‑ins and must be applied **by hand** after importing the `.cfg`.

The **Deployment ▸ Manual Checklist** page lists those items — Users & Groups,
Roles, Security policy, Folder structure, Server/Database/Job Processor, CAD
integration, Email (SMTP), Connectors, the Fusion Manage connector, Backup,
General Settings, and lifecycle transition extras (Custom Job Types, Peer Review,
Email Notifications, State‑based Security).

- Each item has a **checkbox** (progress is saved with the configuration) and a
  **link to jump to that section** of the dashboard.
- The checklist is included in the **PDF** as a go‑live punch list (☑/☐ per item).

---

## The PowerShell script (optional)

**`Export-VaultConfig.ps1`** is a convenience extractor. It runs on **Windows**
against an **ADMS / Vault server** (Vault API) and writes a JSON file you then
load into the dashboard.

- Most team members **don't need it** — the built‑in `.cfg` import covers the same ground.
- It supports selective export (`-Include` / `-Exclude` / `-Interactive`) so you can
  choose which sections to pull.
- Hand it only to whoever does live extraction, along with access to the Vault server.

---

## Data & privacy

- 100% client‑side. Data is held in the browser (local storage / in‑memory) and in
  files you explicitly export.
- **Nothing is uploaded** anywhere. There is no backend.
- Avoid putting secrets you don't want shared (e.g., service passwords) into a file
  you then commit or distribute. The email section intentionally omits password fields.

---

## Distribution

- The tool is the **single file `vault-config-dashboard.html`** — copy it anywhere
  (repo, file share, intranet) and it works.
- Updates are a **drop‑in replacement**: replace the one file.
- The build stamp in the sidebar footer and on the PDF cover (e.g. `v1.2 · Build 2026.06.12`)
  identifies which copy someone is running — handy when reporting issues.

---

## Repository contents

| File | Purpose |
|---|---|
| `vault-config-dashboard.html` | The dashboard (the deliverable). |
| `Export-VaultConfig.ps1` | Optional PowerShell extractor (Vault API → JSON). |
| `index.html` | Lightweight redirect to the dashboard (for static hosting). |
| `README.md` | This document. |

---

## Versioning

The version/build is set in `vault-config-dashboard.html`:

```js
const APP_VERSION='1.2';
const APP_BUILD='2026.06.12';   // YYYY.MM.DD
```

Bump these when publishing an updated copy to the team. The label updates
automatically in the sidebar and on the PDF cover.
