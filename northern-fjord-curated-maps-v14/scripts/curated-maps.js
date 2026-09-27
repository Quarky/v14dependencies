const MODULE_ID = "northern-fjord-curated-maps-v14";
const SOURCE_FLAG = "sourceSceneUuid";
const ROOT_FOLDER = "Skyhorn — Curated Additive Maps";

const PROVIDERS = [
  { ids:["miskasmaps"], match:["miska"], label:"Miska's Maps", maxScenes:14 },
  { ids:["moonlight-maps-free"], match:["moonlight maps"], label:"Moonlight Maps", maxScenes:16 },
  { ids:["tomcartos-into-the-wilds-maps"], match:["into the wilds","tom cartos"], label:"Tom Cartos — Into the Wilds", maxScenes:16 },
  { ids:["tomcartos-ostenwold"], match:["ostenwold"], label:"Tom Cartos — Ostenwold", maxScenes:16 },
  { ids:["mad-taverns","mad-taverns2"], match:["mad cartographer","taverns map pack"], label:"The MAD Cartographer", maxScenes:12 },
  { ids:["czepeku"], match:["czepeku"], label:"CZEPEKU Universe", maxScenes:20 }
];

const CATEGORY_RULES = [
  { key:"harbor-docks", label:"Harbor & Docks", max:8, terms:["harbor","harbour","dock","docks","pier","wharf","quay","shipyard","boat","ship","vessel","fishing","coastal village","port"] },
  { key:"taverns-inns", label:"Taverns & Inns", max:8, terms:["tavern","inn","pub","alehouse","taproom","bar","common room"] },
  { key:"lighthouse-towers", label:"Lighthouse & Towers", max:8, terms:["lighthouse","beacon","tower","watchtower","signal tower","cliff tower"] },
  { key:"coast-roads", label:"Coast, Roads & Passes", max:8, terms:["coast","coastal","shore","shoreline","cliff","fjord","road","trail","mountain pass","pass","bridge","causeway","beach","tidepool","tide pool"] },
  { key:"caves-underwater", label:"Caves & Underwater", max:8, terms:["sea cave","cave","cavern","grotto","underwater","reef","sunken","shipwreck","wreck","coral"] },
  { key:"villages-town", label:"Village & Town", max:8, terms:["village","town","hamlet","market","fish market","town square","village outskirts","nordic","winter village","coastal village"] },
  { key:"ruins-shrines", label:"Ruins & Shrines", max:8, terms:["ruin","ruins","shrine","relic","temple","fortress","fort","old tower","abandoned"] },
  { key:"winter-wilderness", label:"Winter & Wilderness", max:8, terms:["winter","snow","frozen","ice","sleet","storm","arctic","mountain","pine","forest road","ice field"] },
  { key:"guards-smugglers", label:"Guards & Smugglers", max:8, terms:["barracks","guard","watch","smuggler","hideout","camp","warehouse","storehouse","customs"] }
];

const NEGATIVE_TERMS = [
  "sci-fi","scifi","spaceship","spaceport","cyberpunk","modern city","desert","jungle","volcano","lava","hell","astral","starship","laboratory"
];

function norm(v) {
  return String(v ?? "").normalize("NFKD").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

function packageId(pack) {
  return pack?.metadata?.packageName ?? pack?.metadata?.package ?? pack?.metadata?.packageId ?? "";
}

function moduleValues() {
  return Array.from(game.modules?.values?.() ?? []);
}

function resolveProviderModules(rule) {
  const found = new Map();
  for (const id of rule.ids ?? []) {
    const mod = game.modules.get(id);
    if (mod) found.set(id, mod);
  }
  const needles = (rule.match ?? []).map(norm).filter(Boolean);
  for (const mod of moduleValues()) {
    const hay = norm(`${mod.id} ${mod.title ?? mod.data?.title ?? ""}`);
    if (needles.some(n => hay.includes(n))) found.set(mod.id, mod);
  }
  return [...found.entries()].map(([id, mod]) => ({id, mod}));
}

function classify(name) {
  const n = norm(name);
  if (NEGATIVE_TERMS.some(t => n.includes(norm(t)))) return null;
  let best = null;
  for (const cat of CATEGORY_RULES) {
    let score = 0;
    for (const term of cat.terms) {
      const t = norm(term);
      if (n.includes(t)) score += 10 + Math.max(0, t.split(" ").length - 1) * 2;
    }
    if (!best || score > best.score) best = {category:cat, score};
  }
  if (!best || best.score <= 0) return null;
  return best;
}

function scenePacksFor(moduleIds) {
  const ids = new Set(moduleIds);
  return game.packs.filter(p => p.documentName === "Scene" && ids.has(packageId(p)));
}

async function ensureFolder(name, parent=null) {
  const parentId = parent?.id ?? parent ?? null;
  let folder = game.folders.find(f => f.type === "Scene" && f.name === name && (f.folder?.id ?? f.folder ?? null) === parentId);
  if (!folder) folder = await Folder.create({name, type:"Scene", folder:parentId, sorting:"a"});
  return folder;
}

async function findCandidates() {
  const candidates = [];
  for (const provider of PROVIDERS) {
    const active = resolveProviderModules(provider).filter(x => x.mod.active);
    if (!active.length) continue;

    const packs = scenePacksFor(active.map(x => x.id));
    const providerRows = [];

    for (const pack of packs) {
      let index;
      try {
        index = await pack.getIndex({fields:["name"]});
      } catch (error) {
        console.warn(`[Skyhorn Curated Maps] Could not index ${pack.collection}`, error);
        continue;
      }

      for (const entry of index) {
        const hit = classify(entry.name);
        if (!hit) continue;
        providerRows.push({
          provider: provider.label,
          providerId: packageId(pack),
          packId: pack.collection,
          packLabel: pack.metadata?.label ?? pack.title ?? pack.collection,
          sceneId: entry._id,
          sceneName: entry.name,
          categoryKey: hit.category.key,
          categoryLabel: hit.category.label,
          score: hit.score,
          uuid: `Compendium.${pack.collection}.Scene.${entry._id}`
        });
      }
    }

    providerRows.sort((a,b) => b.score-a.score || a.sceneName.localeCompare(b.sceneName));
    candidates.push(...providerRows.slice(0, provider.maxScenes ?? 12));
  }

  const deduped = new Map();
  for (const c of candidates) {
    const previous = deduped.get(c.uuid);
    if (!previous || c.score > previous.score) deduped.set(c.uuid, c);
  }

  const perCategory = new Map();
  const final = [];
  for (const c of [...deduped.values()].sort((a,b) => b.score-a.score || a.sceneName.localeCompare(b.sceneName))) {
    const cat = CATEGORY_RULES.find(x => x.key === c.categoryKey);
    const count = perCategory.get(c.categoryKey) ?? 0;
    if (count >= (cat?.max ?? 8)) continue;
    perCategory.set(c.categoryKey, count + 1);
    final.push(c);
  }
  return final;
}

async function preview() {
  if (!game.user?.isGM) return ui.notifications.warn("Skyhorn curated-map preview requires a GM.");

  const sources = PROVIDERS.map(rule => {
    const mods = resolveProviderModules(rule);
    return {
      source: rule.label,
      installed: mods.length > 0,
      active: mods.some(x => x.mod.active),
      modules: mods.map(x => `${x.id}${x.mod.active ? " [active]" : " [disabled]"}`).join(", ") || "—"
    };
  });
  const candidates = await findCandidates();

  console.group("Skyhorn curated map sources");
  console.table(sources);
  console.groupEnd();

  console.group(`Skyhorn curated map candidates — ${candidates.length}`);
  console.table(candidates.map(c => ({
    category:c.categoryLabel,
    provider:c.provider,
    pack:c.packLabel,
    scene:c.sceneName,
    score:c.score
  })));
  console.groupEnd();

  ui.notifications.info(`Skyhorn curated preview: ${candidates.length} additive map candidates. See console.`);
  return {sources, candidates};
}

async function importCurated() {
  if (!game.user?.isGM) return ui.notifications.warn("Skyhorn curated-map import requires a GM.");

  const candidates = await findCandidates();
  if (!candidates.length) {
    ui.notifications.warn("No relevant active Scene compendia were found. Check the source report and enable installed map modules.");
    return {created:[], skipped:[], errors:[]};
  }

  const root = await ensureFolder(ROOT_FOLDER);
  const created = [];
  const skipped = [];
  const errors = [];

  for (const c of candidates) {
    const existing = game.scenes.find(scene => scene.getFlag(MODULE_ID, SOURCE_FLAG) === c.uuid);
    if (existing) {
      skipped.push({scene:c.sceneName, existingId:existing.id});
      continue;
    }

    try {
      const pack = game.packs.get(c.packId);
      const source = await pack?.getDocument(c.sceneId);
      if (!source) throw new Error(`Scene not found in ${c.packId}`);

      const categoryFolder = await ensureFolder(c.categoryLabel, root);
      const data = source.toObject();
      delete data._id;
      data.folder = categoryFolder.id;
      data.name = `${c.sceneName} — Skyhorn source`;
      data.navigation = false;
      data.flags ??= {};
      data.flags[MODULE_ID] = {
        ...(data.flags[MODULE_ID] ?? {}),
        [SOURCE_FLAG]: c.uuid,
        sourceModule: c.providerId,
        sourcePack: c.packId,
        originalName: c.sceneName,
        category: c.categoryKey,
        score: c.score,
        importedAt: new Date().toISOString()
      };

      const scene = await Scene.create(data, {renderSheet:false});
      created.push({scene:c.sceneName, worldSceneId:scene.id, category:c.categoryLabel});
    } catch (error) {
      console.error(`[Skyhorn Curated Maps] Failed importing ${c.sceneName}`, error);
      errors.push({scene:c.sceneName, error:String(error?.message ?? error)});
    }
  }

  console.group("Skyhorn curated additive import results");
  console.table(created);
  console.table(skipped);
  if (errors.length) console.table(errors);
  console.groupEnd();

  ui.notifications.info(`Skyhorn curated import complete: ${created.length} created, ${skipped.length} already present, ${errors.length} error(s).`);
  return {created, skipped, errors};
}

function reportSources() {
  const rows = PROVIDERS.map(rule => {
    const mods = resolveProviderModules(rule);
    return {
      source: rule.label,
      installed: mods.length > 0,
      active: mods.some(x => x.mod.active),
      modules: mods.map(x => `${x.id}${x.mod.active ? " [active]" : " [disabled]"}`).join(", ") || "—"
    };
  });
  console.table(rows);
  return rows;
}

async function seedMacro(name, command, key) {
  if (!game.user?.isGM) return;
  const existing = game.macros.find(m => m.getFlag(MODULE_ID, "seededMacro") === key);
  if (existing) return existing;
  try {
    return await Macro.create({
      name,
      type:"script",
      scope:"global",
      command,
      flags:{[MODULE_ID]:{seededMacro:key}}
    }, {renderSheet:false});
  } catch (error) {
    console.warn(`[Skyhorn Curated Maps] Could not create helper macro ${name}`, error);
  }
}

const API = {MODULE_ID, PROVIDERS, CATEGORY_RULES, findCandidates, preview, importCurated, reportSources};
globalThis.NorthernFjordCuratedMaps = API;

Hooks.once("ready", async () => {
  if (!game.user?.isGM) return;
  await seedMacro("Skyhorn Maps — Preview Curated Sources", "await globalThis.NorthernFjordCuratedMaps.preview();", "preview");
  await seedMacro("Skyhorn Maps — Import Curated Additions", "await globalThis.NorthernFjordCuratedMaps.importCurated();", "import");
  await seedMacro("Skyhorn Maps — Report Source Modules", "globalThis.NorthernFjordCuratedMaps.reportSources(); ui.notifications.info('See console for map-source status.');", "report");
  console.info(`[Skyhorn Curated Maps] ${MODULE_ID} v${game.modules.get(MODULE_ID)?.version ?? "?"} ready.`);
});
