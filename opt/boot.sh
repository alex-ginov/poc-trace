#!/bin/bash

set -e

if [ -n "$DEBUG" ]; then
  set -x
fi

echo "=====> Démarrage de Grafana Tempo"

TEMPO_BIN="/app/tempo_app/tempo"
TEMPO_CONFIG_FILE="/app/tempo_app/etc/tempo.yaml"

if [ ! -f "$TEMPO_BIN" ]; then
  echo "ERREUR: Exécutable Tempo non trouvé à $TEMPO_BIN"
  exit 1
fi

if [ ! -f "$TEMPO_CONFIG_FILE" ]; then
  echo "ERREUR: Fichier de configuration non trouvé à $TEMPO_CONFIG_FILE"
  exit 1
fi

if [ -z "$PORT" ]; then
  echo "ERREUR: Variable PORT non définie"
  exit 1
fi

echo "Configuration: $TEMPO_CONFIG_FILE"
echo "Port HTTP: $PORT"
echo "Exécutable: $TEMPO_BIN"

mkdir -p /tmp/tempo/wal
mkdir -p /tmp/tempo/blocks

echo "=====> Lancement de Tempo..."

exec "$TEMPO_BIN" \
  -config.file="$TEMPO_CONFIG_FILE" \
  -target=all \
  -server.http-listen-port="$PORT"