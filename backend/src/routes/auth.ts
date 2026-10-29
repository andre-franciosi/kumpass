import type { FastifyInstance } from "fastify";
import { prisma } from "../lib/prisma.js";

interface LoginBody {
  email: string;
  name?: string;
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function authRoutes(app: FastifyInstance): Promise<void> {
  // POST /api/auth/login — login minimalista do MVP (lookup ou criação por email)
  app.post<{ Body: LoginBody }>("/api/auth/login", async (request, reply) => {
    const email = request.body?.email?.trim().toLowerCase();
    const name = request.body?.name?.trim();

    if (!email || !EMAIL_RE.test(email)) {
      return reply.status(400).send({ message: "Email inválido." });
    }

    const fallbackName = email
      .split("@")[0]
      .replace(/[._-]+/g, " ")
      .replace(/\b\w/g, (c) => c.toUpperCase());

    const user = await prisma.user.upsert({
      where: { email },
      update: name ? { name } : {},
      create: { email, name: name || fallbackName },
    });

    return reply.send({
      id: user.id,
      email: user.email,
      name: user.name,
      isTest: user.isTest,
    });
  });
}
