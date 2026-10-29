import Fastify from "fastify";
import cors from "@fastify/cors";
import { questRoutes } from "./routes/quests.js";
import { reviewRoutes } from "./routes/reviews.js";
import { checkpointRoutes } from "./routes/checkpoints.js";
import { userRoutes } from "./routes/users.js";
import { authRoutes } from "./routes/auth.js";
import { weatherRoutes } from "./routes/weather.js";
import { messageRoutes } from "./routes/messages.js";
import { prisma } from "./lib/prisma.js";

const app = Fastify({ logger: true });

// CORS aberto para desenvolvimento (Flutter web / emulador).
await app.register(cors, { origin: true });

app.get("/health", async () => ({ status: "ok" }));

await app.register(questRoutes);
await app.register(reviewRoutes);
await app.register(checkpointRoutes);
await app.register(userRoutes);
await app.register(authRoutes);
await app.register(weatherRoutes);
await app.register(messageRoutes);

const shutdown = async (): Promise<void> => {
  await app.close();
  await prisma.$disconnect();
  process.exit(0);
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

const PORT = Number(process.env.PORT ?? 3000);

try {
  await app.listen({ port: PORT, host: "0.0.0.0" });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
