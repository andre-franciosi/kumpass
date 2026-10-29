import type { FastifyInstance } from "fastify";
import { prisma } from "../lib/prisma.js";
import {
  MAX_FORECAST_DAYS,
  bestDays,
  daysBetween,
  fetchForecast,
  isValidDate,
  scoreDay,
} from "../lib/weather.js";

interface WeatherQuery {
  lat?: string;
  lng?: string;
  date?: string;
  lang?: string;
}

function parseLang(value: string | undefined): "pt" | "en" {
  return value === "en" ? "en" : "pt";
}

interface Bounds {
  minLat: number;
  minLng: number;
  maxLat: number;
  maxLng: number;
}

function parseBounds(value: unknown): Bounds | null {
  if (!value || typeof value !== "object") return null;
  const b = value as Record<string, unknown>;
  if (
    typeof b.minLat !== "number" ||
    typeof b.minLng !== "number" ||
    typeof b.maxLat !== "number" ||
    typeof b.maxLng !== "number"
  ) {
    return null;
  }
  return {
    minLat: b.minLat,
    minLng: b.minLng,
    maxLat: b.maxLat,
    maxLng: b.maxLng,
  };
}

export async function weatherRoutes(app: FastifyInstance): Promise<void> {
  // GET /api/weather?lat=&lng=&date=YYYY-MM-DD
  app.get<{ Querystring: WeatherQuery }>("/api/weather", async (request, reply) => {
    const { lat: latRaw, lng: lngRaw, date } = request.query;
    const lang = parseLang(request.query.lang);
    const lat = Number(latRaw);
    const lng = Number(lngRaw);

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return reply.status(400).send({ message: "lat e lng são obrigatórios." });
    }
    if (!isValidDate(date)) {
      return reply.status(400).send({ message: "date deve ser YYYY-MM-DD." });
    }

    const offset = daysBetween(date);
    if (offset < 0) {
      return reply.status(400).send({ message: "Não há previsão para datas passadas." });
    }
    if (offset >= MAX_FORECAST_DAYS) {
      return reply.status(400).send({
        message: `A previsão só está disponível para os próximos ${MAX_FORECAST_DAYS} dias.`,
      });
    }

    try {
      const days = await fetchForecast(lat, lng, {
        startDate: date,
        endDate: date,
        days: 1,
      });
      if (days.length === 0) {
        return reply.status(404).send({ message: "Sem previsão para esta data." });
      }
      return reply.send({ weather: scoreDay(days[0], lang) });
    } catch (error) {
      app.log.warn(error);
      return reply
        .status(502)
        .send({ message: "Meteorologia indisponível. Tenta novamente." });
    }
  });

  // GET /api/quests/:id/best-days — melhores dias nos próximos 16 dias
  app.get<{ Params: { id: string }; Querystring: { lang?: string } }>(
    "/api/quests/:id/best-days",
    async (request, reply) => {
      const lang = parseLang(request.query.lang);
      const quest = await prisma.quest.findUnique({
        where: { id: request.params.id },
        include: { checkpoints: { select: { lat: true, lng: true } } },
      });

      if (!quest) {
        return reply.status(404).send({ message: "Quest não encontrada." });
      }

      const bounds = parseBounds(quest.regionBounds);
      const center = bounds
        ? {
            lat: (bounds.minLat + bounds.maxLat) / 2,
            lng: (bounds.minLng + bounds.maxLng) / 2,
          }
        : quest.checkpoints.length > 0
          ? {
              lat:
                quest.checkpoints.reduce((sum, c) => sum + c.lat, 0) /
                quest.checkpoints.length,
              lng:
                quest.checkpoints.reduce((sum, c) => sum + c.lng, 0) /
                quest.checkpoints.length,
            }
          : { lat: 38.72, lng: -9.14 };

      try {
        const days = await fetchForecast(center.lat, center.lng, {
          days: MAX_FORECAST_DAYS,
        });
        return reply.send({
          center,
          days: bestDays(days, 5, lang),
        });
      } catch (error) {
        app.log.warn(error);
        return reply.status(502).send({
          message: "Meteorologia indisponível. Tenta novamente.",
        });
      }
    }
  );
}
