#!/usr/bin/env ruby

require "erb"

# Fonction helper pour récupérer les variables d'environnement
def get_env(key, default = nil)
  ENV[key] || default
end

# Configuration du serveur
def server_config
  {
    "http_listen_port" => get_env("TEMPO_HTTP_LISTEN_PORT", "3200").to_i,
    "grpc_listen_port" => get_env("TEMPO_GRPC_LISTEN_PORT", "9095").to_i
  }
end

# Configuration du stockage
def storage_config
  config = {}
  
  # Backend de stockage
  backend = get_env("TEMPO_STORAGE_BACKEND", "local")
  config["trace"] = {
    "backend" => backend
  }
  
  # Configuration WAL
  config["wal"] = {
    "path" => get_env("TEMPO_STORAGE_WAL_PATH", "/tmp/tempo/wal")
  }
  
  # Configuration locale
  if backend == "local"
    config["local"] = {
      "path" => get_env("TEMPO_STORAGE_LOCAL_PATH", "/tmp/tempo/blocks")
    }
  end
  
  # Configuration S3 (si nécessaire)
  if backend == "s3"
    config["s3"] = {
      "bucket" => get_env("TEMPO_STORAGE_S3_BUCKET"),
      "endpoint" => get_env("TEMPO_STORAGE_S3_ENDPOINT"),
      "access_key" => get_env("TEMPO_STORAGE_S3_ACCESS_KEY_ID"),
      "secret_key" => get_env("TEMPO_STORAGE_S3_SECRET_ACCESS_KEY"),
      "insecure" => get_env("TEMPO_STORAGE_S3_INSECURE", "false") == "true"
    }
  end
  
  config
end

# Charger le template
template_path = "#{ENV["BUILDPACK_DIR"]}/opt/tempo.yaml.erb"
if !File.exist?(template_path)
  STDERR.puts "ERREUR: Template non trouvé à #{template_path}"
  exit 1
end

content = File.read(template_path)
erb_template = ERB.new(content, trim_mode: "-")

# Générer et afficher le YAML
begin
  puts erb_template.result(binding)
rescue => e
  STDERR.puts "ERREUR lors de la génération de la configuration: #{e.message}"
  STDERR.puts e.backtrace.join("\n")
  exit 1
end