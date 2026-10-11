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

The V13 dependencies project has its **own repository**: [Quarky/V13dependencies](https://github.com/Quarky/V13dependencies), with a V13 manifest, pinned dependency registry, installer, and module inventory exporter.

- [V13 manifest](https://raw.githubusercontent.com/Quarky/V13dependencies/main/module.json)
- [V13 registry](https://github.com/Quarky/V13dependencies/blob/main/dependencies-v13.json)
- [V13 ZIP](https://github.com/Quarky/V13dependencies/blob/main/v13dependencies.zip)
- [V13/V14 installed-module JSON exporter](https://github.com/Quarky/V13dependencies/blob/main/export_modules.py)

**The older `v13/` subfolder in this repository is superseded; use Quarky/V13dependencies as the canonical V13 source.** V14 installers continue to use only the V14 files at this repository's root.
