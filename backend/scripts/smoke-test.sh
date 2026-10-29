#!/usr/bin/env bash
# Smoke test end-to-end do backend Kumpas.
# Uso: ./scripts/smoke-test.sh [BASE_URL]
set -euo pipefail

BASE_URL="${1:-http://localhost:3000}"
USER_ID="11111111-1111-1111-1111-111111111111"

pass() { printf '\033[32m✔ %s\033[0m\n' "$1"; }
fail() { printf '\033[31m✘ %s\033[0m\n' "$1"; exit 1; }
info() { printf '\033[36m→ %s\033[0m\n' "$1"; }

info "A testar $BASE_URL"

# 1. Health
HEALTH=$(curl -sf "$BASE_URL/health" || fail "GET /health falhou")
[ "$(echo "$HEALTH" | jq -r .status)" = "ok" ] || fail "Health inesperado: $HEALTH"
pass "GET /health"

# 2. Listagem de quests
QUESTS=$(curl -sf "$BASE_URL/api/quests" || fail "GET /api/quests falhou")
COUNT=$(echo "$QUESTS" | jq 'length')
[ "$COUNT" -gt 0 ] || fail "Sem quests. Corre 'npm run seed' primeiro."
pass "GET /api/quests ($COUNT quests)"

QUEST_ID=$(echo "$QUESTS" | jq -r '.[0].id')
DIFFICULTY=$(echo "$QUESTS" | jq -r '.[0].difficulty')
XP_REWARD=$(echo "$QUESTS" | jq -r '.[0].xpReward')
[ "$DIFFICULTY" -ge 1 ] && [ "$DIFFICULTY" -le 5 ] || fail "Nível inválido: $DIFFICULTY"
[ "$XP_REWARD" -gt 0 ] || fail "XP da trilha inválido: $XP_REWARD"
pass "Nível calculado = $DIFFICULTY | XP = $XP_REWARD"

# 3. Detalhe da quest
DETAIL=$(curl -sf "$BASE_URL/api/quests/$QUEST_ID?userId=$USER_ID" || fail "GET /api/quests/:id falhou")
CP_ID=$(echo "$DETAIL" | jq -r '.checkpoints[0].id')
CP_LAT=$(echo "$DETAIL" | jq -r '.checkpoints[0].lat')
CP_LNG=$(echo "$DETAIL" | jq -r '.checkpoints[0].lng')
SCORE=$(echo "$DETAIL" | jq -r '.difficultyBreakdown.score')
[ -n "$SCORE" ] && [ "$SCORE" != "null" ] || fail "Detalhe sem breakdown de dificuldade"
TRACK_POINTS=$(echo "$DETAIL" | jq -r '.track | length')
[ "$TRACK_POINTS" -gt 10 ] || fail "Track real ausente: $TRACK_POINTS pontos"
[ "$(echo "$DETAIL" | jq -r '.bbox != null')" = "true" ] || fail "Detalhe sem bbox"
pass "GET /api/quests/:id (track $TRACK_POINTS pts | score $SCORE)"

# 4. Unlock FORA do raio (coordenadas longe)
FAR=$(curl -s -X POST "$BASE_URL/api/checkpoints/unlock" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER_ID\",\"checkpointId\":\"$CP_ID\",\"userLat\":0,\"userLng\":0}")
[ "$(echo "$FAR" | jq -r .success)" = "false" ] || fail "Esperava falha fora do raio: $FAR"
pass "POST unlock fora do raio → $(echo "$FAR" | jq -r .message)"

# 5. Unlock DENTRO do raio (coordenadas exatas do checkpoint)
NEAR=$(curl -s -X POST "$BASE_URL/api/checkpoints/unlock" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER_ID\",\"checkpointId\":\"$CP_ID\",\"userLat\":$CP_LAT,\"userLng\":$CP_LNG}")
[ "$(echo "$NEAR" | jq -r .success)" = "true" ] || fail "Esperava sucesso dentro do raio: $NEAR"
pass "POST unlock dentro do raio → lore: $(echo "$NEAR" | jq -r '.lore.title')"

# 6. Idempotência (repetir unlock não deve falhar)
AGAIN=$(curl -s -X POST "$BASE_URL/api/checkpoints/unlock" \
  -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER_ID\",\"checkpointId\":\"$CP_ID\",\"userLat\":$CP_LAT,\"userLng\":$CP_LNG}")
[ "$(echo "$AGAIN" | jq -r .success)" = "true" ] || fail "Idempotência falhou: $AGAIN"
pass "POST unlock idempotente"

# 7. Perfil gamificado
PROFILE=$(curl -sf "$BASE_URL/api/users/$USER_ID/profile" || fail "GET /api/users/:id/profile falhou")
LEVEL=$(echo "$PROFILE" | jq -r '.level')
[ "$LEVEL" -ge 1 ] || fail "Perfil sem nível: $PROFILE"
pass "GET /api/users/:id/profile (nível $LEVEL, $(echo "$PROFILE" | jq -r .xp) XP)"

# 8. Login (lookup/create por email)
LOGIN=$(curl -sf -X POST "$BASE_URL/api/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"tester@kumpas.dev"}' || fail "POST /api/auth/login falhou")
[ "$(echo "$LOGIN" | jq -r .id)" = "$USER_ID" ] || fail "Login devolveu user errado: $LOGIN"
pass "POST /api/auth/login → $(echo "$LOGIN" | jq -r .name)"

# 9. Reviews
REVIEWS=$(curl -sf "$BASE_URL/api/quests/$QUEST_ID/reviews" || fail "GET reviews falhou")
echo "$REVIEWS" | jq -e 'type == "array"' >/dev/null || fail "Reviews não é lista"
pass "GET /api/quests/:id/reviews ($(echo "$REVIEWS" | jq 'length') reviews)"

# 10. Meteorologia (Open-Meteo) — dependência externa: 502 não falha o teste
TOMORROW=$(date -u -d tomorrow +%Y-%m-%d)
WEATHER_CODE=$(curl -s -o /tmp/kumpas-weather.json -w '%{http_code}' \
  "$BASE_URL/api/weather?lat=38.79&lng=-9.39&date=$TOMORROW")
if [ "$WEATHER_CODE" = "200" ]; then
  W_SCORE=$(jq -r '.weather.score' /tmp/kumpas-weather.json)
  [ "$W_SCORE" -ge 0 ] && [ "$W_SCORE" -le 100 ] || fail "Score do clima inválido: $W_SCORE"
  pass "GET /api/weather → $(jq -r '.weather.rating' /tmp/kumpas-weather.json) ($W_SCORE/100)"
else
  printf '\033[33m⚠ GET /api/weather indisponível (HTTP %s) — serviço externo\033[0m\n' "$WEATHER_CODE"
fi

BEST_CODE=$(curl -s -o /tmp/kumpas-best.json -w '%{http_code}' "$BASE_URL/api/quests/$QUEST_ID/best-days")
if [ "$BEST_CODE" = "200" ]; then
  BEST_COUNT=$(jq -r '.days | length' /tmp/kumpas-best.json)
  [ "$BEST_COUNT" -gt 0 ] || fail "best-days sem resultados"
  pass "GET /api/quests/:id/best-days ($BEST_COUNT dias)"
else
  printf '\033[33m⚠ GET best-days indisponível (HTTP %s) — serviço externo\033[0m\n' "$BEST_CODE"
fi

# 10b. Recados do caminho
MSGS=$(curl -sf "$BASE_URL/api/quests/$QUEST_ID/messages?userId=$USER_ID" || fail "GET messages falhou")
echo "$MSGS" | jq -e 'type == "array"' >/dev/null || fail "Recados não é lista"
pass "GET /api/quests/:id/messages ($(echo "$MSGS" | jq 'length') recados)"

FARMSG_CODE=$(curl -s -o /tmp/kumpas-msg.json -w '%{http_code}' -X POST \
  "$BASE_URL/api/quests/$QUEST_ID/messages" -H 'Content-Type: application/json' \
  -d "{\"userId\":\"$USER_ID\",\"category\":\"dica\",\"text\":\"Teste longe\",\"lat\":0,\"lng\":0}")
[ "$FARMSG_CODE" = "400" ] || fail "Recado fora da trilha devia dar 400 (deu $FARMSG_CODE)"
pass "Recado fora da trilha recusado (400)"

# 10c. Conta de teste com GPS simulado
GPS_LOGIN=$(curl -sf -X POST "$BASE_URL/api/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"tester.gps@kumpas.dev"}' || fail "Login do test user falhou")
[ "$(echo "$GPS_LOGIN" | jq -r .isTest)" = "true" ] || fail "Test user sem isTest: $GPS_LOGIN"
pass "Login test user (isTest=true)"

# 10d. Conteúdo EN (títulos/descrições/lore traduzidos)
EN_TITLE=$(curl -sf "$BASE_URL/api/quests?lang=en" | jq -r '.[0].title')
PT_TITLE=$(curl -sf "$BASE_URL/api/quests" | jq -r '.[0].title')
[ "$EN_TITLE" != "$PT_TITLE" ] || fail "Conteúdo EN em falta (título igual: $EN_TITLE)"
EN_LORE=$(curl -sf "$BASE_URL/api/quests/$QUEST_ID?lang=en" | jq -r '.checkpoints[0].loreEn // .checkpoints[0].lore')
[ -n "$EN_LORE" ] && [ "$EN_LORE" != "null" ] || fail "Lore EN em falta"
pass "Conteúdo EN ("$EN_TITLE")"

# 11. Conteúdo real (aviso suave — depende do pipeline make content)
NOSRC=$(curl -sf "$BASE_URL/api/quests/$QUEST_ID" | \
  jq '[.checkpoints[] | select(.loreSource == null or .loreSource == "Fallback")] | length')
if [ "$NOSRC" -gt 0 ]; then
  printf '\033[33m⚠ %s checkpoints sem história com fonte — corre make content + seed\033[0m\n' "$NOSRC"
else
  pass "Checkpoints com histórias de fonte real"
fi

printf '\n\033[32mTodos os testes passaram.\033[0m\n'
