import type { FastifyInstance } from "fastify";
import { prisma } from "../lib/prisma.js";
import { haversine } from "../lib/haversine.js";

const CATEGORIES = ["dica", "aviso", "perigo"] as const;
const MAX_TEXT = 280;
const MAX_DISTANCE_TO_TRACK_M = 500;
const MAX_MESSAGES_PER_HOUR = 5;
const HIDE_REPORTS = 3;

interface PostMessageBody {
  userId: string;
  category: string;
  text: string;
  lat: number;
  lng: number;
}

function parseTrack(value: unknown): Array<[number, number]> {
  if (!Array.isArray(value)) return [];
  return value.filter(
    (p): p is [number, number] =>
      Array.isArray(p) &&
      p.length === 2 &&
      typeof p[0] === "number" &&
      typeof p[1] === "number"
  );
}

function distanceToTrackMeters(
  lat: number,
  lng: number,
  track: Array<[number, number]>
): number {
  if (track.length === 0) return Number.POSITIVE_INFINITY;
  let best = Number.POSITIVE_INFINITY;
  for (const point of track) {
    const distance = haversine(lat, lng, point[0], point[1]);
    if (distance < best) best = distance;
  }
  return best;
}

function serialize(
  message: {
    id: string;
    category: string;
    text: string;
    lat: number;
    lng: number;
    createdAt: Date;
    likeCount: number;
    user: { name: string };
    likes?: Array<{ userId: string }>;
  },
  userId?: string
) {
  return {
    id: message.id,
    category: message.category,
    text: message.text,
    lat: message.lat,
    lng: message.lng,
    createdAt: message.createdAt.toISOString(),
    likeCount: message.likeCount,
    userName: message.user.name,
    likedByMe: userId
      ? (message.likes ?? []).some((like) => like.userId === userId)
      : false,
  };
}

export async function messageRoutes(app: FastifyInstance): Promise<void> {
  // GET /api/quests/:id/messages
  app.get<{ Params: { id: string }; Querystring: { userId?: string } }>(
    "/api/quests/:id/messages",
    async (request, reply) => {
      const userId = request.query.userId;
      const messages = await prisma.trailMessage.findMany({
        where: {
          questId: request.params.id,
          reportCount: { lt: HIDE_REPORTS },
          OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
        },
        orderBy: { createdAt: "desc" },
        take: 100,
        include: {
          user: { select: { name: true } },
          likes: userId
            ? { where: { userId }, select: { userId: true } }
            : false,
        },
      });

      return reply.send(messages.map((m) => serialize(m, userId)));
    }
  );

  // POST /api/quests/:id/messages
  app.post<{ Params: { id: string }; Body: PostMessageBody }>(
    "/api/quests/:id/messages",
    async (request, reply) => {
      const { userId, category, text, lat, lng } = request.body ?? {};

      if (
        !userId ||
        !category ||
        !CATEGORIES.includes(category as (typeof CATEGORIES)[number]) ||
        typeof text !== "string" ||
        typeof lat !== "number" ||
        typeof lng !== "number"
      ) {
        return reply.status(400).send({
          message:
            "Payload inválido. Requer userId, category (dica|aviso|perigo), text, lat, lng.",
        });
      }

      const cleanText = text.trim();
      if (cleanText.length < 3 || cleanText.length > MAX_TEXT) {
        return reply.status(400).send({
          message: `O recado deve ter entre 3 e ${MAX_TEXT} caracteres.`,
        });
      }

      const [quest, user] = await Promise.all([
        prisma.quest.findUnique({
          where: { id: request.params.id },
          select: { id: true, trackPoints: true },
        }),
        prisma.user.findUnique({ where: { id: userId }, select: { id: true } }),
      ]);

      if (!quest) return reply.status(404).send({ message: "Quest não encontrada." });
      if (!user) return reply.status(404).send({ message: "Utilizador não encontrado." });

      const track = parseTrack(quest.trackPoints);
      const distance = distanceToTrackMeters(lat, lng, track);
      if (distance > MAX_DISTANCE_TO_TRACK_M) {
        return reply.status(400).send({
          message: "Só podes deixar recados a menos de 500 m da trilha.",
          distanceMeters: Math.round(distance),
        });
      }

      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
      const recent = await prisma.trailMessage.count({
        where: {
          userId,
          questId: quest.id,
          createdAt: { gte: oneHourAgo },
        },
      });
      if (recent >= MAX_MESSAGES_PER_HOUR) {
        return reply.status(429).send({
          message: "Limite de 5 recados por hora nesta trilha. Tenta mais tarde.",
        });
      }

      const message = await prisma.trailMessage.create({
        data: {
          questId: quest.id,
          userId,
          category,
          text: cleanText,
          lat,
          lng,
        },
        include: { user: { select: { name: true } }, likes: true },
      });

      return reply.send(serialize(message, userId));
    }
  );

  // POST /api/messages/:id/like — toggle
  app.post<{ Params: { id: string }; Body: { userId?: string } }>(
    "/api/messages/:id/like",
    async (request, reply) => {
      const userId = request.body?.userId;
      if (!userId) {
        return reply.status(400).send({ message: "userId é obrigatório." });
      }

      const message = await prisma.trailMessage.findUnique({
        where: { id: request.params.id },
        select: { id: true },
      });
      if (!message) return reply.status(404).send({ message: "Recado não encontrado." });

      const existing = await prisma.trailMessageLike.findUnique({
        where: { userId_messageId: { userId, messageId: message.id } },
      });

      if (existing) {
        await prisma.$transaction([
          prisma.trailMessageLike.delete({ where: { id: existing.id } }),
          prisma.trailMessage.update({
            where: { id: message.id },
            data: { likeCount: { decrement: 1 } },
          }),
        ]);
        const updated = await prisma.trailMessage.findUnique({
          where: { id: message.id },
          select: { likeCount: true },
        });
        return reply.send({ liked: false, likeCount: updated?.likeCount ?? 0 });
      }

      await prisma.$transaction([
        prisma.trailMessageLike.create({
          data: { messageId: message.id, userId },
        }),
        prisma.trailMessage.update({
          where: { id: message.id },
          data: { likeCount: { increment: 1 } },
        }),
      ]);
      const updated = await prisma.trailMessage.findUnique({
        where: { id: message.id },
        select: { likeCount: true },
      });
      return reply.send({ liked: true, likeCount: updated?.likeCount ?? 0 });
    }
  );

  // POST /api/messages/:id/report
  app.post<{ Params: { id: string }; Body: { userId?: string } }>(
    "/api/messages/:id/report",
    async (request, reply) => {
      const userId = request.body?.userId;
      if (!userId) {
        return reply.status(400).send({ message: "userId é obrigatório." });
      }

      const message = await prisma.trailMessage.findUnique({
        where: { id: request.params.id },
        select: { id: true },
      });
      if (!message) return reply.status(404).send({ message: "Recado não encontrado." });

      try {
        await prisma.$transaction([
          prisma.trailMessageReport.create({
            data: { messageId: message.id, userId },
          }),
          prisma.trailMessage.update({
            where: { id: message.id },
            data: { reportCount: { increment: 1 } },
          }),
        ]);
      } catch {
        return reply.status(409).send({ message: "Já denunciaste este recado." });
      }

      return reply.send({ reported: true });
    }
  );
}
