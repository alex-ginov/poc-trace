#!/bin/bash

set -e

if [ -n "$DEBUG" ]; then
  set -x
fi

echo "=====> Démarrage de Grafana Tempo"

# Chemins mis à jour pour correspondre à la structure de déploiement Scalingo
TEMPO_BIN="/app/tempo"
TEMPO_CONFIG_FILE="/app/etc/tempo.yaml"

# Vérifier que l'exécutable existe
if [ ! -f "$TEMPO_BIN" ]; then
  echo "ERREUR: Exécutable Tempo non trouvé à $TEMPO_BIN"
  echo "Contenu du répertoire /app :"
  ls -la /app/
  exit 1
fi

# Vérifier que le fichier de configuration existe
if [ ! -f "$TEMPO_CONFIG_FILE" ]; then
  echo "ERREUR: Fichier de configuration non trouvé à $TEMPO_CONFIG_FILE"
  echo "Contenu du répertoire /app :"
  ls -la /app/
  exit 1
fi

# Vérifier que le port est défini
if [ -z "$PORT" ]; then
  echo "ERREUR: Variable PORT non définie"
  exit 1
fi

# Afficher les informations de débogage
echo "===== INFORMATIONS DE DÉBOGAGE ====="
echo "Configuration: $TEMPO_CONFIG_FILE"
echo "Port HTTP: $PORT"
echo "Exécutable: $TEMPO_BIN"

# Vérifier les permissions
echo "Permissions de l'exécutable:"
ls -l "$TEMPO_BIN"

# Créer les répertoires nécessaires
mkdir -p /tmp/tempo/wal
mkdir -p /tmp/tempo/blocks

echo "=====> Lancement de Tempo..."

# Exécuter Tempo avec les paramètres appropriés
exec "$TEMPO_BIN" \
  --config.file="$TEMPO_CONFIG_FILE" \
  --target=all \
  --server.http-listen-port="$PORT"