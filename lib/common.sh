#!/bin/bash

# Fonction pour l'indentation du texte
indent() {
  # Version portable de l'indentation
  # Utilise sed pour ajouter 7 espaces au début de chaque ligne
  sed -u 's/^/       /'
}

# Fonction pour exporter les variables d'environnement
export_env_dir() {
  local env_dir=$1
  if [ -d "$env_dir" ]; then
    local whitelist_regex=${2:-''}
    local blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
    
    if [ -z "$env_dir" ]; then
      return
    fi
    
    for e in $(ls $env_dir); do
      echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
      export "$e=$(cat $env_dir/$e)"
      :
    done
  fi
}