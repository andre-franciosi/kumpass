import type { FastifyInstance } from "fastify";
import { prisma } from "../lib/prisma.js";
import { haversine } from "../lib/haversine.js";
import {
  CHECKPOINT_XP,
  questDifficulty,
  questXp,
} from "../lib/difficulty.js";
import { fetchForecast, scoreDay } from "../lib/weather.js";

interface UnlockBody {
  userId: string;
  checkpointId: string;
  userLat: number;
  userLng: number;
  lang?: string;
}

export async function checkpointRoutes(app: FastifyInstance): Promise<void> {
  // POST /api/checkpoints/unlock
  app.post<{ Body: UnlockBody }>("/api/checkpoints/unlock", async (request, reply) => {
    const { userId, checkpointId, userLat, userLng } = request.body ?? {};
    const lang = request.body?.lang === "en" ? "en" : "pt";

    if (
      !userId ||
      !checkpointId ||
      typeof userLat !== "number" ||
      typeof userLng !== "number"
    ) {
      return reply.status(400).send({
        success: false,
        message: "Payload inválido. Requer userId, checkpointId, userLat, userLng.",
      });
    }

    const [checkpoint, user] = await Promise.all([
      prisma.checkpoint.findUnique({
        where: { id: checkpointId },
        include: {
          quest: {
            include: {
              checkpoints: { select: { id: true, lat: true, lng: true } },
            },
          },
        },
      }),
      prisma.user.findUnique({ where: { id: userId }, select: { id: true } }),
    ]);

    if (!checkpoint) {
      return reply.status(404).send({
        success: false,
        message: "Checkpoint não encontrado.",
      });
    }

    if (!user) {
      return reply.status(404).send({
        success: false,
        message: "Utilizador não encontrado.",
      });
    }

    const distanceMeters = haversine(
      userLat,
      userLng,
      checkpoint.lat,
      checkpoint.lng
    );

    if (distanceMeters > checkpoint.radiusMeters) {
      return reply.status(400).send({
        success: false,
        message: "Fora do raio de alcance.",
        distanceMeters: Math.round(distanceMeters),
        requiredMeters: checkpoint.radiusMeters,
      });
    }

    const alreadyUnlocked = await prisma.userCheckpoint.findUnique({
      where: { userId_checkpointId: { userId, checkpointId } },
    });

    // Idempotente: cria apenas se ainda não existir.
    await prisma.userCheckpoint.upsert({
      where: {
        userId_checkpointId: { userId, checkpointId },
      },
      update: {},
      create: { userId, checkpointId },
    });

    const totalCheckpoints = checkpoint.quest.checkpoints.length;
    const unlockedCount = await prisma.userCheckpoint.count({
      where: { userId, checkpoint: { questId: checkpoint.questId } },
    });

    const justCompleted = unlockedCount === totalCheckpoints;

    // Badge "Caçador de Sol": concluir num dia com condições ideais.
    let sunnyCompletion: boolean | undefined;
    if (justCompleted && !alreadyUnlocked) {
      const points = checkpoint.quest.checkpoints;
      const center =
        points.length > 0
          ? {
              lat: points.reduce((sum, c) => sum + c.lat, 0) / points.length,
              lng: points.reduce((sum, c) => sum + c.lng, 0) / points.length,
            }
          : { lat: checkpoint.lat, lng: checkpoint.lng };

      try {
        const days = await fetchForecast(center.lat, center.lng, { days: 1 });
        sunnyCompletion = days.length > 0 && scoreDay(days[0]).rating === "Ideal";
      } catch {
        sunnyCompletion = false;
      }
    }

    // Atualiza progresso da quest associada (e conclui quando todos validados).
    const progress = await prisma.userProgress.upsert({
      where: { userId_questId: { userId, questId: checkpoint.questId } },
      update: justCompleted
        ? {
            completed: true,
            ...(sunnyCompletion !== undefined ? { sunnyCompletion } : {}),
          }
        : {},
      create: {
        userId,
        questId: checkpoint.questId,
        completed: justCompleted,
        sunnyCompletion: sunnyCompletion ?? false,
      },
    });

    const difficulty = questDifficulty({
      distanceKm: checkpoint.quest.distanceKm,
      durationMin: checkpoint.quest.durationMin,
      elevationGainM: checkpoint.quest.elevationGainM,
      checkpointCount: totalCheckpoints,
      terrainFactor: checkpoint.quest.terrainFactor,
    });

    const xpGained =
      (alreadyUnlocked ? 0 : CHECKPOINT_XP) +
      (justCompleted ? questXp(totalCheckpoints, difficulty.level) : 0);

    return reply.send({
      success: true,
      distanceMeters: Math.round(distanceMeters),
      alreadyUnlocked: Boolean(alreadyUnlocked),
      xpGained,
      lore: {
        title:
          lang === "en"
            ? checkpoint.titleEn ?? checkpoint.title
            : checkpoint.title,
        content: lang === "en" ? checkpoint.loreEn ?? checkpoint.lore : checkpoint.lore,
        source:
          lang === "en"
            ? checkpoint.loreSourceEn ?? checkpoint.loreSource
            : checkpoint.loreSource,
      },
      quest: {
        id: checkpoint.questId,
        unlockedCount,
        totalCheckpoints,
        completed: progress.completed,
        difficulty: difficulty.level,
        difficultyLabel: difficulty.label,
      },
    });
  });
}
