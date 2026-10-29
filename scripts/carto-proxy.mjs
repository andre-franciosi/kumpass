// Proxy local de tiles CARTO Voyager para desenvolvimento.
//
// Necessário quando o dispositivo (ex.: Waydroid sem NAT) não tem internet
// externa mas o host tem. O adb reverse liga o dispositivo a este proxy.
//
// Uso:
//   CARTO_KEY=xxx node scripts/carto-proxy.mjs
//   make tiles-proxy CARTO_KEY=xxx
//   # noutro terminal:
//   make mobile-waydroid MAP_TILE_URL='http://127.0.0.1:3001/{z}/{x}/{y}.png'
import http from "node:http";

const PORT = Number(process.env.TILE_PROXY_PORT ?? 3001);
const KEY = process.env.CARTO_KEY ?? "";
const UPSTREAM =
  process.env.CARTO_UPSTREAM ??
  "https://basemaps.cartocdn.com/rastertiles/voyager";

if (!KEY) {
  console.error("CARTO_KEY em falta. Uso: CARTO_KEY=xxx node scripts/carto-proxy.mjs");
  process.exit(1);
}

const server = http.createServer(async (req, res) => {
  const match = req.url?.match(/^\/(\d+)\/(\d+)\/(\d+)\.png$/);
  if (!match) {
    res.writeHead(404).end("not found");
    return;
  }

  const [, z, x, y] = match;

  try {
    const upstream = await fetch(
      `${UPSTREAM}/${z}/${x}/${y}.png?key=${encodeURIComponent(KEY)}`,
      {
        headers: { "User-Agent": "Kumpas-dev-proxy/1.0" },
        signal: AbortSignal.timeout(15_000),
      }
    );

    if (!upstream.ok) {
      console.error(`upstream ${upstream.status} ${z}/${x}/${y}`);
      res.writeHead(upstream.status).end();
      return;
    }

    const buffer = Buffer.from(await upstream.arrayBuffer());
    res.writeHead(200, {
      "Content-Type": "image/png",
      "Cache-Control": "public, max-age=86400",
    });
    res.end(buffer);
  } catch (error) {
    console.error("tile error", `${z}/${x}/${y}`, String(error));
    res.writeHead(502).end();
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`CARTO proxy em http://0.0.0.0:${PORT} (upstream: ${UPSTREAM})`);
});
