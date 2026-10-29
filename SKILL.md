# SKILL.md — Lisbon Outdoors & Quests MVP

## 1. Visão do Produto & Região
- B2C: Flutter (Android nativo, compatível iOS) + Backend Node.js/TypeScript (Fastify) + PostgreSQL.
- Foco: Missões e rotas histórico-culturais gamificadas, lore local, recompensas em parceiros.
- Região: Grande Lisboa — Sintra, Arrábida, Monsanto.

## 2. Arquitetura & Tech Stack
- **Mobile:** Flutter (Dart), `geolocator`, `http`.
- **Backend:** Node.js, Fastify, TypeScript, Prisma ORM, PostgreSQL.
- **Validação geográfica:** Haversine no servidor. Raio tolerância em metros por checkpoint (`radiusMeters`).

```ts
function haversine(lat1:number,lon1:number,lat2:number,lon2:number):number{
  const R=6371000, toRad=(d:number)=>d*Math.PI/180;
  const dLat=toRad(lat2-lat1), dLon=toRad(lon2-lon1);
  const a=Math.sin(dLat/2)**2+Math.cos(toRad(lat1))*Math.cos(toRad(lat2))*Math.sin(dLon/2)**2;
  return 2*R*Math.asin(Math.sqrt(a));
}
// unlock se haversine(...) <= checkpoint.radiusMeters
```

## 3. Modelo de Dados (Prisma)
```prisma
model User { id String @id @default(uuid()) email String @unique name String progress UserProgress[] checkpoints UserCheckpoint[] rewards UserReward[] }
model Quest { id String @id @default(uuid()) title String description String region String // Sintra | Arrabida | Monsanto
  checkpoints Checkpoint[] progress UserProgress[] }
model Checkpoint { id String @id @default(uuid()) questId String quest Quest @relation(fields:[questId],references:[id],onDelete:Cascade)
  order Int title String lore String lat Float lng Float radiusMeters Int @default(50)
  unlocks UserCheckpoint[] }
model UserProgress { id String @id @default(uuid()) userId String questId String completed Boolean @default(false) updatedAt DateTime @updatedAt
  user User @relation(fields:[userId],references:[id],onDelete:Cascade)
  quest Quest @relation(fields:[questId],references:[id],onDelete:Cascade)
  @@unique([userId,questId]) }
model UserCheckpoint { id String @id @default(uuid()) userId String checkpointId String unlockedAt DateTime @default(now())
  user User @relation(fields:[userId],references:[id],onDelete:Cascade)
  checkpoint Checkpoint @relation(fields:[checkpointId],references:[id],onDelete:Cascade)
  @@unique([userId,checkpointId]) }
model Reward { id String @id @default(uuid()) title String partner String code String stock Int
  claimed UserReward[] }
model UserReward { id String @id @default(uuid()) userId String rewardId String claimedAt DateTime @default(now())
  user User @relation(fields:[userId],references:[id],onDelete:Cascade)
  reward Reward @relation(fields:[rewardId],references:[id])
  @@unique([userId,rewardId]) }
```

## 4. Endpoints REST
- `GET /api/quests` → `[{id,title,region,checkpointCount}]`
- `GET /api/quests/:id` → `{id,title,description,region,checkpoints:[{id,order,title,lore,lat,lng,radiusMeters}]}`
- `POST /api/checkpoints/unlock`
  ```json
  // IN
  {"userId":"uuid","checkpointId":"uuid","userLat":38.71,"userLng":-9.14}
  // OUT 200: {"unlocked":true,"distanceMeters":23}
  // OUT 400: {"unlocked":false,"distanceMeters":312,"requiredMeters":50}
  ```
  Lógica: buscar checkpoint → haversine(user,checkpoint) → se `<= radiusMeters` criar `UserCheckpoint` (idempotente) + upsert `UserProgress`.
- `GET /api/users/:id/profile` → `{user,progress:[{questId,completed}],checkpoints:[checkpointId],rewards:[{rewardId,title,partner,code}]}`

## 5. Regras Globais de Código IA
- Retornar sempre código completo, limpo e executável.
- Priorizar simplicidade e performance.
- Não adicionar dependências desnecessárias. Só `geolocator`,`http` (mobile); `fastify`,`@prisma/client` (backend).
- Validar geo só no servidor. Nunca confiar no client.
- Usar `@@unique([userId,checkpointId])` para idempotência.
