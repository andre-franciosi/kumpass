/**
 * Gera tracks reais a partir do OpenStreetMap (Overpass API).
 *
 * Uso: npm run tracks  (ou `make tracks`)
 * Saída: prisma/tracks/{sintra,arrabida,monsanto}.json
 *
 * O seed lê estes JSON — o script nunca corre em runtime da app.
 * Fonte: © OpenStreetMap contributors (ODbL).
 */
import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = resolve(__dirname, "../prisma/tracks");

const OVERPASS_ENDPOINTS = [
  "https://overpass-api.de/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
];

const USER_AGENT = "Kumpas/1.0 (dev@kumpas.dev)";

interface RegionConfig {
  slug: string;
  relationId: number;
  /** Bbox usado para procurar POIs à volta da rota. */
  poiBbox: [number, number, number, number]; // south, west, north, east
}

const REGIONS: RegionConfig[] = [
  {
    slug: "sintra",
    relationId: 2259794, // Rota "Pena" (Circuito de Sintra)
    poiBbox: [38.785, -9.405, 38.805, -9.37],
  },
  {
    slug: "castelo",
    relationId: 3091628, // Rota "Castelo" (Castelo dos Mouros)
    poiBbox: [38.78, -9.405, 38.805, -9.37],
  },
  {
    slug: "arrabida",
    relationId: 15431241, // Alto do Formosinho
    poiBbox: [38.455, -9.03, 38.51, -8.96],
  },
  {
    slug: "portinho",
    relationId: 15431276, // Portinho da Arrábida
    poiBbox: [38.47, -9.02, 38.505, -8.985],
  },
  {
    slug: "monsanto",
    relationId: 7624909, // Volta do Planalto
    poiBbox: [38.715, -9.205, 38.745, -9.165],
  },
  {
    slug: "agua",
    relationId: 7626364, // Rota da Água
    poiBbox: [38.715, -9.21, 38.745, -9.16],
  },
];

interface OverpassElement {
  type: string;
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  nodes?: number[];
  members?: Array<{ type: string; ref: number; role: string }>;
  tags?: Record<string, string>;
}

/** Tags OSM úteis para enriquecer o lore a partir da Wikipédia/Wikidata. */
interface PoiWikiTags {
  wikipedia?: string;
  wikidata?: string;
  description?: string;
  inscription?: string;
}

interface TrackOutput {
  slug: string;
  relationId: number;
  relationName: string;
  source: string;
  trackPoints: Array<[number, number]>;
  bbox: { minLat: number; minLng: number; maxLat: number; maxLng: number };
  distanceKm: number;
  elevationGainM: number;
  pois: Array<{
    order: number;
    name: string;
    kind: string;
    lore: string;
    lat: number;
    lng: number;
    radiusMeters: number;
    osmType?: string;
    osmId?: number;
    wiki?: PoiWikiTags;
  }>;
}

const sleep = (ms: number): Promise<void> =>
  new Promise((r) => setTimeout(r, ms));

async function fetchOverpass(query: string): Promise<OverpassElement[]> {
  let lastError: unknown = null;

  for (let attempt = 1; attempt <= 4; attempt++) {
    const endpoint = OVERPASS_ENDPOINTS[(attempt - 1) % OVERPASS_ENDPOINTS.length];
    try {
      console.log(`  → Overpass (tentativa ${attempt}) ${endpoint}`);
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": USER_AGENT,
        },
        body: new URLSearchParams({ data: query }).toString(),
        signal: AbortSignal.timeout(120_000),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const json = (await response.json()) as { elements: OverpassElement[] };
      return json.elements ?? [];
    } catch (error) {
      lastError = error;
      const wait = attempt * 4000;
      console.warn(`    falhou (${String(error)}). A aguardar ${wait / 1000}s...`);
      await sleep(wait);
    }
  }

  throw new Error(`Overpass indisponível: ${String(lastError)}`);
}

const toRad = (d: number): number => (d * Math.PI) / 180;

function haversine(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371000;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

/** Douglas-Peucker com tolerância em metros. */
function simplify(
  points: Array<[number, number]>,
  toleranceMeters = 12
): Array<[number, number]> {
  if (points.length <= 2) return points;

  const lat0 = toRad(points[0][0]);
  const project = (p: [number, number]): [number, number] => [
    (p[1] - points[0][1]) * 111320 * Math.cos(lat0),
    (p[0] - points[0][0]) * 110540,
  ];

  const projected = points.map(project);
  const keep = new Array<boolean>(points.length).fill(false);
  keep[0] = true;
  keep[points.length - 1] = true;

  const stack: Array<[number, number]> = [[0, points.length - 1]];

  while (stack.length > 0) {
    const [start, end] = stack.pop()!;
    const [x1, y1] = projected[start];
    const [x2, y2] = projected[end];
    const dx = x2 - x1;
    const dy = y2 - y1;
    const norm = Math.hypot(dx, dy);

    let farthest = -1;
    let maxDistance = 0;

    for (let i = start + 1; i < end; i++) {
      const [x, y] = projected[i];
      const distance =
        norm === 0
          ? Math.hypot(x - x1, y - y1)
          : Math.abs(dy * x - dx * y + x2 * y1 - y2 * x1) / norm;

      if (distance > maxDistance) {
        maxDistance = distance;
        farthest = i;
      }
    }

    if (maxDistance > toleranceMeters && farthest > 0) {
      keep[farthest] = true;
      stack.push([start, farthest], [farthest, end]);
    }
  }

  return points.filter((_, i) => keep[i]);
}

function stitchWays(
  wayIds: number[],
  ways: Map<number, number[]>
): number[] {
  const remaining = [...wayIds];
  const firstWay = ways.get(remaining.shift()!);
  if (!firstWay) return [];

  const sequence = [...firstWay];

  while (remaining.length > 0) {
    let matchedIndex = -1;
    let mode: "append" | "append-reversed" | "prepend" | "prepend-reversed" =
      "append";

    for (let i = 0; i < remaining.length; i++) {
      const nodes = ways.get(remaining[i]);
      if (!nodes || nodes.length < 2) continue;

      if (nodes[0] === sequence[sequence.length - 1]) {
        matchedIndex = i;
        mode = "append";
        break;
      }
      if (nodes[nodes.length - 1] === sequence[sequence.length - 1]) {
        matchedIndex = i;
        mode = "append-reversed";
        break;
      }
      if (nodes[nodes.length - 1] === sequence[0]) {
        matchedIndex = i;
        mode = "prepend";
        break;
      }
      if (nodes[0] === sequence[0]) {
        matchedIndex = i;
        mode = "prepend-reversed";
        break;
      }
    }

    if (matchedIndex === -1) break;

    const nodes = ways.get(remaining.splice(matchedIndex, 1)[0])!;

    if (mode === "append") {
      sequence.push(...nodes.slice(1));
    } else if (mode === "append-reversed") {
      sequence.push(...nodes.slice(0, -1).reverse());
    } else if (mode === "prepend") {
      sequence.unshift(...nodes.slice(0, -1));
    } else {
      sequence.unshift(...nodes.slice(1).reverse());
    }
  }

  return sequence;
}

async function fetchElevationGain(
  points: Array<[number, number]>
): Promise<number> {
  const sampled: Array<[number, number]> = [];
  const maxSamples = 90;
  const step = Math.max(1, Math.floor(points.length / maxSamples));

  for (let i = 0; i < points.length; i += step) sampled.push(points[i]);
  if (sampled[sampled.length - 1] !== points[points.length - 1]) {
    sampled.push(points[points.length - 1]);
  }

  const lats = sampled.map((p) => p[0].toFixed(6)).join(",");
  const lngs = sampled.map((p) => p[1].toFixed(6)).join(",");
  const url = `https://api.open-meteo.com/v1/elevation?latitude=${lats}&longitude=${lngs}`;

  try {
    const response = await fetch(url, {
      headers: { "User-Agent": USER_AGENT },
      signal: AbortSignal.timeout(45_000),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);

    const json = (await response.json()) as { elevation: number[] };
    const elevations = json.elevation ?? [];
    let gain = 0;

    for (let i = 1; i < elevations.length; i++) {
      const diff = elevations[i] - elevations[i - 1];
      if (diff > 0) gain += diff;
    }

    return Math.round(gain);
  } catch (error) {
    console.warn(`    elevação indisponível (${String(error)}); a estimar.`);
    return 0;
  }
}

interface PoiCandidate {
  name: string;
  kind: string;
  lat: number;
  lng: number;
  progress: number;
  distanceMeters: number;
  osmType: string;
  osmId: number;
  wiki: PoiWikiTags;
}

const LORE_BY_KIND: Array<[RegExp, string]> = [
  [
    /viewpoint|peak/,
    "Um miradouro que os locais guardam como segredo. A vista explica porque esta rota é memorável.",
  ],
  [
    /castle|fort|ruins|archaeological/,
    "Pedras que já viram reis, cercos e séculos de histórias. Pára e imagina o que aqui se viveu.",
  ],
  [
    /monument|memorial/,
    "Um marco que resistiu ao tempo e ainda conta a história de quem por aqui passou.",
  ],
  [
    /museum|information|attraction/,
    "Um ponto de paragem onde a história da região está documentada e à espera de ser descoberta.",
  ],
];

function loreFor(kind: string): string {
  const match = LORE_BY_KIND.find(([pattern]) => pattern.test(kind));
  return (
    match?.[1] ??
    "Um ponto de interesse real desta trilha, marcado no mapa para explorares com atenção."
  );
}

function pickPois(
  candidates: PoiCandidate[],
  track: Array<[number, number]>,
  relationName: string
): TrackOutput["pois"] {
  const unique: PoiCandidate[] = [];
  for (const candidate of candidates.sort((a, b) => a.progress - b.progress)) {
    const duplicate = unique.some(
      (u) =>
        u.name === candidate.name ||
        haversine(u.lat, u.lng, candidate.lat, candidate.lng) < 70
    );
    if (!duplicate) unique.push(candidate);
  }

  const targets = [0.08, 0.38, 0.68, 0.92];
  const chosen: PoiCandidate[] = [];

  for (const target of targets) {
    let best: PoiCandidate | null = null;
    for (const candidate of unique) {
      if (chosen.includes(candidate)) continue;
      if (!best || Math.abs(candidate.progress - target) < Math.abs(best.progress - target)) {
        best = candidate;
      }
    }
    if (best && Math.abs(best.progress - target) < 0.3) chosen.push(best);
  }

  const fallbackNames = [
    `Início · ${relationName}`,
    `Meio do percurso · ${relationName}`,
    `Fim · ${relationName}`,
  ];
  if (chosen.length < 2) {
    const fractions = [0.02, 0.5, 0.98];
    return fractions.map((fraction, index) => {
      const point = track[Math.floor((track.length - 1) * fraction)];
      return {
        order: index + 1,
        name: fallbackNames[index],
        kind: "route",
        lore:
          index === 0
            ? "Aqui começa a tua missão. Antes de avançar, confirma a água, o calçado e o plano."
            : index === 1
              ? "Meio do caminho! Respira, olha em volta e regista o que já descobriste."
              : "Fim do trilho. A vista e o cansaço fazem parte da história que vais contar.",
        lat: Number(point[0].toFixed(6)),
        lng: Number(point[1].toFixed(6)),
        radiusMeters: 80,
      };
    });
  }

  return chosen
    .sort((a, b) => a.progress - b.progress)
    .map((poi, index) => ({
      order: index + 1,
      name: poi.name,
      kind: poi.kind,
      lore: loreFor(poi.kind),
      lat: Number(poi.lat.toFixed(6)),
      lng: Number(poi.lng.toFixed(6)),
      radiusMeters: /viewpoint|peak/.test(poi.kind) ? 75 : 60,
      osmType: poi.osmType,
      osmId: poi.osmId,
      wiki: poi.wiki,
    }));
}

async function buildRegion(config: RegionConfig): Promise<TrackOutput> {
  console.log(`\n[${config.slug}] relation ${config.relationId}`);

  const elements = await fetchOverpass(
    `[out:json][timeout:90];rel(${config.relationId});out body;>;out skel qt;`
  );

  const relation = elements.find(
    (e) => e.type === "relation" && e.id === config.relationId
  );
  if (!relation) throw new Error(`Relação ${config.relationId} não encontrada.`);

  const wayIds = (relation.members ?? [])
    .filter((m) => m.type === "way")
    .map((m) => m.ref);

  const ways = new Map<number, number[]>();
  const nodes = new Map<number, { lat: number; lon: number }>();

  for (const element of elements) {
    if (element.type === "way" && element.nodes) {
      ways.set(element.id, element.nodes);
    } else if (
      element.type === "node" &&
      typeof element.lat === "number" &&
      typeof element.lon === "number"
    ) {
      nodes.set(element.id, { lat: element.lat, lon: element.lon });
    }
  }

  const sequence = stitchWays(wayIds, ways);
  const rawTrack: Array<[number, number]> = sequence
    .map((id) => nodes.get(id))
    .filter((n): n is { lat: number; lon: number } => Boolean(n))
    .map((n) => [n.lat, n.lon]);

  if (rawTrack.length < 10) {
    throw new Error(`Track demasiado curto (${rawTrack.length} pontos).`);
  }

  const track = simplify(rawTrack, 12);

  let distanceMeters = 0;
  for (let i = 1; i < track.length; i++) {
    distanceMeters += haversine(
      track[i - 1][0],
      track[i - 1][1],
      track[i][0],
      track[i][1]
    );
  }

  console.log(
    `  track: ${rawTrack.length} → ${track.length} pontos · ${(distanceMeters / 1000).toFixed(2)} km`
  );

  const elevationGainM = await fetchElevationGain(track);
  console.log(`  elevação: ${elevationGainM} m D+`);

  const poiElements = await fetchOverpass(
    `[out:json][timeout:60];
    (
      node["tourism"~"viewpoint|attraction|museum|information"](${config.poiBbox.join(",")});
      node["historic"~"castle|monument|memorial|ruins|archaeological_site|fort"](${config.poiBbox.join(",")});
      way["tourism"~"viewpoint|attraction|museum"](${config.poiBbox.join(",")});
      way["historic"~"castle|monument|memorial|ruins|archaeological_site|fort"](${config.poiBbox.join(",")});
      node["natural"="peak"](${config.poiBbox.join(",")});
    );
    out center tags;`
  );

  const candidates: PoiCandidate[] = [];

  for (const element of poiElements) {
    const name = element.tags?.name;
    if (!name) continue;

    const lat = element.lat ?? element.center?.lat;
    const lng = element.lon ?? element.center?.lon;
    if (typeof lat !== "number" || typeof lng !== "number") continue;

    const kind = element.tags?.tourism
      ? `tourism=${element.tags.tourism}`
      : element.tags?.historic
        ? `historic=${element.tags.historic}`
        : element.tags?.natural
          ? `natural=${element.tags.natural}`
          : "poi";

    let bestIndex = 0;
    let bestDistance = Number.POSITIVE_INFINITY;
    for (let i = 0; i < track.length; i++) {
      const distance = haversine(lat, lng, track[i][0], track[i][1]);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    if (bestDistance > 650) continue;

    candidates.push({
      name,
      kind,
      lat,
      lng,
      progress: bestIndex / (track.length - 1),
      distanceMeters: bestDistance,
      osmType: element.type,
      osmId: element.id,
      wiki: {
        wikipedia: element.tags?.wikipedia,
        wikidata: element.tags?.wikidata,
        description: element.tags?.description,
        inscription: element.tags?.inscription,
      },
    });
  }

  console.log(`  POIs próximos: ${candidates.length}`);
  const pois = pickPois(candidates, track, relation.tags?.name ?? config.slug);

  for (const poi of pois) {
    const lore = loreFor(poi.kind);
    console.log(`    ${poi.order}. ${poi.name} (${poi.kind}) — ${lore.slice(0, 40)}...`);
  }

  const lats = [...track.map((p) => p[0]), ...pois.map((p) => p.lat)];
  const lngs = [...track.map((p) => p[1]), ...pois.map((p) => p.lng)];

  // Padding de ~150 m para o mapa offline e o fit da câmara incluírem POIs.
  const padLat = 0.0015;
  const padLng = 0.0018;

  return {
    slug: config.slug,
    relationId: config.relationId,
    relationName: relation.tags?.name ?? config.slug,
    source: "© OpenStreetMap contributors (ODbL) — via Overpass API",
    trackPoints: track.map(([lat, lng]) => [
      Number(lat.toFixed(6)),
      Number(lng.toFixed(6)),
    ]),
    bbox: {
      minLat: Math.min(...lats) - padLat,
      minLng: Math.min(...lngs) - padLng,
      maxLat: Math.max(...lats) + padLat,
      maxLng: Math.max(...lngs) + padLng,
    },
    distanceKm: Math.round((distanceMeters / 1000) * 10) / 10,
    elevationGainM,
    pois,
  };
}

async function main(): Promise<void> {
  await mkdir(OUT_DIR, { recursive: true });

  // Permite regenerar só algumas regiões: --only=portinho,agua
  const onlyArg = process.argv.find((a) => a.startsWith("--only="));
  const only = onlyArg ? onlyArg.split("=")[1].split(",") : null;

  for (const region of REGIONS) {
    if (only && !only.includes(region.slug)) continue;

    const output = await buildRegion(region);
    const path = resolve(OUT_DIR, `${region.slug}.json`);

    // Não apagar o ficheiro anterior em caso de falha: só escreve no fim.
    await writeFile(path, `${JSON.stringify(output, null, 2)}\n`, "utf8");
    console.log(`  ✔ ${path}`);
  }

  console.log("\nTracks gerados com sucesso.");
}

main().catch((error) => {
  console.error("\nFalha ao gerar tracks:", error);
  process.exit(1);
});
