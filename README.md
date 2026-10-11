# Foundry V14 Dependencies

This repository is only for **automatic dependency installation and updating** for the user's Foundry VTT v14 setup.

It does **not** contain campaign modules, curated map modules, adventures, actors, PCs, or campaign assets.

Default Foundry v14 root:

`/Users/somed/Library/Application Support/FoundryVTTV14`

Default modules directory:

`/Users/somed/Library/Application Support/FoundryVTTV14/Data/modules`

## Usage

Run `install.sh` or double-click `Install.command` on macOS. Use `./install.sh --update` to refresh registered dependencies.

## Registry

`dependencies-v14.json` contains only dependencies that can be installed automatically from a direct/public Foundry-compatible manifest. Campaign packages that use them are distributed separately with their own installer.

Current auto-installable dependencies:

- **CZEPEKU Universe** — optional map source.
- **Cartorium Archive** — optional map-source browser.
- **Complete Card Management 3.0.3** — card canvas/table management; system agnostic; requires Foundry 14.365+ and is verified for Foundry 14.
- **Card Hands List 2.2.7** — card-hand UI; system agnostic; supports Foundry 13-14 and is verified for Foundry 14; integrates with Complete Card Management.

The card modules are suitable for the project's **Foundry v14 + D&D5e 5.3.3** setup because both card modules are system agnostic rather than depending on D&D5e internals.

Provider accounts or subscriptions may still be required for provider-gated content; the dependency installer only installs the Foundry module itself.

More auto-installable v14 dependencies can be appended as needed.

## Foundry V13 companion (separate)

A separate **Foundry V13 Dependencies** module is maintained under [`v13/`](./v13/README.md), with its own `v13dependencies` module ID, V13-compatible pinned manifest URLs, ZIP, safe no-argument installer, and JSON exporter for all installed V13/V14 modules. It installs into `~/Library/Application Support/FoundryVTT/Data/modules`, **not** the V14 data folder. The V14 dependency registry and manifest here at the repository root remain unchanged.

- [V13 dependency registry](./v13/dependencies-v13.json)
- [V13 module manifest](./v13/module.json)
- [V13 module ZIP](./v13/v13dependencies.zip)
- [Export installed V13 and V14 modules to JSON](./v13/export_modules.py)
