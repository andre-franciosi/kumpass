/**
 * Cálculo determinístico do nível de dificuldade de uma trilha.
 *
 * O nível nunca é escrito à mão no seed: é derivado dos dados da própria
 * trilha (distância, duração, desnível, nº de checkpoints e terreno), para
 * que o cliente e o servidor nunca divergam.
 */

export interface DifficultyInput {
  distanceKm: number;
  durationMin: number;
  elevationGainM: number;
  checkpointCount: number;
  terrainFactor: number;
}

export interface DifficultyResult {
  score: number;
  level: number;
  label: string;
}

export const DIFFICULTY_LABELS: Record<number, string> = {
  1: "Fácil",
  2: "Moderado",
  3: "Desafiante",
  4: "Expert",
  5: "Lendário",
};

/** Limiares superiores do score para cada nível (1-5). */
const THRESHOLDS: Array<[maxScore: number, level: number]> = [
  [25, 1],
  [45, 2],
  [70, 3],
  [100, 4],
];

export function questDifficulty(input: DifficultyInput): DifficultyResult {
  const terrain = input.terrainFactor > 0 ? input.terrainFactor : 1;
  const raw =
    input.distanceKm * 3 +
    input.durationMin * 0.12 +
    input.elevationGainM * 0.05 +
    input.checkpointCount * 4;

  const score = Math.round(raw * terrain * 10) / 10;

  const match = THRESHOLDS.find(([max]) => score < max);
  const level = match ? match[1] : 5;

  return { score, level, label: DIFFICULTY_LABELS[level] };
}

/** XP ganho ao concluir a trilha. */
export function questXp(checkpointCount: number, difficulty: number): number {
  return checkpointCount * 100 + 300 + difficulty * 50;
}

/** XP ganho por cada checkpoint validado. */
export const CHECKPOINT_XP = 50;

/** XP necessário para subir de nível. */
export const XP_PER_LEVEL = 500;

export function levelFromXp(xp: number): {
  level: number;
  xpIntoLevel: number;
  xpForNextLevel: number;
} {
  const level = Math.floor(xp / XP_PER_LEVEL) + 1;
  const xpIntoLevel = xp % XP_PER_LEVEL;
  return { level, xpIntoLevel, xpForNextLevel: XP_PER_LEVEL };
}
