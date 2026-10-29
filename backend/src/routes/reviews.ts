import type { FastifyInstance } from "fastify";
import { prisma } from "../lib/prisma.js";

interface ReviewBody {
  userId: string;
  rating: number;
  comment?: string;
}

async function refreshQuestRating(questId: string): Promise<void> {
  const aggregate = await prisma.review.aggregate({
    where: { questId },
    _avg: { rating: true },
    _count: { rating: true },
  });

  await prisma.quest.update({
    where: { id: questId },
    data: {
      ratingAvg: aggregate._avg.rating ?? 0,
      ratingCount: aggregate._count.rating,
    },
  });
}

export async function reviewRoutes(app: FastifyInstance): Promise<void> {
  // GET /api/quests/:id/reviews
  app.get<{ Params: { id: string } }>(
    "/api/quests/:id/reviews",
    async (request, reply) => {
      const reviews = await prisma.review.findMany({
        where: { questId: request.params.id },
        orderBy: { updatedAt: "desc" },
        include: { user: { select: { name: true } } },
      });

      return reply.send(
        reviews.map((r) => ({
          id: r.id,
          rating: r.rating,
          comment: r.comment,
          userName: r.user.name,
          updatedAt: r.updatedAt.toISOString(),
        }))
      );
    }
  );

  // POST /api/quests/:id/reviews — cria ou atualiza (1 review por utilizador)
  app.post<{ Params: { id: string }; Body: ReviewBody }>(
    "/api/quests/:id/reviews",
    async (request, reply) => {
      const questId = request.params.id;
      const { userId, rating, comment } = request.body ?? {};

      if (!userId || typeof rating !== "number" || rating < 1 || rating > 5) {
        return reply.status(400).send({
          message: "Payload inválido. Requer userId e rating entre 1 e 5.",
        });
      }

      const [quest, user] = await Promise.all([
        prisma.quest.findUnique({ where: { id: questId }, select: { id: true } }),
        prisma.user.findUnique({ where: { id: userId }, select: { id: true } }),
      ]);

      if (!quest) return reply.status(404).send({ message: "Quest não encontrada." });
      if (!user) return reply.status(404).send({ message: "Utilizador não encontrado." });

      const review = await prisma.review.upsert({
        where: { userId_questId: { userId, questId } },
        update: { rating, comment: comment?.trim() || null },
        create: { userId, questId, rating, comment: comment?.trim() || null },
        include: { user: { select: { name: true } } },
      });

      await refreshQuestRating(questId);

      return reply.send({
        id: review.id,
        rating: review.rating,
        comment: review.comment,
        userName: review.user.name,
        updatedAt: review.updatedAt.toISOString(),
      });
    }
  );
}
