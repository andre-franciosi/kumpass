<div align="center">
  <img src="docs/logo.png" width="120" alt="Kumpas logo" />

# Kumpas

**Gamified hiking trails across Greater Lisbon — Sintra, Arrábida and Monsanto.**

Real OSM trail geometry · live GPS follow-me mode · automatic check-ins · real stories · offline maps · PT/EN

[![Flutter](https://img.shields.io/badge/Flutter-3.38-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Fastify](https://img.shields.io/badge/Fastify-4-000000?logo=fastify&logoColor=white)](https://fastify.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Prisma](https://img.shields.io/badge/Prisma-5-2D3748?logo=prisma&logoColor=white)](https://www.prisma.io)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

</div>

<p align="center">
  <img src="docs/screenshots/02-home-map.png" width="220" alt="Home with live map" />
  <img src="docs/screenshots/04-live-trail.png" width="220" alt="Live trail mode" />
  <img src="docs/screenshots/05-lore-card.png" width="220" alt="Lore card unlocked on site" />
</p>

---

## What is Kumpas?

Kumpas turns real hiking trails into a game. You pick a trail, walk it with **live GPS tracking** (like a navigation app), and when you physically reach a **checkpoint** the app unlocks its story — sourced from Wikipedia, Wikidata, Wikimedia Commons and on-site OSM inscriptions. Every check-in grants XP, levels and badges; partner rewards unlock when you finish a trail.

It is built around **real data**: trail geometry comes from OpenStreetMap, stories and photos come from open knowledge sources with attribution, and the whole app works offline once you download the map pack for a trail.

## Features

- **Live trail mode** — streamed GPS, blue direction marker, follow-me camera, progress line drawn behind you, next checkpoint with distance, off-route warning, and automatic check-ins when you enter a checkpoint radius.
- **Offline-first** — tile packs per trail (zoom 10–16), trail session persisted locally, failed check-ins queued and re-synced automatically.
- **Real lore, real sources** — every story has a source (Wikipedia article, OSM inscription or curated note) and a real photo with author/license credit. Lore cards show the source and the archive image.
- **Trail messages** — leave tips, warnings or danger notes on the path for other hikers; server-side validation ensures you can only post within 500 m of the trail, with likes and reports.
- **Weather that answers "when should I go?"** — per-day score from Open-Meteo (rain, temperature, wind, storms) with `Ideal / Good / Avoid`, best days for the next 16 days and gear advice.
- **Gamification** — XP per checkpoint and per completion, levels, badges (First Step, Explorer, Sun Chaser…), trail progress and partner rewards.
- **Bilingual** — full UI in **Portuguese and English** with in-app language picker; trail titles, descriptions and lore are bilingual too.
- **Map styles** — CARTO Voyager basemap (Google-Maps-like look) with automatic OSM fallback when no API key is configured.
- **Test account with simulated GPS** — teleport anywhere, jump to any checkpoint or simulate the whole route; the server still validates everything.

<p align="center">
  <img src="docs/screenshots/01-login.png" width="200" alt="Login" />
  <img src="docs/screenshots/03-trail-detail.png" width="200" alt="Trail detail" />
  <img src="docs/screenshots/06-checkpoints-messages.png" width="200" alt="Checkpoints and messages" />
</p>

## Tech stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.38 (Dart) · `flutter_map` + CARTO/OSM · `flutter_map_tile_caching` (offline) · `geolocator` · `http` · `shared_preferences` · `gen_l10n` (PT/EN) |
| Backend | Node.js · Fastify 4 · TypeScript · Prisma 5 |
| Database | PostgreSQL 16 (Docker) |
| Data pipeline | Overpass API (OSM) · Open-Meteo (weather + elevation) · Wikipedia/Wikidata/Wikimedia Commons |
| Tooling | Makefile, tsx, docker compose, flutter_launcher_icons |

## Architecture

```
┌──────────────────────────────┐        ┌──────────────────────────────┐
│  Flutter app                 │        │  Fastify API (TypeScript)    │
│                              │  REST  │                              │
│  • Map + offline tiles       │ ─────► │  • quests / checkpoints      │
│  • Live GPS trail mode       │        │  • unlock (Haversine check)  │
│  • Lore cards + messages     │        │  • reviews / messages        │
│  • PT/EN, gamification UI    │        │  • profile (XP, badges)      │
└──────────────┬───────────────┘        │  • weather proxy (cached)    │
               │                        └───────────┬──────────────────┘
               │ tiles                              │ Prisma
        ┌──────▼────────┐                 ┌─────────▼─────────┐
        │ CARTO / OSM   │                 │  PostgreSQL 16    │
        └───────────────┘                 └───────────────────┘

Offline data builders (no runtime dependency):
  Overpass API ─► prisma/tracks/*.json ─┐
  Wikipedia/Wikidata/Commons ───────────┼─► prisma/content/*.json ─► seed ─► DB
  Open-Meteo (elevation) ───────────────┘
```

## Quick start

Requirements: **Docker**, **Node.js 20+**, **Flutter 3.38+**, **GNU Make**.

```bash
git clone https://github.com/<your-user>/kumpas.git
cd kumpas

make setup      # install backend deps + start Postgres + migrate + seed
make backend    # API on http://localhost:3000
make test       # end-to-end smoke test (17 checks)
```

Run the app (any target):

| Target | Command | API URL used |
|---|---|---|
| Android emulator (AVD) | `make emulator` then `make mobile-android CARTO_KEY=...` | `http://10.0.2.2:3000` |
| Physical Android phone (USB) | `make mobile-device CARTO_KEY=...` | `http://127.0.0.1:3000` via `adb reverse` |
| Waydroid (no NAT) | `make mobile-waydroid` (+ `make tiles-proxy CARTO_KEY=...` for tiles) | `http://127.0.0.1:3000` via `adb reverse` |
| Web / Chrome (dev) | `make mobile-chrome` | `http://localhost:3000` |

> **Maps:** CARTO now requires a free key. Create one at [carto.com/basemaps](https://carto.com/basemaps/) and pass it with `CARTO_KEY=...`. Without a key the app automatically falls back to standard OSM tiles.

Demo accounts:

| Account | Purpose |
|---|---|
| `tester@kumpas.dev` | normal user with seeded progress |
| `tester.gps@kumpas.dev` | **simulated GPS** — teleport, jump to checkpoints, simulate a full walk |

## Project structure

```
kumpas/
├── backend/
│   ├── prisma/
│   │   ├── schema.prisma            # User, Quest, Checkpoint, Review, TrailMessage…
│   │   ├── seed.ts                  # reads tracks + content JSON
│   │   ├── tracks/                  # real OSM geometry (generated)
│   │   └── content/                 # lore, photos, EN/PT copy (generated + curated)
│   ├── scripts/
│   │   ├── fetch-tracks.ts          # Overpass API → trails + POIs
│   │   ├── fetch-content.ts         # Wikipedia/Wikidata/Commons → lore + photos
│   │   ├── smoke-test.sh            # API end-to-end checks
│   │   └── carto-proxy.mjs          # dev tile proxy (for devices without internet)
│   └── src/
│       ├── server.ts
│       ├── lib/                     # haversine, difficulty, badges, weather
│       └── routes/                  # auth, quests, checkpoints, reviews, messages, users, weather
└── mobile/
    └── lib/
        ├── main.dart                # locale + session state
        ├── theme/                   # design tokens (forest/paper/amber)
        ├── l10n/                    # ARB files (PT/EN) + mapped API strings
        ├── models/                  # quests, checkpoints, weather, messages
        ├── services/                # api, position sources, live session, offline cache
        ├── screens/                 # login, home, trail detail, live trail
        └── widgets/                 # compass rose, quest card, lore dialog
```

## Data pipeline

Trails, stories and photos are **generated from real open data**, then committed so the app boots without external services:

```bash
make tracks    # Overpass API → prisma/tracks/*.json (geometry, POIs, elevation)
make content   # tracks + Wikipedia/Wikidata/Commons → prisma/content/*.json (lore, photos, EN)
npm --prefix backend run seed
```

- `fetch-tracks.ts` stitches OSM `route=hiking` relations, simplifies the path (Douglas-Peucker), fetches elevation from Open-Meteo and picks real POIs within 650 m of the route.
- `fetch-content.ts` enriches each POI with stories and photos: OSM tags (`wikipedia`, `wikidata`, `inscription`), Wikipedia extracts, Wikidata images (P18) and Commons metadata for credits. Manual curation in `prisma/content/overrides.json` takes priority, and `coverage.json` reports real vs fallback fills (currently **21/21 checkpoints with a real source, 0 fallbacks**).
- Bilingual site: `prisma/content/quests_en.json` + `overrides.json` provide the English copy.

## API

| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Health check |
| POST | `/api/auth/login` | `{email, name?}` → lookup or create user |
| GET | `/api/quests?userId=&lang=` | Trail list with computed difficulty, rating, XP, bbox, progress |
| GET | `/api/quests/:id?userId=&lang=` | Trail detail + track + checkpoints + reviews + difficulty breakdown |
| POST | `/api/checkpoints/unlock` | `{userId, checkpointId, userLat, userLng, lang?}` → Haversine validation, XP, completion |
| GET/POST | `/api/quests/:id/reviews` | One review per user per trail |
| GET/POST | `/api/quests/:id/messages` | Trail messages within 500 m, 5/hour limit |
| POST | `/api/messages/:id/like` · `/report` | Like toggle · report (3 reports hide the message) |
| GET | `/api/users/:id/profile` | XP, level, badges, progress |
| GET | `/api/weather?lat=&lng=&date=&lang=` | Day forecast + "when to go" score |
| GET | `/api/quests/:id/best-days?lang=` | Best days in the next 16 days |

Trail difficulty is **derived**, never hand-picked:

```
score = (distanceKm × 3 + durationMin × 0.12 + elevationGainM × 0.05 + checkpoints × 4) × terrainFactor
1 Easy (<25) · 2 Moderate (<45) · 3 Challenging (<70) · 4 Expert (<100) · 5 Legendary (≥100)
```

## Testing

```bash
make test                      # backend smoke test (17 checks, includes EN content + messages)
cd mobile && flutter analyze   # static analysis
```

Validated on device (Samsung SM-S711B) and emulator: live trail with simulated GPS, automatic check-ins, lore cards with source + photo, message posting, offline map packs, PT/EN switch, and the full unlock → completion → reward flow.

## Environment variables

Backend (`backend/.env`, see `backend/.env.example`):

| Variable | Default | Notes |
|---|---|---|
| `DATABASE_URL` | `postgresql://kumpas:kumpas@localhost:5432/kumpas?schema=public` | Docker compose credentials |
| `PORT` | `3000` | API port |

Mobile (via `--dart-define`, or Makefile variables):

| Variable | Default | Notes |
|---|---|---|
| `API_BASE_URL` | `http://10.0.2.2:3000` | Use `10.0.2.2` (AVD), `127.0.0.1` (adb reverse) or your LAN IP |
| `CARTO_KEY` | *(empty)* | CARTO basemap key; without it the app falls back to OSM |
| `MAP_TILE_URL` | *(empty)* | Dev tile template override (e.g. local proxy) |
| `USE_OSM_TILES` | `false` | Force OSM tiles even with a CARTO key |

## Attributions & licenses

This project is licensed under the **GNU General Public License v3.0** — see [LICENSE](LICENSE).

Third-party data and assets keep their own licenses:

| Source | License | Where |
|---|---|---|
| OpenStreetMap (trail geometry, POI tags) | [ODbL](https://www.openstreetmap.org/copyright) | `backend/prisma/tracks/`, map attribution |
| Wikipedia / Wikidata / Wikimedia Commons (stories, photos) | [CC BY-SA](https://creativecommons.org/licenses/by-sa/4.0/) | per-item source + credit stored in DB and shown in the app |
| CARTO basemaps | [CARTO attribution](https://carto.com/attribution/) | map attribution `© OpenStreetMap © CARTO` |
| Open-Meteo (weather, elevation) | [Open-Meteo terms](https://open-meteo.com/en/terms) | weather endpoint + elevation pipeline |
| Inter & Fraunces fonts | [OFL-1.1](mobile/assets/fonts/OFL.txt) | bundled in `mobile/assets/fonts/` |
| `flutter_map_tile_caching` | GPL-3.0 | this is why the project is GPL-3.0 |

## Roadmap

- [ ] Real authentication (passwords + JWT) and per-user sessions in the app
- [ ] Reward redemption endpoints (`/api/rewards`, `/api/rewards/:id/claim`) and profile screen
- [ ] Trail message moderation dashboard
- [ ] iOS target (`flutter create . --platforms=ios`) and store builds
- [ ] Automated tests (Vitest on the backend, widget tests on the app)
- [ ] Public leaderboards per region

## Development notes

`PROGRESS.md` and `SKILL.md` are kept in Portuguese: they are the working handoff notes for this project (current state, environment quirks, next steps).
