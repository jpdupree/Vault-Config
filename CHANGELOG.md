# Changelog — Vault Configuration Dashboard

All notable changes to `vault-config-dashboard.html`. Dates are `YYYY-MM-DD`.

---

## v1.4 — 2026-06-16

**Theme: reliable `.cfg` round-trip into a fresh/target vault, plus a one-click pre-flight.**

This release closes a series of import failures that surfaced when re-importing
an edited (or merged) `.cfg` back into Vault, and adds a **Validate** button that
catches those problems before you export.

### Added
- **Manual Checklist: property “Required” flags** — added a checklist item noting
  that a property’s Required/mandatory setting isn’t carried by the `.cfg` and must
  be set per category in Vault. (List/enumerated property values *do* carry.)
- **Validation: non-portable user ACEs** — Validate now warns when lifecycle
  state or transition security grants to a **user** (not a group); user accounts
  are environment-specific and Vault drops them on `.cfg` import.
- **Delete-first lifecycle note** — the Export `.cfg` dialog and the Manual
  Checklist now flag that Vault won't overwrite an existing lifecycle on import
  (delete or rename it in Vault first, or the change is a no-op).
- **Content Center Libraries** section (under Structure) — lists the Inventor
  Content Center libraries loaded into the vault, each with a **Type**
  (Standard / Custom) and a free‑text **Notes** field (e.g. which release years
  are loaded), plus **+ Add Library** and **Load Defaults** (the standard Inventor
  set). Documentation only (loaded via ADMS, not the Global Settings `.cfg`);
  included in the PDF.
- **✓ Validate** toolbar button + results dialog — pre-flights the whole config
  for references Vault rejects on import (bad criteria values, categories pointing
  at undefined lifecycles/revisions, rules targeting missing categories,
  system/undefined category properties, duplicate category names). **Errors** block
  the `.cfg` export and are listed with their exact location; **warnings** are
  cleaned up automatically on export. The **Export .cfg** path runs the same checks.

### Fixed
- **State security: grant model** — the State Security editor now uses a **grant
  checkbox** per permission (Read/Modify/Delete/Download) instead of an
  —/Allow/Deny dropdown. Vault state ACEs are grant-only and *exclusive*, so the
  old "Deny"/blank options were misleading (both exported as "not granted", which
  reads as a deny). Rows that grant nothing are now **dropped on export** so a
  listed-but-empty group can't become an accidental deny-all.
- **State security: User vs Group flag** — the State Security editor now has an
  **Is Group** column (matching transition security), and hand-added entries default
  to a group. Previously every manually added state ACE exported as `IsGroup="false"`
  (a user), so group-targeted state ACLs wouldn't bind on import. Entries read from a
  `.cfg` already preserved the flag; this closes the editor-side gap.

### Fixed — import errors (`ConfigurationError [232]` family)
- **Lifecycle criteria → `nvarchar→float`** — transition criteria RuleSets are now
  preserved verbatim from the source `.cfg` (the rebuild was dropping per-rule
  data-type context). Numeric criteria are also validated in the editor and on export.
- **Category properties → `UnknownBehavior` (e.g. `CreateDate`, `pre`)** — system
  properties and undefined property names can no longer be assigned to a category;
  they're blocked in the picker, flagged on existing chips, and dropped on export.
- **Category lifecycle/revision → `UnknownBehavior`** — category behavior references
  are resolved to defined lifecycles/revision schemes (by friendly or internal name)
  and written without stale/duplicate entries; danglers block export with a clear message.
- **Category dropdown losing its value** — lifecycle/revision selects bind reliably
  even for names containing special characters (e.g. `Library & Hardware Lifecycle`).
- **Category rules → `UnknownCategory`** — rules are validated against defined
  categories before export.
- **Custom category internal name (GUID)** — preserved end-to-end so category
  definitions and the rules that reference them stay in sync (`UnknownCategory`).
- **`EntityClassSupportedBehavior` not updated** — the exporter now registers every
  category **and** the lifecycle, revision scheme, and properties it references under
  the correct entity class. This fixes both `UnknownCategory` and
  *"category … references behaviors that are not associated to the Entity Class."*
- **Duplicate category (`Category already exist`)** — categories are de-duped in the
  model (keeping the most-configured entry, so no work is lost) and on export. **Merge
  remains fully available** — it just no longer accumulates duplicates.

### Notes
- Merging the dashboard's sample data with a real `.cfg` (Replace **off**) is fully
  supported; the export now self-heals the references a fresh vault wouldn't know about.
- Recommended workflow: **✓ Validate → ⬇ Export .cfg**. Green means it will import.

---

## v1.3 — 2026-06-12

### Added
- **Revision Table Settings** section (under Behaviors), gated by *Enable Revision
  Table control*, with Mappings/Content/Filters and a **Load Defaults** button.
- **Per-category property list** — expandable categories with a searchable property
  picker, kept alphabetical, with copy/paste of a property set.
- **Property value lists** (UDP `ValueList`) — display, edit, and write-back.
- **Help & Docs** in-app page; **README** and **Quick Start** guides.
- Lifecycle editor: **drag-to-reorder** state cards; **Import JSON** browses for a file;
  export/import carries all state securities and transition settings.
- Fusion connector **State Mappings**: *Use state transition* toggle, multi-select
  **Vault Action** dropdown, and change-order default mappings.

### Fixed
- **Lifecycle export `FileLinkTypeEnum`** — no longer writes invalid `Released`/`Tertiary`
  values (Vault import error 232).
- Custom lifecycles, revision schemes/sequences, and category rules no longer import
  as System with GUID names — friendly names are preserved via `rawName`.

### Changed
- State-based security: only the checkbox toggles it (not the whole row).
- Removed the non-visible *Update Items* toggle from transition Actions (still written to cfg).

---

_For older history, see the git commit log._
