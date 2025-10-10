#!/bin/bash

if [ -n "$DEBUG" ]; then
  set -x
fi

# Chemin vers l'exécutable Tempo et le fichier de configuration
TEMPO_BIN="/app/tempo/tempo"
TEMPO_CONFIG_FILE="/app/tempo/etc/tempo.yaml"

# Vérifier si le fichier de configuration existe
if [ ! -f "$TEMPO_CONFIG_FILE" ]; then
  echo >&2 "Erreur: Le fichier de configuration Tempo n'a pas été trouvé à $TEMPO_CONFIG_FILE"
  exit 1
fi

# Scalingo expose le port via la variable d'environnement $PORT

echo "Démarrage de Grafana Tempo avec la configuration: $TEMPO_CONFIG_FILE sur le port $PORT"

# Exécuter Tempo en lui passant le port HTTP via --target.http-listen-port
# et en s'assurant que le fichier de configuration est bien pris en compte.
exec "$TEMPO_BIN" -config.file="$TEMPO_CONFIG_FILE" -target=all -server.http-listen-port="$PORT"