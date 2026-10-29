# LinkedIn post — Kumpas

> Draft in English. Replace `https://github.com/andre-franciosi/kumpass` with the repository link.
> Suggested format: text + 4-image carousel (login, home/map, live trail, lore card).
> Images are in `docs/screenshots/` (use 01, 02, 04, 05).

---

🧭 I built **Kumpas** — a gamified hiking app for Greater Lisbon (Sintra, Arrábida, Monsanto).

It started as "trails on a map" and turned into a full product:

🥾 **Real trails** — geometry from OpenStreetMap, not hand-drawn lines
📍 **Live trail mode** — streamed GPS, follow-me camera, progress line and automatic check-ins when you reach a checkpoint
📖 **Real stories** — every checkpoint unlocks lore sourced from Wikipedia/Wikidata or on-site inscriptions, with real archive photos and credits
💬 **Trail messages** — hikers leave tips, warnings and danger notes on the path (with likes and reports)
🗺️ **Offline maps** — download a trail's tiles and navigate with no signal; failed check-ins sync later
🌦️ **"When should I go?"** — daily weather score, best days in the next 16 days and gear advice
🏅 **Gamification** — XP, levels, badges and partner rewards
🌍 **PT + EN** — full UI and bilingual trail content, switchable in the app

Stack: **Flutter** (maps, GPS, offline tiles) · **Fastify + TypeScript** · **PostgreSQL + Prisma** · data pipelines over Overpass, Wikipedia, Wikimedia Commons and Open-Meteo.

Tested on a real device, including a test account with simulated GPS to walk any trail from the sofa.

Open source (GPL-3.0): https://github.com/andre-franciosi/kumpass

Feedback welcome — especially from hikers and Flutter devs. What would you add next? 🥾

#Flutter #OpenSource #OpenStreetMap #Gamification #MobileDevelopment #Hiking #Lisbon #PostgreSQL #Fastify
