# Changelog — Vault Configuration Dashboard

All notable changes to `vault-config-dashboard.html`. Dates are `YYYY-MM-DD`.

---

## Unreleased

### Fixed
- **Stale entity-class registrations never cleared on export** — the ESB patcher only
  ever *added* to the entity-class behavior lists, so a bad entry from a previous
  (polluted) export — e.g. a category or its item lifecycle wrongly under FileMaster —
  survived even after the category was reclassified or deleted in the model, and kept
  failing the import. Export now reconciles each entity class to the model: the category
  list is exactly the model's categories of that type (stale/reclassified ones removed,
  guarded against an empty model), and a lifecycle/revision that a category uses under a
  *different* entity class is stripped from this one (a behavior no category uses is left
  alone as still-available). A category registered under more than one entity class is
  classified to the class where it's the **default** (e.g. Document is the default Item
  category), then by which class's lifecycles it actually uses, then File — with the
  per-category Entity selector to override.

### Fixed
- **Category on wrong entity class → `ConfigurationError [232]` ("Category.X cannot be
  added to the Entity Class … references behaviors that are not associated")** — a
  category with no assignment rule (e.g. the standard **Document** item category) was
  defaulting to the generic `File` entity type, so the exporter wrote it under
  FileMaster where its item lifecycle isn't valid and Vault aborted. Category entity is
  now classified from the authoritative **EntityClassSupportedBehavior** section (which
  class actually lists the category, with a lifecycle-aware tie-break for categories
  registered under more than one), falling back to rules/name/File only when the ESB is
  silent. On export, a category is also **removed** from any entity class the model no
  longer classifies it under, and behaviors are registered only for correctly-typed
  categories — so a stale/misplaced registration self-heals. Added a per-category
  **Entity type** selector so a misclassified category can be reassigned in the UI.

### Fixed (previous attempt, superseded above)
- **Category behaviors not associated with entity class (`ConfigurationError [232]` /
  "Category.X cannot be added to the Entity Class … references behaviors that are not
  associated")** — `EntityClassSupportedBehavior` was rebuilt from the in-memory model,
  which can diverge from what `Category.xml` actually references (e.g. a behavior
  preserved from the cloned source category node that the model doesn't track). The
  exporter now takes an authoritative pass over the just-patched `Category.xml` and
  registers every behavior each category references — across all behavior classes, not
  just lifecycle/revision/UDP — so nothing a category points at is left unassociated.
  It only adds what's missing (over-association is harmless; only under-association
  fails the import).
- **Revision scheme → missing sequence (`RevisionSequenceNotExist [3409]`)** — Validate
  and Export now catch a revision scheme whose Primary/Secondary/Tertiary points at a
  revision sequence that isn't defined (e.g. the sequence was deleted or renamed while
  a scheme still referenced it). Previously the exporter wrote the dangling reference
  blindly and Vault aborted the entire import when validating the Revision section.
  The Revision Schemes dropdowns now also show a `⚠ … (missing)` option instead of
  silently falling back to “None”, so the broken reference is visible and fixable.
- **Revision scheme → sequence match is now whitespace/case-tolerant** — a scheme
  reference could drift from its sequence by stray whitespace or case (e.g. a
  sequence deleted and re-created with a re-typed name). Because `<option>` values
  are whitespace-stripped, exact-equality matching stranded the reference even after
  re-selecting the sequence in the dropdown — so Validate kept flagging it and export
  kept failing. Matching (dropdown selection, Validate, and export resolution) now
  trims and case-folds, so the reference resolves to the real sequence and the export
  writes a consistent internal name.

### Added
- **Vault Upgrade page** (Deployment → ⬆️ Vault Upgrade) — captures the full upgrade
  assessment from the Symetri upgrade project plan (ADMS server, SQL, current Vault,
  accounts/services, sizing, backup, apps, clients, Job Processor, Symetri needs), a
  **Target Version** picker (Basic/Professional × 2024–2027), and a **Check System
  Requirements** button that compares the captured environment against the target
  release's requirements — OS (flags a server move when unsupported), SQL version,
  SQL Express size limit, remote-SQL-with-Basic, RAM, C:\ and data-drive space,
  upgrade-path gap (intermediate versions), and Pro→Basic downgrade — with a per-item
  pass/warn/fail table and the specific change needed. Requirements live in a
  `VAULT_SYSREQ` data table covering **2011–2027**. 2024–2027 are from Autodesk's
  official per-year system requirements articles (verified Aug 2026): 2024 = Server
  2019/2022 + SQL 2017/2019 (no SQL 2022); 2025 = Server 2019/2022 + SQL
  2017/2019/2022; 2026 = Server 2019/2022 + SQL 2019/2022; 2027 = Server 2022/2025 +
  SQL 2022 only. 2011–2023 are historical best-effort (marked * — verify before a
  stepped upgrade). OS/SQL matching understands "R2" versions (Server/SQL 2008 R2 vs
  2008) and legacy client OSes (XP/Vista/7/8/8.1). The upgrade-path check enforces
  Vault's **max 2 releases per migration hop** (e.g. 2020→2022): a bigger jump fails
  with the required stepping ladder (e.g. 2015 → 2017 → 2019 → 2021 → 2023 → 2025 →
  2027) and a per-hop table of each intermediate version's supported OS/SQL, with a
  note that old hops may need a temporary VM when no supported overlap exists.
  Seven expandable **upgrade runbooks** (Basic notes/in-place; Professional in-place,
  server move, filestore replication, full replication, replication server move) with
  per-step checkboxes; progress and all fields persist with the configuration.
- **Properties: Basic Search flag** — new **Basic Search** column on Property
  Definitions (click to toggle). Read from and written back to the `.cfg`
  (`BasicSearch` attribute); **new/duplicated properties default to ON**. Configs
  saved before the flag existed don't clobber the original attribute on export.
- **Vault Connector: default property mappings updated** — now includes
  `Revision → PDM_ITEM_REVISION` (Item) and `State → PDM_STATUS_NAME` (Item)
  alongside the previous defaults, matching the Vault Connector Configurations
  dialog. Added a **⤓ Load Defaults** button to the Property Mappings table so an
  existing saved config can pick up the new defaults.
- **Thin Client (Web Client) page** (Integrations) — Administrator Settings → Files
  toggles (Hide Files workspace, Make default landing page, Show released files only,
  Show latest version of file only) plus a **Notes** field. Gated by a new **Thin
  Client (Web Client)** checkbox in Overview → Connections & Integrations: the page
  (and nav item) only appear when it's ticked, mirroring the Fusion connector. Prints
  to the PDF when enabled. Applied in the Thin Client admin UI, not the `.cfg`.

### Changed
- **Nav order** — the **Lifecycles** item now sits after **Categories** and
  **Category Rules** under Behaviors.
- **Default backup script** replaced with the three-generation cascade routine
  (Temp → A → B) that logs to `VaultBackup.log`, closes the ADMS console, runs
  `Connectivity.ADMSConsole.exe -Obackup` with `-DBSC -IVAL`, and only rotates the
  generations on success (resetting `Temp` on failure). Applies to fresh/sample
  loads; existing saved configs keep their stored script.

### Added
- **Database Growth page** (Maintenance → 📈 Database Growth) — record the total
  Vault SQL database size, individual database sizes (one row per vault/ADMS DB),
  and the file store size with a date. Each measurement is plotted on a line chart
  so you can watch growth and plan capacity, with a history table and **Download
  CSV**. Database names carry forward to the next entry; re-recording a date updates
  it. Data is stored in this browser and in saved/exported JSON (kept across `.cfg`
  imports) but is *not* written to the Vault `.cfg` — it's operational telemetry.

## v1.4 — 2026-06-16

**Theme: reliable `.cfg` round-trip into a fresh/target vault, plus a one-click pre-flight.**

This release closes a series of import failures that surfaced when re-importing
an edited (or merged) `.cfg` back into Vault, and adds a **Validate** button that
catches those problems before you export.

### Added
- **Properties: list-value count badge** — a property row now shows a `📋 N` badge
  when it has list/enumerated values, so they're visible without expanding. (The
  dedicated **List Values** editor already exists in the expanded row — values
  round-trip in the `.cfg`.)
- **Manual Checklist: property initial value / required + per-user security** — a
  property’s initial/default value and Required flag aren’t modeled or written to
  the `.cfg`; and per-user object/folder ACLs are environment-specific. Both added
  as hand-apply checklist items. (List values *do* carry.)
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
