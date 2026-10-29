import { readFileSync } from "node:fs";

import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

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
  wiki?: {
    wikipedia?: string;
    wikidata?: string;
    description?: string;
    inscription?: string;
  };
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
}

interface TrackContentData {
  slug: string;
  quest?: {
    imageUrl?: string;
    imageCredit?: string;
    titleEn?: string;
    descriptionEn?: string;
  };
  pois: Record<string, PoiContent>;
}

interface TrackMeta {
  title: string;
  description: string;
  region: string;
  terrainFactor: number;
}

/** Metadados editoriais de cada trilha (geometria vem dos JSON de track). */
const TRACK_META: Record<string, TrackMeta> = {
  sintra: {
    title: "Mistérios de Sintra",
    description:
      "Rota real do Palácio da Pena, entre miradouros, memoriais e os caminhos escondidos da serra de Sintra.",
    region: "Sintra",
    terrainFactor: 1.2,
  },
  castelo: {
    title: "Muralhas do Castelo",
    description:
      "Camina por trilhos reais à volta do Castelo dos Mouros, a fortaleza muçulmana do século VIII que vigia a serra há mais de mil anos.",
    region: "Sintra",
    terrainFactor: 1.15,
  },
  arrabida: {
    title: "Segredos da Arrábida",
    description:
      "Subida real ao Alto do Formosinho, o ponto mais alto da serra, entre falésias, fontes e o azul profundo da Arrábida.",
    region: "Arrabida",
    terrainFactor: 1.3,
  },
  portinho: {
    title: "Costa do Portinho",
    description:
      "Trilho costeiro real pelo Portinho da Arrábida, entre o Convento franciscano do século XVI, o Forte de Santa Maria e praias escondidas.",
    region: "Arrabida",
    terrainFactor: 1.25,
  },
  monsanto: {
    title: "Vigia de Monsanto",
    description:
      "Volta real ao planalto de Monsanto, o pulmão verde de Lisboa, entre miradouros, penedos de granito e histórias da cidade.",
    region: "Monsanto",
    terrainFactor: 1.0,
  },
  agua: {
    title: "Caminhos da Água",
    description:
      "A Rota da Água real de Monsanto: fontes, tanques e o traçado que acompanha a água que abasteceu Lisboa desde o Aqueduto das Águas Livres.",
    region: "Monsanto",
    terrainFactor: 1.0,
  },
};

const REVIEWERS = [
  { email: "marta@kumpas.dev", name: "Marta Silva" },
  { email: "joao@kumpas.dev", name: "João Pereira" },
  { email: "ines@kumpas.dev", name: "Inês Costa" },
];

const REVIEWS: Record<string, Array<{ email: string; rating: number; comment: string }>> = {
  "Mistérios de Sintra": [
    { email: "marta@kumpas.dev", rating: 5, comment: "O caminho até à Pena é mágico. O mapa com o track real faz toda a diferença." },
    { email: "joao@kumpas.dev", rating: 4, comment: "Trilha exigente, mas a vista compensa tudo." },
    { email: "ines@kumpas.dev", rating: 5, comment: "Fiz com a família e adorámos os desafios." },
  ],
  "Segredos da Arrábida": [
    { email: "marta@kumpas.dev", rating: 4, comment: "O Formosinho é duro, mas o miradouro é um prémio real." },
    { email: "joao@kumpas.dev", rating: 5, comment: "O melhor pôr do sol que já vi na Arrábida." },
  ],
  "Vigia de Monsanto": [
    { email: "ines@kumpas.dev", rating: 4, comment: "Perfeita para uma manhã tranquila em Lisboa." },
    { email: "joao@kumpas.dev", rating: 3, comment: "Boa para começar, com miradouros surpreendentes." },
  ],
};

function loadTrack(slug: string): TrackData | null {
  try {
    const url = new URL(`./tracks/${slug}.json`, import.meta.url);
    return JSON.parse(readFileSync(url, "utf8")) as TrackData;
  } catch {
    return null;
  }
}

function loadContent(slug: string): TrackContentData | null {
  try {
    const url = new URL(`./content/${slug}.json`, import.meta.url);
    return JSON.parse(readFileSync(url, "utf8")) as TrackContentData;
  } catch {
    return null;
  }
}

/** Estimativa de duração: 3 km/h + 10 min por cada 100 m de subida. */
function estimateDuration(distanceKm: number, elevationGainM: number): number {
  return Math.round((distanceKm / 3) * 60 + (elevationGainM / 100) * 10);
}

async function main(): Promise<void> {
  // Utilizador de teste (id fixo para facilitar o smoke test).
  const user = await prisma.user.upsert({
    where: { email: "tester@kumpas.dev" },
    update: {},
    create: {
      id: "11111111-1111-1111-1111-111111111111",
      email: "tester@kumpas.dev",
      name: "Tester Kumpas",
    },
  });

  // Conta de demonstração com GPS simulado (não usar em produção).
  const gpsUser = await prisma.user.upsert({
    where: { email: "tester.gps@kumpas.dev" },
    update: { isTest: true },
    create: {
      id: "22222222-2222-2222-2222-222222222222",
      email: "tester.gps@kumpas.dev",
      name: "Tester GPS",
      isTest: true,
    },
  });

  const reviewers = [];
  for (const r of REVIEWERS) {
    const created = await prisma.user.upsert({
      where: { email: r.email },
      update: { name: r.name },
      create: r,
    });
    reviewers.push(created);
  }

  const slugs = Object.keys(TRACK_META);

  for (const slug of slugs) {
    const track = loadTrack(slug);
    if (!track) {
      console.log(`[${slug}] sem track JSON (corre 'make tracks') — a ignorar.`);
      continue;
    }
    const meta = TRACK_META[slug];
    const content = loadContent(slug);

    const durationMin = estimateDuration(track.distanceKm, track.elevationGainM);

    const data = {
      titleEn: content?.quest?.titleEn ?? null,
      description: meta.description,
      descriptionEn: content?.quest?.descriptionEn ?? null,
      region: meta.region,
      distanceKm: track.distanceKm,
      durationMin,
      elevationGainM: track.elevationGainM,
      terrainFactor: meta.terrainFactor,
      // Foto real (Commons/Wikipédia); sem foto, o app usa o gradiente.
      imageUrl: content?.quest?.imageUrl ?? null,
      imageCredit: content?.quest?.imageCredit ?? null,
      trackPoints: track.trackPoints,
      regionBounds: track.bbox,
    };

    const existing = await prisma.quest.findFirst({ where: { title: meta.title } });

    let questId: string;
    if (existing) {
      const updated = await prisma.quest.update({
        where: { id: existing.id },
        data,
      });
      questId = updated.id;
    } else {
      const created = await prisma.quest.create({
        data: { title: meta.title, ...data },
      });
      questId = created.id;
    }

    console.log(
      `[${meta.title}] track ${track.trackPoints.length} pts · ${track.distanceKm} km · ` +
        `${track.elevationGainM} m D+ · ${durationMin} min · ${track.pois.length} POIs`
    );

    // Atualiza checkpoints por `order` (preserva IDs e progresso existente).
    const current = await prisma.checkpoint.findMany({ where: { questId } });

    for (const poi of track.pois) {
      const contentPoi = content?.pois[String(poi.order)];

      const checkpoint = {
        order: poi.order,
        title: poi.name,
        titleEn: contentPoi?.titleEn ?? null,
        lore: contentPoi?.lore ?? poi.lore,
        loreEn: contentPoi?.loreEn ?? null,
        loreSource: contentPoi?.loreSource ?? null,
        loreSourceEn: contentPoi?.loreSourceEn ?? null,
        loreUrl: contentPoi?.loreUrl ?? null,
        loreUrlEn: contentPoi?.loreUrlEn ?? null,
        imageUrl: contentPoi?.imageUrl ?? null,
        imageCredit: contentPoi?.imageCredit ?? null,
        lat: poi.lat,
        lng: poi.lng,
        radiusMeters: poi.radiusMeters,
      };

      const match = current.find((c) => c.order === poi.order);
      if (match) {
        await prisma.checkpoint.update({
          where: { id: match.id },
          data: checkpoint,
        });
      } else {
        await prisma.checkpoint.create({ data: { ...checkpoint, questId } });
      }
    }

    const validOrders = new Set(track.pois.map((p) => p.order));
    const obsolete = current.filter((c) => !validOrders.has(c.order));
    if (obsolete.length > 0) {
      await prisma.checkpoint.deleteMany({
        where: { id: { in: obsolete.map((c) => c.id) } },
      });
    }
  }

  // Reviews de exemplo (idempotentes por userId + questId).
  for (const slug of slugs) {
    const meta = TRACK_META[slug];
    const quest = await prisma.quest.findFirst({ where: { title: meta.title } });
    if (!quest) continue;

    for (const review of REVIEWS[meta.title] ?? []) {
      const reviewer = reviewers.find((r) => r.email === review.email);
      if (!reviewer) continue;

      await prisma.review.upsert({
        where: {
          userId_questId: { userId: reviewer.id, questId: quest.id },
        },
        update: { rating: review.rating, comment: review.comment },
        create: {
          userId: reviewer.id,
          questId: quest.id,
          rating: review.rating,
          comment: review.comment,
        },
      });
    }

    const aggregate = await prisma.review.aggregate({
      where: { questId: quest.id },
      _avg: { rating: true },
      _count: { rating: true },
    });
    await prisma.quest.update({
      where: { id: quest.id },
      data: {
        ratingAvg: aggregate._avg.rating ?? 0,
        ratingCount: aggregate._count.rating,
      },
    });
  }

  const rewards = [
    { title: "Café Grátis", partner: "Café Central Sintra", code: "KUMPAS-CAFE-01", stock: 100 },
    { title: "10% Desconto", partner: "Adega da Arrábida", code: "KUMPAS-ADE-10", stock: 50 },
    { title: "Visita Guiada", partner: "Monsanto Tours", code: "KUMPAS-TOUR-01", stock: 25 },
  ];

  for (const r of rewards) {
    const existing = await prisma.reward.findFirst({ where: { code: r.code } });
    if (existing) continue;
    await prisma.reward.create({ data: r });
  }

  // Recados reais de exemplo (idempotentes): deixados junto ao 1.º checkpoint.
  const SEED_MESSAGES: Record<string, Array<{ email: string; category: string; text: string }>> = {
    "Mistérios de Sintra": [
      {
        email: "marta@kumpas.dev",
        category: "dica",
        text: "O miradouro da Vigia é melhor ao fim da tarde. Leva água: a subida aquece.",
      },
      {
        email: "joao@kumpas.dev",
        category: "aviso",
        text: "Piso escorregadio junto à fonte depois da chuva. Atenção aos degraus.",
      },
    ],
    "Muralhas do Castelo": [
      {
        email: "ines@kumpas.dev",
        category: "perigo",
        text: "Nas muralhas o vento é forte e não há proteção. Não te aproximes da borda.",
      },
      {
        email: "marta@kumpas.dev",
        category: "dica",
        text: "A entrada do Poço Iniciático tem fila ao meio-dia. Vai cedo.",
      },
    ],
    "Segredos da Arrábida": [
      {
        email: "joao@kumpas.dev",
        category: "aviso",
        text: "No Formosinho o nevoeiro fecha rápido. Leva corta-vento e mapa offline.",
      },
    ],
    "Costa do Portinho": [
      {
        email: "ines@kumpas.dev",
        category: "dica",
        text: "A praia escondida só aparece na maré baixa. Confirma a tábua antes de descer.",
      },
    ],
    "Vigia de Monsanto": [
      {
        email: "marta@kumpas.dev",
        category: "dica",
        text: "O miradouro do moinho é ótimo para o pôr do sol sobre o Tejo.",
      },
    ],
    "Caminhos da Água": [
      {
        email: "joao@kumpas.dev",
        category: "aviso",
        text: "A fonte do percurso pode estar seca no verão. Leva água de casa.",
      },
    ],
  };

  for (const slug of slugs) {
    const meta = TRACK_META[slug];
    const quest = await prisma.quest.findFirst({
      where: { title: meta.title },
      include: { checkpoints: { orderBy: { order: "asc" }, take: 1 } },
    });
    if (!quest || quest.checkpoints.length === 0) continue;
    const point = quest.checkpoints[0];

    for (const message of SEED_MESSAGES[meta.title] ?? []) {
      const author = reviewers.find((r) => r.email === message.email);
      if (!author) continue;
      const exists = await prisma.trailMessage.findFirst({
        where: { questId: quest.id, text: message.text },
      });
      if (exists) continue;
      await prisma.trailMessage.create({
        data: {
          questId: quest.id,
          userId: author.id,
          category: message.category,
          text: message.text,
          lat: point.lat,
          lng: point.lng,
          likeCount: message.category === "dica" ? 2 : 0,
        },
      });
    }
  }

  const questCount = await prisma.quest.count();
  const checkpointCount = await prisma.checkpoint.count();
  const reviewCount = await prisma.review.count();
  const messageCount = await prisma.trailMessage.count();
  const withSource = await prisma.checkpoint.count({ where: { loreSource: { not: "Fallback" } } });
  const withImage = await prisma.checkpoint.count({ where: { imageUrl: { not: null } } });

  console.log(`Seed concluído.`);
  console.log(`  User de teste: ${user.id} (${user.email})`);
  console.log(
    `  Quests: ${questCount} | Checkpoints: ${checkpointCount} | Reviews: ${reviewCount}`
  );
  console.log(
    `  Conteúdo real: ${withSource}/${checkpointCount} checkpoints com fonte | ` +
      `${withImage} com foto`
  );
  console.log(`  Recados: ${messageCount}`);
  console.log(`  Test user GPS: ${gpsUser.id} (${gpsUser.email})`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
