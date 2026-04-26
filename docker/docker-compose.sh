#!/usr/bin/env bash
# wrapper around `docker compose` that:
#   - discovers host-specific GIDs (render, video) at runtime so the compose
#     file is portable between machines that assign these groups different IDs
#   - polls every UI URL after `up`, prints periodic 'starting' progress,
#     and only prints the final URLs once all services are responsive
#   - on `down`, sweeps the per-task sandbox containers OpenHands spawns
#     outside the compose project (it bind-mounts the host docker socket)
#
# usage: ./docker-compose.sh up
#        ./docker-compose.sh down

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

cmd="${1:-}"

# tunables
READY_TIMEOUT="${READY_TIMEOUT:-600}"   # seconds to wait for everything
POLL_INTERVAL="${POLL_INTERVAL:-10}"    # seconds between progress prints

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

  echo "==> host GIDs:"
  printf "      render = %s\n      video  = %s\n" \
    "$RENDER_GID" "$VIDEO_GID"
}

# ---------------------------------------------------------------------------
# treat any HTTP response (even 4xx) as 'alive'. only connection failure
# (curl exit !=0 / code 000) and gateway errors (502-504) count as 'down'.
# ---------------------------------------------------------------------------
is_url_alive() {
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 2 "$1" 2>/dev/null || echo "000")
  case "$code" in
    000|502|503|504) return 1 ;;
    *) return 0 ;;
  esac
}

# ---------------------------------------------------------------------------
# poll every service URL and print periodic 'starting' messages until all
# are responsive (or timeout). prints the final URL list and returns 0
# only when every service is live.
# ---------------------------------------------------------------------------
wait_for_all() {
  local services=(
    "Lemonade|http://localhost:13305/live"
    "Open WebUI|http://localhost:8080/"
    "OpenHands|http://localhost:3000/"
  )

  declare -A ready_url
  local elapsed=0

  echo "==> waiting for services to come online (timeout ${READY_TIMEOUT}s)..."

  while [ "$elapsed" -lt "$READY_TIMEOUT" ]; do
    local pending=()

    for entry in "${services[@]}"; do
      local name="${entry%%|*}"
      local url="${entry##*|}"
      if [ -n "${ready_url[$name]:-}" ]; then
        continue
      fi
      if is_url_alive "$url"; then
        ready_url[$name]="$url"
        echo "    [ready] $name → $url"
      else
        pending+=("$name")
      fi
    done

    if [ "${#pending[@]}" -eq 0 ]; then
      echo
      echo "stack is up and ready:"
      echo "  ${ready_url[Lemonade]}      (Lemonade health)"
      echo "  ${ready_url[Open WebUI]}             (Open WebUI)"
      echo "  ${ready_url[OpenHands]}             (OpenHands)"
      return 0
    fi

    printf "    starting (%ds elapsed): %s\n" "$elapsed" "$(IFS=', '; echo "${pending[*]}")"
    sleep "$POLL_INTERVAL"
    elapsed=$((elapsed + POLL_INTERVAL))
  done

  echo
  echo "WARN: timed out after ${READY_TIMEOUT}s. these services never responded:" >&2
  for entry in "${services[@]}"; do
    local name="${entry%%|*}"
    [ -z "${ready_url[$name]:-}" ] && echo "  - $name" >&2 || true
  done
  echo "tail logs with: docker compose logs --tail 200" >&2
  return 1
}

# ---------------------------------------------------------------------------
# clean up the OpenHands per-task sandbox containers that live outside the
# compose project (compose can't see or remove them).
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
    wait_for_all
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
