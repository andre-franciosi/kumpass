#!/usr/bin/env bash
# Instala o Android SDK (cmdline-tools, platform-tools, emulator, system image)
# em ~/Android/Sdk e cria um AVD chamado "kumpas".
set -euo pipefail

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
AVDMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"

if [ ! -x "$SDKMANAGER" ]; then
  echo "cmdline-tools não encontradas em $ANDROID_HOME. Corre primeiro o download." >&2
  exit 1
fi

echo "==> A aceitar licenças"
yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true

echo "==> A instalar componentes do SDK"
"$SDKMANAGER" --install \
  "platform-tools" \
  "emulator" \
  "platforms;android-35" \
  "system-images;android-35;google_apis;x86_64"

echo "==> A criar AVD 'kumpas' (se não existir)"
if ! "$AVDMANAGER" list avd 2>/dev/null | grep -q "Name: kumpas"; then
  echo "no" | "$AVDMANAGER" create avd \
    --name kumpas \
    --package "system-images;android-35;google_apis;x86_64" \
    --device "pixel_6"
else
  echo "AVD 'kumpas' já existe."
fi

echo "==> Concluído."
echo "ANDROID_HOME=$ANDROID_HOME"
"$AVDMANAGER" list avd | grep -E "Name:|Path:" || true