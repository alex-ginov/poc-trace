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

# Afficher la configuration complète
echo "===== CONFIGURATION ====="
cat "$TEMPO_CONFIG_FILE"

# Tester l'exécution de Tempo en mode version d'abord
echo "\n===== VERSION DE TEMPO ====="
"$TEMPO_BIN" --version || echo "Impossible d'exécuter 'tempo --version'"

# Tester la validation de la configuration
echo "\n===== VALIDATION DE LA CONFIGURATION ====="
"$TEMPO_BIN" --config.file="$TEMPO_CONFIG_FILE" --check-config || echo "Échec de la validation de la configuration"

# Créer un wrapper pour Tempo avec plus de logs
tempo_wrapper() {
    echo "\n===== LANCEMENT DE TEMPO ====="
    echo "Commande: $TEMPO_BIN --config.file=$TEMPO_CONFIG_FILE --target=all --server.http-listen-port=$PORT"
    
    # Exécuter en arrière-plan pour pouvoir capturer la sortie
    "$TEMPO_BIN" \
      --config.file="$TEMPO_CONFIG_FILE" \
      --target=all \
      --server.http-listen-port="$PORT" \
      --log.level=debug \
      --log.json=false \
      2>&1 | while IFS= read -r line; do
        echo "[TEMPO] $line"
      done &
      
    # Attendre que le port soit en écoute (méthode sans nc)
    local timeout=10
    local start_time=$(date +%s)
    local port_open=0
    
    echo "Vérification du port $PORT..."
    
    while [ $port_open -eq 0 ]; do
        # Vérifier si le processus est toujours en cours d'exécution
        if ! kill -0 $! 2>/dev/null; then
            echo "ERREUR: Le processus Tempo s'est arrêté prématurément"
            return 1
        fi
        
        # Vérifier si le port est en écoute en utilisant /proc
        if [ -d "/proc/$(pgrep -f "$TEMPO_BIN")/fd" ]; then
            if ls -l /proc/$(pgrep -f "$TEMPO_BIN")/fd 2>/dev/null | grep -q "socket:.*:$PORT"; then
                port_open=1
                break
            fi
        fi
        
        # Vérifier le timeout
        local current_time=$(date +%s)
        if (( current_time - start_time > timeout )); then
            echo "ERREUR: Temps d'attente dépassé pour le démarrage de Tempo"
            echo "Derniers logs de Tempo:"
            tail -n 20 /tmp/tempo.log 2>/dev/null || echo "Aucun log disponible"
            return 1
        fi
        
        sleep 1
    done
    
    echo "Tempo est démarré et écoute sur le port $PORT"
    
    # Attendre indéfiniment
    wait
}

# Exécuter le wrapper
tempo_wrapper