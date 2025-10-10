#!/usr/bin/env ruby

require "erb"
require "yaml"
require "json"

# Helper function to get environment variables safely
def get_env(key, default = nil)
  ENV[key] || default
end

# Example of how to expose environment variables to the ERB template
# You can add more helper methods here for specific Tempo configuration sections

def storage_config
  config = {}
  config["trace_by_id"] = { "backend": get_env("TEMPO_STORAGE_TRACE_BY_ID_BACKEND", "s3") } if get_env("TEMPO_STORAGE_TRACE_BY_ID_BACKEND")
  config["wal"] = { "path": get_env("TEMPO_STORAGE_WAL_PATH", "/tmp/tempo/wal") } if get_env("TEMPO_STORAGE_WAL_PATH")
  config["s3"] = { "bucket": get_env("TEMPO_STORAGE_S3_BUCKET"), "endpoint": get_env("TEMPO_STORAGE_S3_ENDPOINT") } if get_env("TEMPO_STORAGE_S3_BUCKET")
  config
end

def server_config
  config = {}
  config["http_listen_port"] = get_env("TEMPO_HTTP_LISTEN_PORT", "3200").to_i
  config["grpc_listen_port"] = get_env("TEMPO_GRPC_LISTEN_PORT", "9095").to_i
  config
end

# Load the template
# BUILDPACK_DIR est exporté par le script compile
content = File.read "#{ENV["BUILDPACK_DIR"]}/tempo.yaml.erb"
erb_template = ERB.new(content, nil, "-")

# Output the generated YAML
puts erb_template.result(binding)