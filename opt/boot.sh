#!/bin/bash

set -e

# Mode debug si nécessaire
if [ -n "$DEBUG" ]; then
  set -x
fi

echo "=====> Démarrage de Grafana Tempo"

# Chemins
TEMPO_BIN="/app/tempo/tempo"
TEMPO_CONFIG_FILE="/app/tempo/etc/tempo.yaml"

# Vérifications
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

# Créer les répertoires nécessaires
mkdir -p /tmp/tempo/wal
mkdir -p /tmp/tempo/blocks

echo "=====> Lancement de Tempo..."

# Démarrer Tempo avec la configuration
exec "$TEMPO_BIN" \
  -config.file="$TEMPO_CONFIG_FILE" \
  -target=all \
  -server.http-listen-port="$PORT"