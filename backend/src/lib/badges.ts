/**
 * Badges de gamificação derivadas do progresso real do utilizador.
 */

export interface Badge {
  id: string;
  title: string;
  description: string;
  icon: string;
}

export interface BadgeInput {
  unlockedCheckpoints: number;
  completedQuestIds: string[];
  completedRegions: string[];
  reviewsWritten: number;
  sunnyCompletions: number;
}

export function computeBadges(input: BadgeInput): Badge[] {
  const badges: Badge[] = [];

  if (input.unlockedCheckpoints >= 1) {
    badges.push({
      id: "primeiro-passo",
      title: "Primeiro Passo",
      description: "Validaste o teu primeiro checkpoint.",
      icon: "footsteps",
    });
  }

  if (input.completedQuestIds.length >= 1) {
    badges.push({
      id: "explorador",
      title: "Explorador",
      description: "Concluíste a tua primeira trilha.",
      icon: "terrain",
    });
  }

  if (input.completedQuestIds.length >= 3) {
    badges.push({
      id: "colecionador",
      title: "Colecionador de Histórias",
      description: "Concluíste todas as trilhas da região.",
      icon: "collections_bookmark",
    });
  }

  for (const region of input.completedRegions) {
    badges.push({
      id: `regiao-${region.toLowerCase()}`,
      title: `Guardião de ${region}`,
      description: `Concluíste uma trilha em ${region}.`,
      icon: "shield",
    });
  }

  if (input.reviewsWritten >= 1) {
    badges.push({
      id: "critico",
      title: "Voz da Montanha",
      description: "Partilhaste a tua primeira review.",
      icon: "rate_review",
    });
  }

  if (input.sunnyCompletions >= 1) {
    badges.push({
      id: "cacador-de-sol",
      title: "Caçador de Sol",
      description: "Concluíste uma trilha num dia com condições ideais.",
      icon: "wb_sunny",
    });
  }

  return badges;
}
