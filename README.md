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

Current registry:

- **CZEPEKU Universe** — Foundry v14 verified. The module can be installed from its public manifest. Access to its map library still requires the user's Czepeku account/subscription.

More auto-installable v14 dependencies can be appended as needed.
