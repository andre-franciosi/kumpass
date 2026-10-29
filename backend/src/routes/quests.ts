import type { FastifyInstance } from "fastify";
import { prisma } from "../lib/prisma.js";
import { questDifficulty, questXp } from "../lib/difficulty.js";

type QuestStatus = "not_started" | "active" | "completed";

interface Bounds {
  minLat: number;
  minLng: number;
  maxLat: number;
  maxLng: number;
}

type TrackPoint = [number, number];

interface UserQuestProgress {
  completedIds: Set<string>;
  unlockedByQuest: Map<string, number>;
}

const REGION_CENTERS: Record<string, { lat: number; lng: number }> = {
  Sintra: { lat: 38.7974, lng: -9.3906 },
  Arrabida: { lat: 38.4795, lng: -8.9932 },
  Monsanto: { lat: 38.7331, lng: -9.1872 },
};

function parseBounds(value: unknown): Bounds | null {
  if (!value || typeof value !== "object") return null;
  const b = value as Record<string, unknown>;
  const values = [b.minLat, b.minLng, b.maxLat, b.maxLng];
  if (!values.every((v) => typeof v === "number")) return null;
  return {
    minLat: b.minLat as number,
    minLng: b.minLng as number,
    maxLat: b.maxLat as number,
    maxLng: b.maxLng as number,
  };
}

function parseTrack(value: unknown): TrackPoint[] {
  if (!Array.isArray(value)) return [];
  return value.filter(
    (p): p is TrackPoint =>
      Array.isArray(p) &&
      p.length === 2 &&
      typeof p[0] === "number" &&
      typeof p[1] === "number"
  );
}

function centerOf(
  checkpoints: Array<{ lat: number; lng: number }>,
  region: string,
  bounds: Bounds | null
) {
  if (bounds) {
    return {
      lat: (bounds.minLat + bounds.maxLat) / 2,
      lng: (bounds.minLng + bounds.maxLng) / 2,
    };
  }
  if (checkpoints.length === 0) {
    return REGION_CENTERS[region] ?? { lat: 38.72, lng: -9.14 };
  }
  const lat = checkpoints.reduce((sum, c) => sum + c.lat, 0) / checkpoints.length;
  const lng = checkpoints.reduce((sum, c) => sum + c.lng, 0) / checkpoints.length;
  return { lat, lng };
}

async function loadUserProgress(userId?: string): Promise<UserQuestProgress> {
  if (!userId) {
    return { completedIds: new Set(), unlockedByQuest: new Map() };
  }

  const [progress, unlocked] = await Promise.all([
    prisma.userProgress.findMany({ where: { userId } }),
    prisma.userCheckpoint.findMany({
      where: { userId },
      select: { checkpoint: { select: { questId: true } } },
    }),
  ]);

  const unlockedByQuest = new Map<string, number>();
  for (const row of unlocked) {
    const questId = row.checkpoint.questId;
    unlockedByQuest.set(questId, (unlockedByQuest.get(questId) ?? 0) + 1);
  }

  return {
    completedIds: new Set(progress.filter((p) => p.completed).map((p) => p.questId)),
    unlockedByQuest,
  };
}

function statusFor(
  questId: string,
  progress: UserQuestProgress
): { status: QuestStatus; unlockedCount: number } {
  const unlockedCount = progress.unlockedByQuest.get(questId) ?? 0;
  const completed = progress.completedIds.has(questId);
  const status: QuestStatus = completed
    ? "completed"
    : unlockedCount > 0
      ? "active"
      : "not_started";
  return { status, unlockedCount };
}

type Lang = "pt" | "en";

function parseLang(value: string | undefined): Lang {
  return value === "en" ? "en" : "pt";
}

function summarize(
  quest: {
    id: string;
    title: string;
    titleEn: string | null;
    description: string;
    descriptionEn: string | null;
    region: string;
    distanceKm: number;
    durationMin: number;
    elevationGainM: number;
    terrainFactor: number;
    imageUrl: string | null;
    imageCredit: string | null;
    ratingAvg: number;
    ratingCount: number;
    trackPoints: unknown;
    regionBounds: unknown;
    checkpoints: Array<{ lat: number; lng: number }>;
  },
  progress: UserQuestProgress,
  lang: Lang = "pt"
) {
  const checkpointCount = quest.checkpoints.length;
  const bounds = parseBounds(quest.regionBounds);
  const track = parseTrack(quest.trackPoints);
  const difficulty = questDifficulty({
    distanceKm: quest.distanceKm,
    durationMin: quest.durationMin,
    elevationGainM: quest.elevationGainM,
    checkpointCount,
    terrainFactor: quest.terrainFactor,
  });
  const { status, unlockedCount } = statusFor(quest.id, progress);

  return {
    id: quest.id,
    title: lang === "en" ? quest.titleEn ?? quest.title : quest.title,
    description:
      lang === "en" ? quest.descriptionEn ?? quest.description : quest.description,
    region: quest.region,
    imageUrl: quest.imageUrl,
    imageCredit: quest.imageCredit,
    checkpointCount,
    distanceKm: quest.distanceKm,
    durationMin: quest.durationMin,
    elevationGainM: quest.elevationGainM,
    difficulty: difficulty.level,
    difficultyLabel: difficulty.label,
    difficultyScore: difficulty.score,
    xpReward: questXp(checkpointCount, difficulty.level),
    ratingAvg: Math.round(quest.ratingAvg * 10) / 10,
    ratingCount: quest.ratingCount,
    center: centerOf(quest.checkpoints, quest.region, bounds),
    bbox: bounds,
    hasTrack: track.length > 1,
    userStatus: {
      status,
      unlockedCount,
      completed: status === "completed",
    },
  };
}

export async function questRoutes(app: FastifyInstance): Promise<void> {
  // GET /api/quests — listagem para o mapa + lista da Home
  app.get<{ Querystring: { userId?: string; lang?: string } }>(
    "/api/quests",
    async (request, reply) => {
    const userId = request.query.userId;
    const lang = parseLang(request.query.lang);
    const [quests, progress] = await Promise.all([
      prisma.quest.findMany({
        orderBy: { title: "asc" },
        include: { checkpoints: { select: { lat: true, lng: true } } },
      }),
      loadUserProgress(userId),
    ]);

    return reply.send(quests.map((q) => summarize(q, progress, lang)));
  });

  // GET /api/quests/:id — detalhe com checkpoints, reviews e progresso
  app.get<{
    Params: { id: string };
    Querystring: { userId?: string; lang?: string };
  }>("/api/quests/:id", async (request, reply) => {
      const userId = request.query.userId;
      const lang = parseLang(request.query.lang);
      const quest = await prisma.quest.findUnique({
        where: { id: request.params.id },
        include: {
          checkpoints: { orderBy: { order: "asc" } },
          reviews: {
            orderBy: { updatedAt: "desc" },
            take: 3,
            include: { user: { select: { name: true } } },
          },
        },
      });

      if (!quest) {
        return reply.status(404).send({ message: "Quest não encontrada." });
      }

      const progress = await loadUserProgress(userId);
      const summary = summarize(quest, progress, lang);

      const unlockedIds = userId
        ? (
            await prisma.userCheckpoint.findMany({
              where: { userId, checkpoint: { questId: quest.id } },
              select: { checkpointId: true },
            })
          ).map((u) => u.checkpointId)
        : [];

      const userReview = userId
        ? await prisma.review.findUnique({
            where: { userId_questId: { userId, questId: quest.id } },
          })
        : null;

      return reply.send({
        ...summary,
        terrainFactor: quest.terrainFactor,
        track: parseTrack(quest.trackPoints),
        difficultyBreakdown: {
          distanceKm: quest.distanceKm,
          durationMin: quest.durationMin,
          elevationGainM: quest.elevationGainM,
          checkpointCount: quest.checkpoints.length,
          terrainFactor: quest.terrainFactor,
          score: summary.difficultyScore,
        },
        checkpoints: quest.checkpoints.map((c) => ({
          id: c.id,
          order: c.order,
          title: lang === "en" ? c.titleEn ?? c.title : c.title,
          lore: lang === "en" ? c.loreEn ?? c.lore : c.lore,
          loreSource: lang === "en" ? c.loreSourceEn ?? c.loreSource : c.loreSource,
          loreUrl: lang === "en" ? c.loreUrlEn ?? c.loreUrl : c.loreUrl,
          imageUrl: c.imageUrl,
          imageCredit: c.imageCredit,
          lat: c.lat,
          lng: c.lng,
          radiusMeters: c.radiusMeters,
        })),
        reviews: quest.reviews.map((r) => ({
          id: r.id,
          rating: r.rating,
          comment: r.comment,
          userName: r.user.name,
          updatedAt: r.updatedAt.toISOString(),
        })),
        userReview,
        unlockedCheckpointIds: unlockedIds,
      });
    }
  );
}
