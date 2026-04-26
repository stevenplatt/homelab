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
  export KVM_GID="$(gid_or_default kvm 104)"

  echo "==> host GIDs:"
  printf "      docker = %s\n      render = %s\n      video  = %s\n      kvm    = %s\n" \
    "$DOCKER_GID" "$RENDER_GID" "$VIDEO_GID" "$KVM_GID"
}

# ---------------------------------------------------------------------------
# bootstrap AgentStack platform & launch the UI in the background.
# `agentstack self install` is idempotent — on subsequent runs it detects
# the existing platform and exits quickly.
# ---------------------------------------------------------------------------
bootstrap_agentstack() {
  echo "==> bootstrapping AgentStack platform (first run can take 5-10 min)..."
  if ! docker compose exec -T agent-tools agentstack self install; then
    echo "WARN: 'agentstack self install' failed — UI will not be reachable" >&2
    echo "      run 'docker compose logs agent-tools' to inspect"             >&2
    return 1
  fi

  echo "==> launching AgentStack UI in background..."
  # exec -d detaches; the process persists for the lifetime of the container.
  # output goes to a logfile inside the named volume so subsequent runs can
  # tail it if something goes wrong.
  docker compose exec -d agent-tools sh -c \
    'nohup agentstack ui --host 0.0.0.0 > /home/agent/.agentstack-ui.log 2>&1'

  # give the UI a few seconds to bind a port before we probe it
  sleep 5
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

    bootstrap_agentstack || true

    echo
    echo "stack is up. UIs:"
    echo "  http://localhost:8080  (Open WebUI)"
    echo "  http://localhost:8501  (CrewAI Studio)"
    echo "  http://localhost:3000  (OpenHands)"

    if url=$(get_agentstack_url); then
      echo "  ${url}  (AgentStack UI)"
    else
      echo "  AgentStack UI: not reachable yet. tail the bootstrap log with:"
      echo "    docker compose exec agent-tools cat /home/agent/.agentstack-ui.log"
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
