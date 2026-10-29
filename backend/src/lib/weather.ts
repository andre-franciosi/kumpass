/**
 * Meteorologia via Open-Meteo (sem API key).
 * Cache em memória de 30 min para não abusar do serviço público.
 */

export interface DailyWeather {
  date: string;
  tempMax: number;
  tempMin: number;
  precipProb: number;
  windMax: number;
  weathercode: number;
  label: string;
}

export type WeatherRating = "Ideal" | "Bom" | "Evitar";

export interface ScoredWeather extends DailyWeather {
  score: number;
  rating: WeatherRating;
  reason: string;
  advice: string[];
}

interface OpenMeteoResponse {
  daily?: {
    time?: string[];
    temperature_2m_max?: number[];
    temperature_2m_min?: number[];
    precipitation_probability_max?: number[];
    wind_speed_10m_max?: number[];
    weathercode?: number[];
  };
}

const CACHE_TTL_MS = 30 * 60 * 1000;
const MAX_FORECAST_DAYS = 16;

const cache = new Map<string, { expiresAt: number; data: DailyWeather[] }>();

export function weatherLabel(code: number): string {
  if (code === 0) return "Céu limpo";
  if (code <= 2) return "Pouco nublado";
  if (code === 3) return "Nublado";
  if (code === 45 || code === 48) return "Nevoeiro";
  if (code >= 51 && code <= 57) return "Chuvisco";
  if (code >= 61 && code <= 67) return "Chuva";
  if (code >= 71 && code <= 77) return "Neve";
  if (code >= 80 && code <= 82) return "Aguaceiros";
  if (code >= 95) return "Trovoada";
  return "Condições variáveis";
}

export interface ForecastOptions {
  startDate?: string;
  endDate?: string;
  days?: number;
}

export async function fetchForecast(
  lat: number,
  lng: number,
  options: ForecastOptions = {}
): Promise<DailyWeather[]> {
  const days = Math.min(Math.max(options.days ?? MAX_FORECAST_DAYS, 1), MAX_FORECAST_DAYS);
  const key = `${lat.toFixed(3)}|${lng.toFixed(3)}|${options.startDate ?? ""}|${options.endDate ?? ""}|${days}`;

  const cached = cache.get(key);
  if (cached && cached.expiresAt > Date.now()) return cached.data;

  const params = new URLSearchParams({
    latitude: lat.toFixed(4),
    longitude: lng.toFixed(4),
    daily:
      "temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,weathercode",
    timezone: "Europe/Lisbon",
  });

  if (options.startDate && options.endDate) {
    params.set("start_date", options.startDate);
    params.set("end_date", options.endDate);
  } else {
    params.set("forecast_days", String(days));
  }

  const response = await fetch(
    `https://api.open-meteo.com/v1/forecast?${params.toString()}`,
    {
      headers: { "User-Agent": "Kumpas/1.0 (dev@kumpas.dev)" },
      signal: AbortSignal.timeout(20_000),
    }
  );

  if (!response.ok) {
    throw new Error(`Open-Meteo respondeu HTTP ${response.status}`);
  }

  const json = (await response.json()) as OpenMeteoResponse;
  const daily = json.daily;
  if (!daily?.time?.length) throw new Error("Open-Meteo sem dados diários.");

  const data: DailyWeather[] = daily.time.map((date, index) => {
    const code = daily.weathercode?.[index] ?? 3;
    return {
      date,
      tempMax: daily.temperature_2m_max?.[index] ?? 0,
      tempMin: daily.temperature_2m_min?.[index] ?? 0,
      precipProb: daily.precipitation_probability_max?.[index] ?? 0,
      windMax: daily.wind_speed_10m_max?.[index] ?? 0,
      weathercode: code,
      label: weatherLabel(code),
    };
  });

  cache.set(key, { expiresAt: Date.now() + CACHE_TTL_MS, data });
  return data;
}

type Lang = "pt" | "en";

interface WeatherCopy {
  rain: (v: number) => string;
  rainRisk: (v: number) => string;
  heat: (v: number) => string;
  cold: (v: number) => string;
  wind: (v: number) => string;
  storm: string;
  fog: string;
  allGood: string;
  takeRainGear: string;
  takeLightCover: string;
  water: string;
  warmLayer: string;
  avoidRidges: string;
  windbreaker: string;
  postponeStorm: string;
  fogLight: string;
}

const COPY: Record<Lang, WeatherCopy> = {
  pt: {
    rain: (v) => `chuva ${v}%`,
    rainRisk: (v) => `risco de chuva ${v}%`,
    heat: (v) => `calor ${v}°`,
    cold: (v) => `frio ${v}°`,
    wind: (v) => `vento ${v} km/h`,
    storm: "trovoada",
    fog: "nevoeiro",
    allGood: "Temperatura amena, pouco vento e baixa probabilidade de chuva.",
    takeRainGear: "Leva impermeável e protege a mochila.",
    takeLightCover: "Leva uma capa leve por precaução.",
    water: "Reforça a água (+1 L por pessoa).",
    warmLayer: "Leva uma camada térmica para o início da manhã.",
    avoidRidges: "Evita miradouros e cristas expostas.",
    windbreaker: "Leva corta-vento.",
    postponeStorm: "Adia se houver trovoada: cristas não são seguras.",
    fogLight: "Leva luz e mapa offline: a visibilidade pode cair.",
  },
  en: {
    rain: (v) => `rain ${v}%`,
    rainRisk: (v) => `chance of rain ${v}%`,
    heat: (v) => `heat ${v}°`,
    cold: (v) => `cold ${v}°`,
    wind: (v) => `wind ${v} km/h`,
    storm: "thunderstorm",
    fog: "fog",
    allGood: "Mild temperature, light wind and low chance of rain.",
    takeRainGear: "Bring a rain jacket and protect your backpack.",
    takeLightCover: "Bring a light cover just in case.",
    water: "Carry extra water (+1 L per person).",
    warmLayer: "Bring an extra layer for the early morning.",
    avoidRidges: "Avoid exposed viewpoints and ridges.",
    windbreaker: "Bring a windbreaker.",
    postponeStorm: "Postpone if there is a thunderstorm: ridges are not safe.",
    fogLight: "Bring a light and offline map: visibility can drop.",
  },
};

export function scoreDay(day: DailyWeather, lang: Lang = "pt"): ScoredWeather {
  const copy = COPY[lang] ?? COPY.pt;
  let score = 100;
  const reasons: string[] = [];
  const advice: string[] = [];

  if (day.precipProb > 40) {
    score -= 40;
    reasons.push(copy.rain(Math.round(day.precipProb)));
    advice.push(copy.takeRainGear);
  } else if (day.precipProb > 20) {
    score -= 20;
    reasons.push(copy.rainRisk(Math.round(day.precipProb)));
    advice.push(copy.takeLightCover);
  }

  if (day.tempMax > 30 || day.tempMax < 8) {
    score -= 25;
    reasons.push(
      day.tempMax > 30
        ? copy.heat(Math.round(day.tempMax))
        : copy.cold(Math.round(day.tempMax))
    );
  } else if (day.tempMax < 15 || day.tempMax > 24) {
    score -= 10;
  }

  if (day.tempMax > 28) advice.push(copy.water);
  if (day.tempMin < 10) advice.push(copy.warmLayer);

  if (day.windMax > 30) {
    score -= 20;
    reasons.push(copy.wind(Math.round(day.windMax)));
    advice.push(copy.avoidRidges);
  } else if (day.windMax > 20) {
    score -= 10;
    if (day.windMax > 25) advice.push(copy.windbreaker);
  }

  if (day.weathercode >= 95) {
    score -= 30;
    reasons.push(copy.storm);
    advice.push(copy.postponeStorm);
  } else if (day.weathercode === 45 || day.weathercode === 48) {
    score -= 15;
    reasons.push(copy.fog);
    advice.push(copy.fogLight);
  }

  const finalScore = Math.max(0, Math.min(100, score));
  const rating: WeatherRating =
    finalScore >= 80 ? "Ideal" : finalScore >= 55 ? "Bom" : "Evitar";

  return {
    ...day,
    score: finalScore,
    rating,
    reason: reasons.length > 0 ? reasons.join(" · ") : copy.allGood,
    advice: [...new Set(advice)],
  };
}

export function bestDays(
  days: DailyWeather[],
  limit = 5,
  lang: Lang = "pt"
): ScoredWeather[] {
  return days
    .map((day) => scoreDay(day, lang))
    .sort((a, b) => b.score - a.score || a.date.localeCompare(b.date))
    .slice(0, limit);
}

/** Data YYYY-MM-DD válida. */
export function isValidDate(value: string | undefined): value is string {
  if (!value || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  return !Number.isNaN(Date.parse(`${value}T00:00:00Z`));
}

export function daysBetween(date: string): number {
  const target = Date.parse(`${date}T00:00:00Z`);
  const today = new Date();
  const todayUtc = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate());
  return Math.floor((target - todayUtc) / 86_400_000);
}

export { MAX_FORECAST_DAYS };
export type { Lang as WeatherLang };
