#!/usr/bin/env bash
# wrapper around `docker compose` that:
#   - discovers host-specific GIDs (docker, render, video) at runtime so the
#     compose file is portable between machines that assign these groups
#     different IDs
#   - probes AgentStack's actual UI port after `up` instead of guessing
#   - on `down`, sweeps containers spawned *outside* the compose project by
#     openhands and agentstack/beeai (they bind-mount the host docker socket
#     and create their own sandbox / kind-cluster containers)
#
# usage: ./docker-compose.sh up
#        ./docker-compose.sh down

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

cmd="${1:-}"

# ---------------------------------------------------------------------------
# discover host-specific GIDs
# ---------------------------------------------------------------------------
gid_or_default() {
  local name="$1" default="$2"
  local found
  found=$(getent group "$name" 2>/dev/null | cut -d: -f3 || true)
  if [ -n "$found" ]; then
    echo "$found"
  else
    echo "WARN: host group '$name' not found, defaulting to GID $default" >&2
    echo "$default"
  fi
}

detect_gids() {
  export VIDEO_GID="$(gid_or_default video 44)"
  export RENDER_GID="$(gid_or_default render 110)"
  export DOCKER_GID="$(gid_or_default docker 999)"

  echo "==> host GIDs:"
  printf "      docker = %s\n      render = %s\n      video  = %s\n" \
    "$DOCKER_GID" "$RENDER_GID" "$VIDEO_GID"
}

# ---------------------------------------------------------------------------
# probe AgentStack's actual UI port
#
# `docker compose port` returns the host port mapped to a given container
# port. we try the common AgentStack UI ports (in container) and, for any
# that's actually published AND responding to HTTP, we report that URL.
# ---------------------------------------------------------------------------
get_agentstack_url() {
  local cport mapped host_port
  for cport in 8333 8334 13900; do
    mapped=$(docker compose port agent-tools "$cport" 2>/dev/null | tail -1) || continue
    [ -n "$mapped" ] || continue
    host_port=$(echo "$mapped" | awk -F: '{print $NF}')
    if curl -fsS --max-time 2 "http://localhost:${host_port}/" >/dev/null 2>&1; then
      echo "http://localhost:${host_port}"
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# clean up containers that openhands/agentstack spawn outside the compose
# project (compose can't see or remove them)
# ---------------------------------------------------------------------------
cleanup_orphans() {
  echo "==> removing OpenHands runtime sandbox containers"
  docker ps -a --format '{{.ID}} {{.Image}}' \
    | awk '$2 ~ /openhands\/(agent-server|runtime)/ {print $1}' \
    | xargs -r docker rm -f

  echo "==> removing OpenHands by-name (openhands-*)"
  docker ps -a --format '{{.ID}} {{.Names}}' \
    | awk '$2 ~ /^openhands-/ {print $1}' \
    | xargs -r docker rm -f

  echo "==> removing AgentStack / BeeAI kind cluster nodes"
  docker ps -aq --filter "label=io.x-k8s.kind.cluster" \
    | xargs -r docker rm -f

  echo "==> removing AgentStack / BeeAI platform containers (by name)"
  docker ps -a --format '{{.ID}} {{.Names}}' \
    | awk '$2 ~ /(agentstack|beeai)/ {print $1}' \
    | xargs -r docker rm -f

  echo "==> pruning dangling networks (best-effort)"
  docker network prune -f >/dev/null 2>&1 || true
}

# ---------------------------------------------------------------------------
# entry point
# ---------------------------------------------------------------------------
case "$cmd" in
  up)
    detect_gids
    docker compose up -d --build

    echo
    echo "stack is up. UIs:"
    echo "  http://localhost:8080  (Open WebUI)"
    echo "  http://localhost:8501  (CrewAI Studio)"
    echo "  http://localhost:3000  (OpenHands)"

    if url=$(get_agentstack_url); then
      echo "  ${url}  (AgentStack UI)"
    else
      echo "  AgentStack UI: not yet running. Bootstrap once with:"
      echo "    docker compose exec agent-tools agentstack self install"
      echo "    docker compose exec agent-tools agentstack ui --host 0.0.0.0"
      echo "  Then rerun this script's 'up' to refresh and detect the port."
    fi
    ;;

  down)
    detect_gids
    docker compose down --remove-orphans
    cleanup_orphans
    echo
    echo "stack is down. data volumes preserved."
    echo "use 'docker compose down -v' from this dir to wipe volumes."
    ;;

  *)
    echo "usage: $0 {up|down}" >&2
    exit 1
    ;;
esac
