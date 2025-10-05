#!/usr/bin/env ruby
# ============================================================
# Génération statique d'une configuration Grafana Tempo
# Compatible Scalingo (écoute sur le port $PORT)
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
    grpc_listen_port: #{port}

  distributor:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: "0.0.0.0:#{port}"
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
  YAML

  # Affiche le contenu généré (utile pour debugging)
  puts "-----> Génération de tempo.yaml (port: #{port})"
  puts config
  puts "✓ tempo.yaml généré avec succès"
  exit 0

rescue => e
  STDERR.puts "ERREUR lors de la génération de la configuration: #{e.class}: #{e.message}"
  STDERR.puts e.backtrace.join("\n")
  exit 1
end
