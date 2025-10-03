#!/bin/bash

export_env_dir() {
  local env_dir=$1
  if [ -d "$env_dir" ]; then
    for e in $(ls $env_dir);
    do
      echo "  $e=$(cat $env_dir/$e)"
      export $e=$(cat $env_dir/$e)
    done
  fi
}

