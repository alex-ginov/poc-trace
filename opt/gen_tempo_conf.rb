#!/usr/bin/env ruby

require "erb"
require "yaml"

# Activer le mode debug si la variable d'environnement est définie
DEBUG = ENV["DEBUG"] == "true"

def debug(msg)
  STDERR.puts "[DEBUG] #{msg}" if DEBUG
end

# Fonction helper pour récupérer les variables d'environnement
def get_env(key, default = nil)
  value = ENV[key] || default
  debug("get_env(#{key}) = #{value.inspect}")
  value
end

# Configuration du serveur
def server_config
  config = {
    "http_listen_port" => get_env("PORT", "3200").to_i,  # Utiliser le port fourni par Scalingo
    "grpc_listen_port" => get_env("TEMPO_GRPC_LISTEN_PORT", "9095").to_i
  }
  
  debug("Configuration du serveur: #{config.inspect}")
  config
end

# Configuration du stockage
def storage_config
  debug("Début de la configuration du stockage")
  
  # Initialiser la structure de configuration complète
  config = {
    "trace" => {},
    "wal" => {},
    "local" => nil,
    "s3" => nil
  }
  
  # Backend de stockage
  backend = get_env("TEMPO_STORAGE_BACKEND", "local").to_s.downcase
  debug("Backend de stockage: #{backend}")
  
  config["trace"]["backend"] = backend
  
  # Configuration WAL
  config["wal"]["path"] = get_env("TEMPO_STORAGE_WAL_PATH", "/tmp/tempo/wal")
  
  # Configuration locale
  if backend == "local"
    debug("Configuration du stockage local")
    config["local"] = {
      "path" => get_env("TEMPO_STORAGE_LOCAL_PATH", "/tmp/tempo/blocks")
    }
  end
  
  # Configuration S3 (si nécessaire)
  if backend == "s3"
    debug("Configuration du stockage S3")
    s3_bucket = get_env("TEMPO_STORAGE_S3_BUCKET")
    
    if s3_bucket.nil? || s3_bucket.empty?
      raise "TEMPO_STORAGE_S3_BUCKET doit être défini pour utiliser le backend S3"
    end
    
    config["s3"] = {
      "bucket" => s3_bucket,
      "endpoint" => get_env("TEMPO_STORAGE_S3_ENDPOINT"),
      "access_key" => get_env("TEMPO_STORAGE_S3_ACCESS_KEY_ID"),
      "secret_key" => get_env("TEMPO_STORAGE_S3_SECRET_ACCESS_KEY"),
      "insecure" => get_env("TEMPO_STORAGE_S3_INSECURE", "false").to_s.downcase == "true"
    }
  end
  
  debug("Configuration du stockage générée: #{config.inspect}")
  
  # Valider la structure de configuration
  if config["trace"].nil? || config["trace"]["backend"].nil?
    raise "Configuration de stockage invalide: section 'trace' manquante ou incomplète"
  end
  
  config
end

begin
  debug("Début de la génération de la configuration Tempo")
  
  # Charger le template
  template_path = "#{ENV["BUILDPACK_DIR"]}/opt/tempo.yaml.erb"
  debug("Chemin du template: #{template_path}")
  
  if !File.exist?(template_path)
    raise "Template non trouvé à #{template_path}"
  end
  
  content = File.read(template_path)
  debug("Template chargé (#{content.length} octets)")
  
  # Créer le template ERB avec le mode de coupe des espaces
  erb_template = ERB.new(content, trim_mode: "-")
  
  # Générer la configuration
  debug("Génération de la configuration...")
  config_yaml = erb_template.result(binding)
  
  # Valider le YAML généré
  begin
    YAML.safe_load(config_yaml)
    debug("Configuration YAML valide")
  rescue Psych::SyntaxError => e
    debug("ERREUR: Configuration YAML invalide: #{e.message}")
    debug("Contenu généré:\n#{config_yaml}")
    raise "La configuration générée n'est pas un YAML valide: #{e.message}"
  end
  
  # Afficher la configuration générée
  puts config_yaml
  debug("Configuration générée avec succès")
  
rescue => e
  STDERR.puts "ERREUR lors de la génération de la configuration: #{e.class}: #{e.message}"
  STDERR.puts "Backtrace:"
  STDERR.puts e.backtrace.join("\n")
  exit 1
end