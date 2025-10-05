#!/usr/bin/env ruby
# ============================================================
# Génération statique d'une configuration Grafana Tempo
# Compatible Scalingo (écoute sur le port $PORT pour HTTP, 9095 pour gRPC)
# ============================================================

begin
  # Récupère le port exposé par Scalingo, sinon 8080 par défaut
  port = ENV["PORT"] || "8080"

  config = <<~YAML
  # ================================================
  # Configuration Grafana Tempo pour Scalingo
  # ================================================
  server:
    http_listen_port: #{port}
    grpc_listen_port: 9095

  distributor:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: "0.0.0.0:9095"
          http:
            endpoint: "0.0.0.0:#{port}"

  ingester:
    max_block_duration: 1h
    max_block_bytes: 104857600
    complete_block_timeout: 5m

  compactor:
    compaction:
      block_retention: 48h

  storage:
    trace:
      backend: local
    wal:
      path: /tmp/tempo/wal
    local:
      path: /tmp/tempo/blocks

  # Désactiver l'authentification pour simplifier
  auth:
    enabled: false

  # Désactiver les métriques Prometheus intégrées
  # car elles entrent en conflit avec l'agent
  metrics_generator:
    storage:
      path: /tmp/tempo/metrics
  YAML

  # Afficher la configuration générée
  puts config

rescue => e
  STDERR.puts "ERREUR lors de la génération de la configuration: #{e.message}"
  STDERR.puts e.backtrace.join("\n")
  exit 1
end

# Toujours terminer avec succès
exit 0