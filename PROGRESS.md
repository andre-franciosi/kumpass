# Kumpas — Estado do Projeto & Próximos Passos

> Documento de handoff. Explica **o que já está feito**, **como correr** e **o que falta**.
> Última atualização: 26 out 2026.

---

## 1. Visão geral

**Kumpas** (Lisbon Outdoors & Quests) — app de missões histórico-culturais gamificadas
na Grande Lisboa (Sintra, Arrábida, Monsanto), com lore local e recompensas em parceiros.

| Camada | Stack | Estado |
|---|---|---|
| Backend | Node.js + Fastify + TypeScript + Prisma + PostgreSQL | ✅ Funcional |
| Mobile | Flutter (Dart) + `geolocator` + `http` + `flutter_map` + `flutter_map_tile_caching` + `shared_preferences` | ✅ Funcional |
| BD local | PostgreSQL 16 (Docker) | ✅ A correr |
| Emulador | Waydroid (Android nativo) | ✅ A funcionar |
| Emulador | AVD `kumpas` (QEMU, com internet) | ✅ A funcionar |
| Telemóvel | Android físico via USB + `adb reverse` | ✅ A funcionar (Samsung SM-S711B) |

---

## 2. O que já está feito

### 2.1 Backend (`backend/`)

**Estrutura:**
```
backend/
├── prisma/
│   ├── schema.prisma              # 8 modelos (Quest com track + Review)
│   ├── seed.ts                    # lê tracks reais + reviews + rewards
│   ├── tracks/                    # sintra/arrabida/monsanto.json (OSM)
│   └── migrations/
├── scripts/
│   ├── fetch-tracks.ts            # Overpass API → tracks reais
│   └── smoke-test.sh              # teste end-to-end (11 verificações)
├── src/
│   ├── server.ts                  # Fastify + CORS + registo de rotas
│   ├── lib/
│   │   ├── prisma.ts
│   │   ├── haversine.ts
│   │   ├── difficulty.ts          # nível, XP e progressão de nível
│   │   ├── badges.ts              # badges derivadas do progresso
│   │   └── weather.ts             # Open-Meteo + score "quando ir"
│   └── routes/
│       ├── auth.ts                # login/criação por email
│       ├── quests.ts              # lista + detalhe (track, bbox, nível)
│       ├── reviews.ts             # listar/upsert reviews
│       ├── checkpoints.ts         # unlock + conclusão + badge de sol
│       ├── users.ts               # perfil (XP, nível, badges)
│       └── weather.ts             # previsão + melhores dias
```

**Modelos Prisma:** `User`, `Quest`, `Checkpoint` (+ `loreSource/loreUrl/imageUrl/imageCredit`),
`UserProgress`, `UserCheckpoint`, `Reward`, `UserReward`, `Review` (+ `imageCredit` na Quest).

`Quest` ganhou: `distanceKm`, `durationMin`, `elevationGainM`, `terrainFactor`,
`imageUrl`, `ratingAvg`, `ratingCount`, `trackPoints` (Json) e `regionBounds` (Json).
`UserProgress` ganhou `sunnyCompletion` (conclusão em dia Ideal).
`Review` tem `@@unique([userId, questId])` (uma review editável por utilizador e trilha).

**Endpoints implementados:**

| Método | Rota | Descrição |
|---|---|---|
| GET | `/health` | Health check |
| POST | `/api/auth/login` | `{email, name?}` → lookup ou cria utilizador |
| GET | `/api/quests?userId=` | Lista com nível, rating, XP, centro do mapa e progresso |
| GET | `/api/quests/:id?userId=` | Detalhe + checkpoints + reviews + breakdown da dificuldade |
| GET | `/api/quests/:id/reviews` | Lista de reviews |
| POST | `/api/quests/:id/reviews` | `{userId, rating, comment?}` (upsert + recalcula média) |
| POST | `/api/checkpoints/unlock` | Valida GPS, cria `UserCheckpoint`, conclui a trilha e atribui badge de sol |
| GET | `/api/users/:id/profile` | XP, nível, badges, progresso e reviews escritas |
| GET | `/api/weather?lat=&lng=&date=` | Previsão diária + score “quando ir” (Open-Meteo) |
| GET | `/api/quests/:id/best-days` | 5 melhores dias nos próximos 16 dias |

**Nível de dificuldade (calculado, nunca escrito à mão):**

```
score = (distanceKm × 3 + durationMin × 0,12 + elevationGainM × 0,05 + checkpoints × 4) × terrainFactor
1 = Fácil (<25) · 2 = Moderado (<45) · 3 = Desafiante (<70) · 4 = Expert (<100) · 5 = Lendário (>=100)
```

Exemplos do seed (dados reais OSM): Sintra 3,7 km/250 m D+ → nível 3;
Arrábida 8,1 km/532 m D+ → nível 5; Monsanto 6,7 km/207 m D+ → nível 3.

**Trilhas reais (Overpass/OSM):**
- `make tracks` corre `scripts/fetch-tracks.ts`, que consulta relations
  `route=hiking`, costura as ways, simplifica o traçado (Douglas-Peucker),
  pede elevações ao Open-Meteo e escolhe POIs reais junto à rota.
- O resultado fica em `prisma/tracks/*.json` (fonte de verdade versionada).
- `regionBounds` é o bbox do track + POIs com ~150 m de padding.
- Se o Overpass falhar, os JSON anteriores são mantidos.

**Gamificação no servidor:**
- `+50 XP` por checkpoint validado.
- Ao concluir todos os checkpoints: `completed = true` e bónus
  `checkpoints×100 + 300 + nível×50` (Sintra 900 · Arrábida 750 · Monsanto 700).
- Perfil: `level = floor(xp/500)+1`, com `xpIntoLevel` e `xpForNextLevel`.
- Badges: Primeiro Passo, Explorador, Colecionador de Histórias, Guardião de
  cada região concluída, Voz da Montanha (primeira review) e **Caçador de Sol**
  (conclusão num dia com rating “Ideal”, calculado via Open-Meteo).
- **Tempo:** score 0-100 por dia (chuva, temperatura, vento, trovoada/nevoeiro),
  com cache de 30 min. `>=80 Ideal`, `>=55 Bom`, resto `Evitar`.

**Lógica do unlock (`checkpoints.ts`):**
1. Valida payload e existência de user/checkpoint.
2. Haversine → se `distância > radiusMeters`, `400` com distância e raio exigido.
3. Dentro do raio → `upsert` idempotente + contagem de checkpoints da trilha.
4. Se validou todos → `UserProgress.completed = true`.
5. Devolve lore, `xpGained`, `alreadyUnlocked` e progresso da trilha.

**Validação:** `backend/scripts/smoke-test.sh` passa **11/11** (health, lista com nível,
detalhe com track/breakdown, unlock fora/dentro do raio, idempotência, perfil, login,
reviews, weather e best-days; os testes de clima avisam mas não falham se o
serviço externo estiver em baixo).

### 2.2 Mobile (`mobile/`)

**Estrutura (refactor do antigo `main.dart` único):**
```
mobile/lib/
├── main.dart                      # MaterialApp + sessão (login ↔ home)
├── config.dart                    # API_BASE_URL via --dart-define
├── map_style.dart                 # CARTO Voyager + fallback OSM
├── models/models.dart             # User, Quest, Checkpoint, Review, Profile...
├── services/
│   ├── api_service.dart
│   ├── location_service.dart
│   ├── position_source.dart       # GPS real + GPS simulado (test user)
│   ├── live_session.dart          # sessão ativa + fila de check-ins offline
│   ├── map_cache.dart             # tiles offline (FMTC/ObjectBox)
│   └── plan_repository.dart       # interface + local (SharedPreferences) + stub remoto
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── trail_detail_screen.dart
│   └── live_trail_screen.dart     # modo ao vivo (mapa, auto-unlock, recados)
└── widgets/
    ├── ui.dart                    # cores, nível, estrelas, formatação
    ├── quest_card.dart
    └── lore_dialog.dart
```

**Fluxo do utilizador:**
1. **Login** — email (pré-preenchido com `tester@kumpas.dev`) → `POST /api/auth/login`.
2. **Home** — cabeçalho com XP/nível/badges; mapa interativo com pinos clicáveis
   (cor por estado: nova/cinza, em progresso/azul, concluída/verde); filtro por
   região; lista de trilhas com imagem, nível, rating, distância, duração, D+,
   XP e barra de progresso.
3. **Detalhe da trilha**
   - Hero com região, nível, rating.
   - Estatísticas e cartão do nível com o **breakdown da fórmula**.
   - Mini-mapa com o **track real do OSM** (polyline), bbox ajustado e
     checkpoints numerados (verdes quando validados).
   - **Mapa offline**: download dos tiles da trilha (zoom 10-16) com progresso,
     validação de falhas de rede e botão para apagar.
   - **Fundo do mapa**: CARTO Voyager (visual tipo Google Maps) quando há
     `CARTO_KEY`; sem key usa OSM standard.
   - **Planear o passeio** (local): data, nº de pessoas, transporte e checklist.
     Guarda em `SharedPreferences`; checklist completa **e** dia Bom/Ideal
     mostra “+50 XP preparador”.
   - **Previsão do tempo**: chip com temperatura, chuva, vento e rating
     (Ideal/Bom/Evitar); “Melhores dias” clicáveis; sugestões de equipamento.
   - **Checkpoints**: lore bloqueado até validar no local (GPS → API).
   - **Recompensa de parceiro** (teaser) e **reviews** com estrelas e formulário.
   - Ao desbloquear: Lore Card com XP ganho; ao concluir: banner + mensagem de recompensa.

**Dependências:** `geolocator`, `http`, `flutter_map`, `latlong2` (0.9.1),
`flutter_map_tile_caching` (10.x), `shared_preferences`.

**Internacionalização (29 out 2026):**
- `flutter_localizations` + `intl` + `gen_l10n` (`l10n.yaml`, `lib/l10n/app_pt.arb`,
  `app_en.arb`; gerados para `lib/l10n/app_localizations*.dart`).
- Estado do idioma em `main.dart` (`_effectiveLocale`: preferência guardada →
  locale do dispositivo) + `LanguageStore` (SharedPreferences) + helpers em
  `lib/l10n/l10n.dart` (`context.l10n`).
- Seletor: `SegmentedButton` no login (`LanguageToggle`) e botão PT/EN na AppBar
  (`LanguageButton`), ambos em `services/language_store.dart`.
- Valores vindos da API em PT mapeados no cliente (`lib/l10n/mapped_strings.dart`):
  dificuldade, ratings/labels de clima, badges, categorias de recado e erros de GPS.
- Backend: `/api/weather` e `/best-days` aceitam `?lang=pt|en` (reason/advice).
- **Conteúdo bilingue (29 out 2026):** `Quest.titleEn/descriptionEn` e
  `Checkpoint.titleEn/loreEn/loreSourceEn/loreUrlEn`; o pipeline `make content`
  combina `prisma/content/quests_en.json` + `overrides.json` (`titleEn`/`loreEn`)
  e o `GET /api/quests` / `/:id` / `POST /checkpoints/unlock` aceitam `?lang=en`
  (ou `lang` no body). Cobertura atual: 6/6 trilhas e 21/21 checkpoints com EN.
- **Bugs corrigidos (29 out 2026):**
  - Página da trilha rebentava em EN: o dropdown de transporte usava o texto
    traduzido como valor (`initialValue: 'Carro'` sem correspondência) →
    transporte passou a ids (`walk|car|train|bus`) com migração dos planos antigos.
  - Região "Arrabida" passa a "Arrábida" na UI; descrições EN nas listas.
- **Fora de âmbito (fase 2):** reviews e recados de utilizadores continuam no
  idioma em que foram escritos; mensagens de erro do servidor em PT.
- Nota: `gen_l10n` ordena placeholders **alfabeticamente** — nos textos com 2+
  placeholders a ordem dos argumentos tem de respeitar isso.

**Configuração:**
- `API_BASE_URL` via `--dart-define` (default `http://10.0.2.2:3000`).
- `CARTO_KEY` via `--dart-define` (ou `make ... CARTO_KEY=...`). Sem key, fallback OSM.
- `MAP_TILE_URL` (dev) permite forçar um template de tiles/proxy local.
- `USE_OSM_TILES=true` força OSM mesmo com key CARTO.

**Redesign (21 out 2026):**
- Tokens centralizados em `lib/theme/kumpas_theme.dart` (paleta floresta/papel/âmbar,
  raios, tipografia e temas de componentes).
- Fontes **embarcadas** (OFL, sem download em runtime): `Inter` (texto) e
  `Fraunces` (títulos) em `assets/fonts/` (instâncias estáticas geradas com fonttools).
- Marca desenhada: `CompassRose` (CustomPainter) usada no login, estados vazios/erro
  e como ícone da app.
- Login: hero com bússola + painel papel.
- Home: cabeçalho compacto com anel de XP + badges, mapa em destaque, pills de
  região e `QuestCard` redesenhado.
- Detalhe: `SliverAppBar` com hero colapsável, checkpoints em **timeline vertical**,
  cartões de clima/offline/plano/reviews restilizados.
- **Ícone da app**: bússola desenhada (SVG → PNG 1024, `assets/icon/`) com
  `flutter_launcher_icons` → adaptive icon Android (`#1F5C2E` + foreground).
  iOS não está configurado no projeto (sem pasta `ios/`).
- Android: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`,
  `usesCleartextTraffic="true"`.

**Validação:** `flutter analyze` → *No issues found!* · `flutter build apk --debug` OK ·
`make test` 12/12 (inclui verificação de histórias com fonte) · **E2E “vida real”
no AVD**: login → trilha Mistérios de Sintra → check-in GPS com as coordenadas
reais dos 4 POIs (`adb emu geo fix`) → Lore Card com história real, foto de
arquivo (retrato de D. Fernando II), fonte e XP → trilha concluída (+900 XP) →
Home com 6 trilhas, capas reais e estado “Concluída”. O APK final também está
pronto para o telemóvel (`make mobile-device CARTO_KEY=...`; o cabo estava
desligado no fim da sessão).
Também validado no **AVD com internet** e num **telemóvel físico** (Samsung
SM-S711B, USB + `adb reverse`): CARTO Voyager, track real e API a funcionar.

**Correções (21 out 2026):**
- **Zoom do mapa:** `TileLayer.maxNativeZoom = 16` em ambos os mapas; no detalhe,
  `maxZoom` é 18 online e 16 com pack offline. *Sem* `minZoom` no mapa do
  detalhe — combinado com `initialCameraFit` quebrava o carregamento de tiles
  (ficavam os tiles do centro por defeito, “Kyiv”). Deixou de “desaparecer” no
  zoom máximo (upscale do z16).
- **Review:** formulário extraído para `_ReviewSheet` (só recolhe input e faz
  `pop` com o resultado); o POST, `_reloadDetail` e `SnackBar` correm no ecrã
  pai depois do sheet fechar. Elimina o `_dependents.isEmpty` causado por
  `setState`/`pop` entrelaçados.

**Trilha ao vivo + recados (28 out 2026):**
- `LiveTrailScreen`: stream GPS (`getPositionStream`, `distanceFilter: 8 m`),
  marcador azul com rumo, câmara follow-me, track completo em cinza e troço
  percorrido em verde, próximo checkpoint + distância, aviso “fora da rota”
  (>80 m), progresso e botões Recado / GPS / Terminar.
- Auto-unlock ao entrar no raio (cooldown 25 s, um de cada vez); Lore Dialog
  com foto/fonte/XP. Falhas de rede vão para `PendingUnlockStore` e são
  reenviadas no arranque seguinte.
- Sessão em `LiveSessionStore` (início, distância) → “Retomar trilha” no
  detalhe; terminar limpa a sessão.
- **Recados:** `TrailMessage` (categoria, texto ≤280, lat/lng, likes,
  denúncias) + `TrailMessageLike` e `TrailMessageReport`; `routes/messages.ts`
  com GET/POST/like/report, rate limit 5/hora e validação server-side de
  proximidade (<500 m do track). ReportCount ≥3 esconde do GET.
- **Conta de teste:** `User.isTest` (seed `tester.gps@kumpas.dev`, id
  `2222...`), botão no login. `SimulatedPositionSource`: teletransporte por
  toque longo, atalhos por checkpoint e simulação do percurso a 1,4 m/s.
- **Validação no telemóvel:** login test-user → Muralhas do Castelo → trilha ao
  vivo → GPS simulado no cp1 → unlock automático (+50 XP, Lore real) → recado
  publicado e visível → voltar → “Retomar trilha” com sessão de 4 min. Smoke
  test 16/16.

### 2.3 Infraestrutura

| Ficheiro | Função |
|---|---|
| `docker-compose.yml` | Postgres 16-alpine (user/pass/db = `kumpas`, porta 5432) |
| `Makefile` | Atalhos para tudo (`make help`); Waydroid usa `adb reverse` |
| `backend/prisma/tracks/` | Tracks reais OSM versionados (gerados por `make tracks`) |
| `.gitignore` | Node, Flutter, Android, IDE |
| `README.md` | Guia de arranque rápido |
| `scripts/setup-android-sdk.sh` | Recria SDK + AVD do zero |
| `scripts/waydroid-start.sh` | Arranca Waydroid (container + rede + adb) |
| `SKILL.md` | Especificação original do produto |

---

## 3. Como correr

### Arranque completo

```bash
make setup      # install + Postgres + migrações + seed
make tracks     # (opcional) regenera as trilhas reais via Overpass/OSM
make backend    # API em http://localhost:3000
make test       # smoke test (noutro terminal)
```

### Front-end (escolher uma opção)

```bash
# A) Waydroid — Android nativo (recomendado)
make waydroid-start    # corre no TEU terminal (precisa sudo)
make mobile-waydroid   # faz adb reverse e usa 127.0.0.1:3000

# B) Emulador AVD (QEMU)
make emulator
make mobile-android

# C) Web (requer `flutter create . --platforms web`; o projeto ainda não tem web/)
make mobile-chrome
make mobile-web
```

### Dados de teste (reais)

- **User:** `11111111-1111-1111-1111-111111111111` (`tester@kumpas.dev`)
- **6 trilhas reais** (tracks OSM): Mistérios de Sintra · Muralhas do Castelo ·
  Segredos da Arrábida · Costa do Portinho · Vigia de Monsanto · Caminhos da Água
- **21 checkpoints** (POIs reais) — 21/21 com história de fonte real
  (inscrições OSM, Wikipédia PT, curadoria com fonte) · 13 com foto Commons
- **Reviews:** 7 de exemplo · **Rewards:** 3

### Testar o unlock com GPS simulado (Waydroid)

```bash
adb -s 192.168.240.112:5555 emu geo fix -9.3906 38.7974   # Sintra
```

---

## 4. ⚠️ Limitações conhecidas

| # | Limitação | Impacto |
|---|---|---|
| 1 | **Login sem password/JWT** — email identifica o utilizador | Não serve para produção |
| 2 | **Planeamento só local** (`SharedPreferences`) | Não sincroniza entre dispositivos |
| 3 | **Rewards sem claim** — `/api/rewards` e `POST /claim` ainda não existem | Recompensa é apenas teaser visual |
| 4 | **Sem validação de schema** (ex.: Zod) | Payloads malformados dependem de validação manual |
| 5 | **Sem testes automatizados** (só smoke test manual) | Regressões passam despercebidas |
| 6 | **CORS aberto** (`origin: true`) | Só aceitável em dev |
| 7 | **Tiles/imagens precisam de internet** no primeiro uso | Sem rede, o mapa mostra fundo + track vetorial |
| 8 | **CARTO exige key** (desde 2026) e tem quota (1M comercial / 5M não-comercial) | Sem key cai para OSM; monitorizar quota |
| 9 | **Offline por trilha partilha um store** | “Apagar mapas” remove o cache de todas as trilhas |
| 10 | **Cache não expira** | Tiles podem ficar antigos; apagar/descarregar resolve |
| 11 | **FMTC é GPL-3.0** | Rever licenciamento antes de publicar comercialmente |
| 12 | **Mini-mapa do detalhe pode mostrar tiles de outra zona (Lisboa)** | Câmara/fit com `fitCamera` pós-layout e provider por mapa não resolveram; follow-up: investigar `TileLayer` partilhado/estado do `flutter_map` 8 |
| 13 | **Sem modo escuro** | Redesign atual é claro; dark mode fica para fase 2 |
| 12 | **Sem modo escuro** | Redesign atual é claro; dark mode fica para fase 2 |

> Waydroid neste ambiente **não tem rede externa** (nem default route/NAT) — os
> tiles (OSM/CARTO) e imagens não carregam diretamente. Solução de dev:
> `make tiles-proxy CARTO_KEY=...` no host + `MAP_TILE_URL` (via `adb reverse`).
> Com proxy, o CARTO Voyager e o download offline funcionam; sem proxy, o mapa
> fica no fundo verde mas track/pinos/clima continuam operacionais.

---

## 5. Próximos passos sugeridos

### 🔴 Prioridade alta

1. **Recompensas reais** — `GET /api/rewards`, `POST /api/rewards/:id/claim`
   (decremento de `stock`, `UserReward`) e ecrã de perfil com códigos.
2. **Autenticação real** — password hash (argon2/bcrypt) + JWT.
3. **Validar nível/XP com testes unitários** (`difficulty.ts` e conclusão de quest).

### 🟡 Prioridade média

4. **Sincronizar planos** — `PlannedHike` + `POST /api/plans`; trocar
   `LocalPlanRepository` por `RemotePlanRepository` (contrato já existe).
5. **Validação com Zod** nos handlers.
6. **Ecrã de perfil** com histórico, badges e recompensas.
7. **Leaderboard** semanal por região (usa XP já calculado).
8. **Refrescar tracks** periodicamente (`make tracks`) e guardar `sourceTimestamp`
   para mostrar a idade dos dados OSM.
9. **Clima no plano guardado** — guardar o rating do dia escolhido e avisar se
   a previsão mudar.

### 🟢 Prioridade baixa

10. **Testes** — Vitest no backend, `flutter_test` no mobile.
11. **Cache offline por trilha independente** (um store FMTC por quest) e expiração.
12. **Estado global** (Riverpod/Provider) e persistência da sessão de login.
13. **Web**: `flutter create . --platforms web` para ativar `make mobile-web`.

---

## 6. Comandos de referência rápida

```bash
# Base de dados
make db-up / db-down / db-reset
npx prisma studio                    # UI da BD (a partir de backend/)

# Backend
make backend                         # dev com hot reload
make test                            # smoke test
make tracks                          # regenerar tracks via Overpass/OSM
npm --prefix backend run seed        # repopular

# Mobile
make mobile-waydroid / mobile-android / mobile-chrome / mobile-web
make emulator                        # AVD (tem internet)
make mobile-android CARTO_KEY=a_tua_key   # mapa CARTO Voyager no AVD
make mobile-device DEVICE=<serial> CARTO_KEY=a_tua_key  # telemóvel USB
make tiles-proxy CARTO_KEY=a_tua_key        # proxy p/ Waydroid sem internet
cd mobile && flutter analyze         # lint
cd mobile && flutter build apk --debug

# Waydroid
make waydroid-start / waydroid-stop
adb -s 192.168.240.112:5555 reverse tcp:3000 tcp:3000
adb -s 192.168.240.112:5555 emu geo fix -9.3906 38.7974
```

---

## 7. Notas de ambiente (gotchas)

- **Shell é fish** — `export PATH=$VAR:$PATH` corrompe o PATH. Usar `set -gx PATH ...`
  ou scripts bash.
- **Waydroid congela** se a UI não estiver a correr → o `waydroid-start.sh` usa `setsid`
  para a manter viva. Se o IP aparecer `UNKNOWN`, correr `make waydroid-start` de novo.
- **Rede do Waydroid:** a bridge `192.168.240.1` pode estar bloqueada por firewall;
  `make mobile-waydroid` usa `adb reverse` + `127.0.0.1:3000` (mais fiável).
- **Emulador AVD:** acede ao host via `10.0.2.2`.
- **`flutter run` "Lost connection to device"** — acontece quando o terminal é limpo,
  mas o app continua a correr no dispositivo.
- **npm bloqueia install scripts** (prisma/esbuild postinstall) neste ambiente.
