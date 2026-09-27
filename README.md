# Foundry V14 Dependencies

Running dependency and curated-map installer repository for Foundry VTT v14.

Default local Foundry data root used by the installer:

`/Users/somed/Library/Application Support/FoundryVTTV14`

Modules directory:

`/Users/somed/Library/Application Support/FoundryVTTV14/Data/modules`

## Current bundled utility

### Skyhorn curated additive maps

Internal module ID:

`northern-fjord-curated-maps-v14`

Visible title:

**Skyhorn — Curated Additive Maps**

The module is intentionally additive and non-destructive:

- Does not delete or replace existing campaign maps.
- Does not overwrite the main Skyhorn/Northern Fjord campaign module.
- Scans installed Scene compendia from supported map-source modules.
- Scores only Skyhorn/Northern Fjord-relevant maps.
- Imports selected scenes into a separate **Skyhorn — Curated Additive Maps** folder.
- Stores source UUID flags and skips already imported maps.
- Uses per-pack and per-scene try/catch so one broken source pack cannot stop the rest.
- Provides GM macros for preview, import, and dependency/source reporting.

The curated terms cover the campaign locations already established in the project: fjord harbor, docks, ships, taverns/inns, lighthouse/towers, cliffs/coast, sea caves, fishing settlements, roads/mountain passes, frozen ruins, tide pools/shoreline, shrines, guard/barracks, smuggler sites, ice fields, and underwater/reef encounters.

## Running dependency installer

Run:

```bash
chmod +x install.sh
./install.sh
```

or double-click `Install.command` on macOS.

The installer:

1. Installs/updates the local curated-map module from this checkout using a staged move.
2. Checks the configured v14 map-source packages.
3. Automatically installs public-manifest dependencies when safe to do so.
4. Reports Foundry-exclusive / Marketplace / subscription-gated packages that must be installed through their normal provider or Foundry Setup UI.
5. Never removes unrelated modules.

Use `./install.sh --update` to refresh auto-installable dependencies that are already present.

## Source registry

The running source list is in `dependencies-v14.json`.

Current Skyhorn-relevant source families include:

- CZEPEKU Universe
- Miska's Maps
- Moonlight Maps
- Tom Cartos Into the Wilds
- Tom Cartos Ostenwold
- The MAD Cartographer tavern packs

More v14-compatible source modules can be added to the JSON registry and importer without changing the existing campaign maps.
