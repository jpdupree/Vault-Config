# Quick Start — Vault Configuration Dashboard

A 5‑minute guide to using the tool. For full details see [README.md](./README.md).

---

## 1. Open it

Open **`vault-config-dashboard.html`** in any modern browser (Chrome, Edge, Firefox).
Double‑click the file, or use your team's hosted link. Nothing to install.

It opens with **sample data** so you can click around safely.

---

## 2. Load your Vault configuration

Click **📂 Load Data** (top right) and pick one of:

- **A Vault `.cfg`** — export it from the Vault client: **File ▸ Export** (Global Settings). *Best option — pulls in the most data.*
- **A dashboard JSON** — a file you previously downloaded from this tool.
- **PowerShell JSON** — output from `Export-VaultConfig.ps1`.

**Replace toggle** (next to Load Data):
- **Off (merge)** — keeps existing data for anything the file doesn't include. *Use this most of the time.*
- **On (replace)** — clears sections missing from the file for a clean slate.

---

## 3. Review & edit

Use the left sidebar to move through the sections. Everything is editable inline:

- Type into fields, toggle switches, add/remove rows.
- **Lifecycles** has a visual flowchart editor — click a state or transition arrow to edit its settings below the diagram.
- **Property Definitions** — click a property to expand its mappings.

The **Overview** page shows completion bars so you can see what's still blank.

---

## 4. Save your work

- **💾 Save** — keeps your work in this browser (survives refresh/close).
- **↺ Reset** — discards changes and returns to sample data.

> Your data stays in your browser. Nothing is uploaded.

---

## 5. Export / hand off

- **⬇ Download Current as JSON** — a portable file you (or a teammate) can re‑load later.
- **⬇ Export .cfg** — *appears after you load a `.cfg`.* Writes your edits back into the
  original package so it **re‑imports into Vault**. A dialog explains what it will/won't update.
- **🖨 Print / PDF** — a polished, multi‑page configuration document (cover sheet + sections).
  In the print dialog choose **Save as PDF**.

---

## Common tasks at a glance

| I want to… | Do this |
|---|---|
| Document a brand‑new Vault | Start from sample data, edit each section, then **Download JSON** / **Print PDF** |
| Review an existing Vault | **Load Data** → its `.cfg` (Replace **on**), walk the sidebar |
| Continue earlier work | **Load Data** → your saved dashboard JSON |
| Update Vault from my edits | Load the `.cfg`, edit, **Export .cfg**, import it back in the Vault client |
| Produce a hand‑off document | **Print / PDF** → Save as PDF |
| Track manual setup steps | Open **Deployment ▸ Manual Checklist** and check items off |

---

## Good to know

- **Single file** — the whole tool is `vault-config-dashboard.html`. Copy it anywhere.
- **Offline** — no internet or server needed.
- **Version** — the build stamp (e.g. `v1.3 · Build 2026.06.12`) is in the sidebar footer and on the PDF cover; quote it if you report an issue.
- **Users & Groups** are environment‑specific and are **not** included in a `.cfg`, so a `.cfg` import won't touch them.
- **Not everything is in the `.cfg`.** After importing, use **Deployment ▸ Manual Checklist** — it lists the settings you must apply by hand in Vault (users, roles, folders, email, connectors, etc.), with a link to each section and a checkbox to track progress. It also prints in the PDF.
