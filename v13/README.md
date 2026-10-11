# Foundry V13 Dependencies

The V13 companion project lives here separately from the V14 files at the repository root.

**Target only:** `~/Library/Application Support/FoundryVTT/Data/modules` (not `FoundryVTTV14`).
**Scope:** public-manifest add-on dependencies. No campaigns, worlds, game systems, maps or actors.

## Install
After the [v13dependencies.zip](./v13dependencies.zip) artifact has been built, install this package into Foundry V13 using this manifest:

`https://raw.githubusercontent.com/Quarky/v14dependencies/main/v13/module.json`

It uses Foundry's normal dependency prompt to install the four registered add-ons, or you can download/unzip the ZIP and run `./install.sh` (no args) or double-click `Install.command` on macOS. Default installer skips already installed add-ons; `./install.sh --update` replaces them with timestamped backups and rollback, and `./install.sh --check` checks remote manifests without installing.

**Important:** Complete Card Management **2.1.2** is the last listed V13 release and requires V13 build **351 or later**; do not install V14-only **3.0.3** into V13.

## Export all installed modules

Double-click `Export-Module-Inventory.command` from the unzipped bundle, or run `python3 export_modules.py`. This writes two JSON files to Desktop:

- `foundry-v14-installed-modules.json`
- `foundry-v13-installed-modules.json`

They include all installed module IDs, titles, versions, compatibility, manifests, and required/recommended module relationships. The files do not report which modules are enabled in individual worlds. Check custom URLs for embedded tokens before sharing.

## Initial mappings

| Add-on | Registered V14 release | V13-compatible release |
|---|---|---|
| CZEPEKU Universe | 1.0.0 | 1.0.0 (Foundry 12–14; subscription required) |
| Cartorium Archive | 1.0.8 current | 1.0.8 (Foundry 13–14) |
| Complete Card Management | 3.0.3 | **2.1.2** (Foundry 13.351+) |
| Card Hands List | 2.2.7 | 2.2.7 (Foundry 13–14) |

The V13 registry pins publisher versions and refuses later manifests that stop supporting V13. Future expansions need the user's actual V14 inventory JSON; don't assume the four listed here are their complete installation.

Sources: https://foundryvtt.com/packages/czepeku · https://foundryvtt.com/packages/cartorium-browser · https://foundryvtt.com/packages/complete-card-management · https://foundryvtt.com/packages/card-hands-list
