#!/usr/bin/env bash
# Arranca o Waydroid e garante rede + adb. CORRER NO TEU TERMINAL (precisa de sudo).
set -uo pipefail
export PATH="$HOME/Android/Sdk/platform-tools:$PATH"

CONTAINER_IP="192.168.240.112"
BRIDGE_IP="192.168.240.1"

echo "==> 1/6 Garantir binderfs"
if [ ! -e /dev/binderfs/binder ]; then
  sudo mkdir -p /dev/binderfs
  sudo mount -t binder binder /dev/binderfs
fi

echo "==> 2/6 Arrancar container"
sudo systemctl start waydroid-container 2>/dev/null || true
sleep 3

echo "==> 3/6 Arrancar sessão (persistente, desanexada do terminal)"
setsid waydroid session start >/tmp/waydroid-session.log 2>&1 < /dev/null &
sleep 10

echo "==> 4/6 Abrir UI (persistente — mantém o container acordado)"
setsid waydroid show-full-ui >/tmp/waydroid-ui.log 2>&1 < /dev/null &
sleep 12

echo "==> 5/6 Corrigir rede do container (unfreeze + rota)"
CPID=$(sudo lxc-info -P /var/lib/waydroid/lxc -n waydroid -p 2>/dev/null | awk '{print $2}')
if [ -n "$CPID" ]; then
  sudo lxc-unfreeze -P /var/lib/waydroid/lxc -n waydroid 2>/dev/null || true
  sudo nsenter -t "$CPID" -n ip link set eth0 up 2>/dev/null || true
  sudo nsenter -t "$CPID" -n ip addr add "$CONTAINER_IP/24" dev eth0 2>/dev/null || true
  sudo nsenter -t "$CPID" -n ip route add default via "$BRIDGE_IP" 2>/dev/null || true
  echo "    eth0: $(sudo nsenter -t "$CPID" -n ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\S+')"
else
  echo "    AVISO: container não encontrado"
fi

echo "==> 6/6 Ligar adb"
adb connect "$CONTAINER_IP:5555" 2>&1 || true
sleep 3
adb devices -l 2>&1

echo
echo "==> Pronto. Backend acessível do container em http://$BRIDGE_IP:3000"
echo "==> Corre o app com: make mobile-waydroid"