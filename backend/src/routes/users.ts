import type { FastifyInstance } from "fastify";
import { prisma } from "../lib/prisma.js";
import {
  CHECKPOINT_XP,
  levelFromXp,
  questDifficulty,
  questXp,
} from "../lib/difficulty.js";
import { computeBadges } from "../lib/badges.js";

export async function userRoutes(app: FastifyInstance): Promise<void> {
  // GET /api/users/:id/profile — gamificação: XP, nível, badges e progresso
  app.get<{ Params: { id: string } }>(
    "/api/users/:id/profile",
    async (request, reply) => {
      const userId = request.params.id;

      const user = await prisma.user.findUnique({
        where: { id: userId },
        include: {
          progress: true,
          checkpoints: { select: { checkpoint: { select: { questId: true } } } },
        },
      });

      if (!user) {
        return reply.status(404).send({ message: "Utilizador não encontrado." });
      }

      const [quests, reviewsWritten] = await Promise.all([
        prisma.quest.findMany({
          include: { checkpoints: { select: { id: true } } },
        }),
        prisma.review.count({ where: { userId } }),
      ]);

      const completedIds = new Set(
        user.progress.filter((p) => p.completed).map((p) => p.questId)
      );

      const unlockedCheckpoints = user.checkpoints.length;

      let xp = unlockedCheckpoints * CHECKPOINT_XP;
      const progress = [];
      const completedRegions = new Set<string>();

      for (const quest of quests) {
        const unlockedCount = user.checkpoints.filter(
          (c) => c.checkpoint.questId === quest.id
        ).length;
        const completed = completedIds.has(quest.id);
        const difficulty = questDifficulty({
          distanceKm: quest.distanceKm,
          durationMin: quest.durationMin,
          elevationGainM: quest.elevationGainM,
          checkpointCount: quest.checkpoints.length,
          terrainFactor: quest.terrainFactor,
        });

        if (completed) {
          xp += questXp(quest.checkpoints.length, difficulty.level);
          completedRegions.add(quest.region);
        }

        progress.push({
          questId: quest.id,
          title: quest.title,
          region: quest.region,
          completed,
          unlockedCount,
          totalCheckpoints: quest.checkpoints.length,
          difficulty: difficulty.level,
          difficultyLabel: difficulty.label,
        });
      }

      const levelInfo = levelFromXp(xp);
      const totalCheckpoints = quests.reduce(
        (sum, q) => sum + q.checkpoints.length,
        0
      );

      return reply.send({
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          isTest: user.isTest,
        },
        xp,
        ...levelInfo,
        completedQuests: completedIds.size,
        totalQuests: quests.length,
        unlockedCheckpoints,
        totalCheckpoints,
        reviewsWritten,
        badges: computeBadges({
          unlockedCheckpoints,
          completedQuestIds: [...completedIds],
          completedRegions: [...completedRegions],
          reviewsWritten,
          sunnyCompletions: user.progress.filter((p) => p.sunnyCompletion).length,
        }),
        progress,
      });
    }
  );
}
