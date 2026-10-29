/**
 * Enriquece os POIs das trilhas com histórias REAIS e fotos livres.
 *
 * Cadeia de fontes (por POI):
 *   1. Tags OSM (wikipedia=*, wikidata=*, description=*, inscription=*)
 *   2. Wikidata  → descrição pt + sitelink ptwiki + imagem P18 (Commons)
 *   3. Wikipédia → extract da API REST (apenas pt) + imagem
 *   4. Overrides (curadoria manual em prisma/content/overrides.json)
 *   5. Fallback genérico do track JSON (marcado como "fallback" no relatório)
 *
 * Imagens: Wikimedia Commons (P18) com crédito (autor + licença).
 * Saída: prisma/content/{slug}.json + coverage.json
 *
 * Uso: npm run content  (ou `make content`)
 */
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const TRACKS_DIR = resolve(__dirname, "../prisma/tracks");
const CONTENT_DIR = resolve(__dirname, "../prisma/content");

const WIKI_UA = "Kumpas-content-bot/1.0 (dev@kumpas.dev)";
const OVERPASS_ENDPOINTS = [
  "https://overpass-api.de/api/interpreter",
  "https://overpass.kumi.systems/api/interpreter",
];

const TRACK_SLUGS = ["sintra", "arrabida", "monsanto", "castelo", "portinho", "agua"];

const sleep = (ms: number): Promise<void> => new Promise((r) => setTimeout(r, ms));

async function fetchJson(url: string, timeoutMs = 30_000): Promise<any> {
  const response = await fetch(url, {
    headers: { "User-Agent": WIKI_UA, Accept: "application/json" },
    signal: AbortSignal.timeout(timeoutMs),
  });
  if (!response.ok) throw new Error(`HTTP ${response.status} em ${url}`);
  return response.json();
}

function normalizeName(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9 ]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

interface PoiWikiTags {
  wikipedia?: string;
  wikidata?: string;
  description?: string;
  inscription?: string;
}

interface TrackPoi {
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
}

interface TrackData {
  slug: string;
  relationId: number;
  relationName: string;
  source: string;
  trackPoints: Array<[number, number]>;
  bbox: { minLat: number; minLng: number; maxLat: number; maxLng: number };
  distanceKm: number;
  elevationGainM: number;
  pois: TrackPoi[];
}

interface PoiContent {
  lore: string;
  loreSource: string;
  loreUrl?: string;
  titleEn?: string;
  loreEn?: string;
  loreSourceEn?: string;
  loreUrlEn?: string;
  imageUrl?: string;
  imageCredit?: string;
  origin: "wikipedia" | "wikidata" | "override" | "fallback";
  /** Referência opcional em overrides para buscar imagem (ex.: "Palácio Nacional da Pena"). */
  wikipedia?: string;
  wikidata?: string;
}

interface TrackContent {
  slug: string;
  coverage: { real: number; override: number; fallback: number; total: number };
  quest?: {
    imageUrl?: string;
    imageCredit?: string;
    titleEn?: string;
    descriptionEn?: string;
  };
  pois: Record<string, PoiContent>;
}

/** "pt:Palácio da Pena" → { lang: "pt", title: "Palácio da Pena" } */
function parseWikipediaTag(tag: string): { lang: string; title: string } | null {
  const trimmed = tag.trim();
  const match = trimmed.match(/^([a-z]{2,3})\s*:\s*(.+)$/);
  if (match) {
    return { lang: match[1], title: match[2].trim() };
  }
  // Sem prefixo de idioma: assume pt (aplicação portuguesa).
  return { lang: "pt", title: trimmed };
}

function truncateToSentence(text: string, max = 380): string {
  const clean = text.replace(/\s+/g, " ").trim();
  if (clean.length <= max) return clean;

  const sentences = clean.split(/(?<=[.!?])\s+/);
  let output = "";
  for (const sentence of sentences) {
    if ((output + " " + sentence).trim().length > max) break;
    output = (output + " " + sentence).trim();
  }
  if (output.length >= 60) return output;

  const cut = clean.slice(0, max);
  const lastSpace = cut.lastIndexOf(" ");
  return `${cut.slice(0, lastSpace > 40 ? lastSpace : max).trim()}…`;
}

/** Heurística leve para garantir texto português (evita EN/ES). */
function looksPortuguese(text: string): boolean {
  const words = text.toLowerCase().split(/\s+/);
  const ptMarkers = words.filter((w) =>
    ["de", "da", "do", "dos", "das", "em", "que", "com", "uma", "para", "por", "no", "na"].includes(w)
  ).length;
  const esMarkers = words.filter((w) => ["el", "los", "las", "del", "con"].includes(w)).length;
  const enMarkers = words.filter((w) => ["the", "of", "and", "in", "with"].includes(w)).length;
  if (esMarkers > 0 && ptMarkers < esMarkers * 3) return false;
  if (enMarkers > words.length * 0.15) return false;
  return ptMarkers >= 3;
}

function stripHtml(html: string): string {
  return html
    .replace(/<[^>]*>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#039;|&apos;/g, "'")
    .trim();
}

async function fetchOverpassPoiTags(
  lat: number,
  lng: number,
  name: string
): Promise<PoiWikiTags | null> {
  const query = `[out:json][timeout:25];(node(around:150,${lat},${lng});way(around:150,${lat},${lng}););out center tags;`;

  let elements: any[] = [];
  for (let attempt = 1; attempt <= 2; attempt++) {
    const endpoint = OVERPASS_ENDPOINTS[(attempt - 1) % OVERPASS_ENDPOINTS.length];
    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": WIKI_UA,
        },
        body: new URLSearchParams({ data: query }).toString(),
        signal: AbortSignal.timeout(15_000),
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const json = (await response.json()) as { elements?: any[] };
      elements = json.elements ?? [];
      break;
    } catch (error) {
      console.warn(`    Overpass around falhou (${String(error)}), tentativa ${attempt}`);
      await sleep(attempt * 2000);
    }
  }
  if (elements.length === 0) return null;

  const wanted = normalizeName(name);
  const candidates = elements.filter(
    (e) =>
      e.tags &&
      e.tags.name &&
      (e.tags.wikipedia || e.tags.wikidata)
  );

  // Só aceitamos correspondência segura: nome normalizado igual ou contido.
  const named = candidates.find((e) => {
    const elementName = normalizeName(e.tags.name);
    return (
      elementName === wanted ||
      elementName.includes(wanted) ||
      wanted.includes(elementName)
    );
  });

  if (!named) return null;
  return {
    wikipedia: named.tags.wikipedia,
    wikidata: named.tags.wikidata,
    description: named.tags.description,
    inscription: named.tags.inscription,
  };
}

interface WikiResult {
  lore?: string;
  loreUrl?: string;
  imageUrl?: string;
  imageCredit?: string;
  origin: "wikipedia" | "wikidata";
}

/** Info de um ficheiro no Commons: thumb válido (iiurlwidth) + crédito. */
async function commonsImageInfo(
  filename: string,
  wantWidth = 1200
): Promise<{ imageUrl?: string; imageCredit?: string }> {
  const url =
    `https://commons.wikimedia.org/w/api.php?action=query&format=json` +
    `&prop=imageinfo&iiprop=url%7Cextmetadata&iiurlwidth=${wantWidth}` +
    `&titles=${encodeURIComponent(`File:${filename}`)}`;
  const json = await fetchJson(url);
  const pages = json?.query?.pages ?? {};
  const info = Object.values<any>(pages)[0]?.imageinfo?.[0];
  if (!info) return {};

  const artist = info.extmetadata?.Artist?.value
    ? stripHtml(info.extmetadata.Artist.value)
    : null;
  const license = info.extmetadata?.LicenseShortName?.value
    ? stripHtml(info.extmetadata.LicenseShortName.value)
    : null;

  return {
    // thumburl é gerado pelo servidor com um tamanho válido.
    imageUrl: info.thumburl ?? info.url,
    imageCredit:
      [artist, license].filter(Boolean).join(" — ") || "Wikimedia Commons",
  };
}

/** Imagem do artigo via pageimages (thumb válido no próprio servidor). */
async function wikipediaImage(
  lang: string,
  title: string
): Promise<{ imageUrl?: string; imageCredit?: string }> {
  const api =
    `https://${lang}.wikipedia.org/w/api.php?action=query&format=json` +
    `&prop=pageimages&piprop=original%7Cthumbnail&pithumbsize=1200&titles=${encoded(title)}`;
  const json = await fetchJson(api);
  const page = Object.values<any>(json?.query?.pages ?? {})[0];

  const filename = page?.pageimage as string | undefined;
  if (filename) {
    try {
      const info = await commonsImageInfo(filename, 1200);
      if (info.imageUrl) return info;
    } catch {
      // cai para thumb/original abaixo
    }
    await sleep(250);
  }

  const fallback = page?.thumbnail?.source ?? page?.original?.source;
  return fallback ? { imageUrl: fallback, imageCredit: "Wikimedia Commons" } : {};
}

async function wikidataImage(qid: string): Promise<{ imageUrl?: string; imageCredit?: string }> {
  const url =
    `https://www.wikidata.org/w/api.php?action=wbgetentities&ids=${qid}` +
    `&format=json&props=claims&languages=pt`;
  const json = await fetchJson(url);
  const entity = json?.entities?.[qid];
  const p18 = entity?.claims?.P18?.[0]?.mainsnak?.datavalue?.value as string | undefined;
  if (!p18) return {};

  const image = await commonsImageInfo(p18, 1200);
  await sleep(300);
  return image;
}

async function wikipediaSummary(
  lang: string,
  title: string
): Promise<{ extract?: string; pageUrl?: string }> {
  const encodedTitle = encodeURIComponent(title.replace(/ /g, "_"));
  const json = await fetchJson(
    `https://${lang}.wikipedia.org/api/rest_v1/page/summary/${encodedTitle}`
  );
  if (json?.type === "standard") {
    return {
      extract: json.extract,
      pageUrl: json.content_urls?.desktop?.page,
    };
  }
  return {};
}

async function enrichWithWiki(
  poi: TrackPoi,
  tags: PoiWikiTags
): Promise<WikiResult> {
  const result: WikiResult = { origin: "wikipedia" };

  // 1) Wikidata → imagem sempre que existir.
  if (tags.wikidata) {
    try {
      const image = await wikidataImage(tags.wikidata);
      result.imageUrl = image.imageUrl;
      result.imageCredit = image.imageCredit;
    } catch (error) {
      console.warn(`    wikidata falhou (${String(error)})`);
    }
    await sleep(300);
  }

  // 2) Wikipédia (apenas pt) → extract como lore + imagem se ainda faltar.
  const wikiTag = tags.wikipedia;
  if (wikiTag) {
    const parsed = parseWikipediaTag(wikiTag);
    if (parsed && parsed.lang === "pt") {
      try {
        const summary = await wikipediaSummary(parsed.lang, parsed.title);
        if (
          summary.extract &&
          looksPortuguese(summary.extract) &&
          summary.extract.length >= 80
        ) {
          result.lore = truncateToSentence(summary.extract);
          result.loreUrl =
            summary.pageUrl ?? `https://pt.wikipedia.org/wiki/${encoded(parsed.title)}`;
        }
        if (!result.imageUrl) {
          const image = await wikipediaImage(parsed.lang, parsed.title);
          if (image.imageUrl) {
            result.imageUrl = image.imageUrl;
            result.imageCredit = image.imageCredit;
          }
        }
      } catch (error) {
        console.warn(`    wikipédia falhou (${String(error)})`);
      }
      await sleep(300);
    }
  }

  return result;
}

function encoded(title: string): string {
  return encodeURIComponent(title.replace(/ /g, "_"));
}

async function main(): Promise<void> {
  await mkdir(CONTENT_DIR, { recursive: true });

  const overridesPath = resolve(CONTENT_DIR, "overrides.json");
  let overrides: Record<string, Record<string, Partial<PoiContent>>> = {};
  try {
    overrides = JSON.parse(await readFile(overridesPath, "utf8"));
  } catch {
    console.log("Sem overrides.json — a usar apenas fontes automáticas.");
  }

  // Metadados EN por trilha (título + descrição).
  let questsEn: Record<string, { title?: string; description?: string }> = {};
  try {
    questsEn = JSON.parse(
      await readFile(resolve(CONTENT_DIR, "quests_en.json"), "utf8")
    );
  } catch {
    console.log("Sem quests_en.json — trilhas ficam sem título/descrição EN.");
  }

  // Permite regenerar só algumas trilhas: --only=sintra,agua
  const onlyArg = process.argv.find((a) => a.startsWith("--only="));
  const only = onlyArg ? onlyArg.split("=")[1].split(",") : null;
  // Evita consultas "around" ao Overpass (útil quando os tracks já têm tags).
  const skipOverpass = process.argv.includes("--no-overpass");

  const report: Array<{
    slug: string;
    real: number;
    override: number;
    fallback: number;
    total: number;
  }> = [];

  for (const slug of TRACK_SLUGS) {
    if (only && !only.includes(slug)) continue;

    let track: TrackData;
    try {
      track = JSON.parse(await readFile(resolve(TRACKS_DIR, `${slug}.json`), "utf8"));
    } catch {
      console.log(`\n[${slug}] sem track JSON — a ignorar.`);
      continue;
    }

    console.log(`\n[${slug}] ${track.pois.length} POIs`);
    const content: TrackContent = {
      slug,
      coverage: { real: 0, override: 0, fallback: 0, total: track.pois.length },
      pois: {},
    };

    for (const poi of track.pois) {
      let tags = poi.wiki;

      // Tracks antigos podem não ter tags — procura por proximidade no OSM.
      if (!skipOverpass && (!tags || (!tags.wikipedia && !tags.wikidata))) {
        tags = (await fetchOverpassPoiTags(poi.lat, poi.lng, poi.name)) ?? tags;
        await sleep(500);
      }

      let poiContent: PoiContent = {
        lore: poi.lore,
        loreSource: "Fallback",
        origin: "fallback",
      };

      if (tags && (tags.wikipedia || tags.wikidata)) {
        const wiki = await enrichWithWiki(poi, tags);
        if (wiki.lore) {
          poiContent = {
            lore: wiki.lore,
            loreSource: "Wikipédia",
            loreUrl: wiki.loreUrl,
            imageUrl: wiki.imageUrl,
            imageCredit: wiki.imageCredit,
            origin: wiki.lore ? "wikipedia" : "wikidata",
          };
          console.log(`  ${poi.order}. ${poi.name} → Wikipédia ✔ (${wiki.lore.length} chars)`);
        } else if (wiki.imageUrl) {
          poiContent = {
            lore: poi.lore,
            loreSource: "Fallback",
            imageUrl: wiki.imageUrl,
            imageCredit: wiki.imageCredit,
            origin: "wikidata",
          };
          console.log(`  ${poi.order}. ${poi.name} → imagem do Wikidata (sem artigo pt)`);
        } else {
          console.log(`  ${poi.order}. ${poi.name} → wiki sem extract pt`);
        }
      }

      // Overrides (curadoria) têm sempre prioridade; podem também pedir
      // imagem via `wikipedia`/`wikidata` quando o POI não tem tags.
      const slugOverrides = overrides[slug] ?? {};
      const byName = slugOverrides[poi.name];
      const byOrder = slugOverrides[String(poi.order)];
      const override = byName ?? byOrder;
      if (override) {
        let wikiImage: { imageUrl?: string; imageCredit?: string } = {};
        const wikiRef = (override as any).wikipedia ?? (override as any).wikidata;
        if (!override.imageUrl && wikiRef) {
          const tags: PoiWikiTags =
            typeof wikiRef === "string" && /^Q\d+$/.test(wikiRef)
              ? { wikidata: wikiRef }
              : { wikipedia: wikiRef };
          try {
            const enriched = await enrichWithWiki(poi, tags);
            wikiImage = { imageUrl: enriched.imageUrl, imageCredit: enriched.imageCredit };
          } catch {
            // sem imagem; fica o gradiente
          }
          await sleep(250);
        }

        poiContent = {
          ...poiContent,
          ...override,
          ...(override.imageUrl ? {} : wikiImage),
          origin: "override",
          loreSource: override.loreSource ?? "Curadoria Kumpas",
        } as PoiContent;
          const enFlag = poiContent.loreEn ? " +EN" : "";
        console.log(`  ${poi.order}. ${poi.name} → override ✔${enFlag}`);
      }

      content.pois[String(poi.order)] = poiContent;
      if (poiContent.origin === "wikipedia") content.coverage.real += 1;
      else if (poiContent.origin === "override") content.coverage.override += 1;
      else content.coverage.fallback += 1;
    }

    // Foto de capa da trilha: primeira POI com imagem + metadados EN.
    const cover = track.pois
      .map((p) => content.pois[String(p.order)])
      .find((c) => c?.imageUrl);
    content.quest = {
      ...(cover?.imageUrl
        ? { imageUrl: cover.imageUrl, imageCredit: cover.imageCredit }
        : {}),
      ...(questsEn[slug]?.title ? { titleEn: questsEn[slug].title } : {}),
      ...(questsEn[slug]?.description
        ? { descriptionEn: questsEn[slug].description }
        : {}),
    };

    await writeFile(
      resolve(CONTENT_DIR, `${slug}.json`),
      `${JSON.stringify(content, null, 2)}\n`,
      "utf8"
    );
    report.push({ slug, ...content.coverage });
  }

  await writeFile(
    resolve(CONTENT_DIR, "coverage.json"),
    `${JSON.stringify(report, null, 2)}\n`,
    "utf8"
  );

  const total = report.reduce((acc, r) => acc + r.total, 0);
  const real = report.reduce((acc, r) => acc + r.real, 0);
  const override = report.reduce((acc, r) => acc + r.override, 0);
  const fallback = report.reduce((acc, r) => acc + r.fallback, 0);

  console.log(
    `\nCobertura: ${real} Wikipédia + ${override} curadoria / ${total} POIs` +
      ` (${fallback} fallback)`
  );
  if (total > 0 && (real + override) / total < 0.8) {
    console.warn("⚠ Cobertura abaixo de 80% — preenche overrides.json e volta a correr.");
  }
}

main().catch((error) => {
  console.error("\nFalha ao gerar conteúdo:", error);
  process.exit(1);
});
