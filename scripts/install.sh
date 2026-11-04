#!/usr/bin/env bash
# Bash 3.2+; Linux, macOS and Docker-capable NAS hosts.
set -euo pipefail

install_dir="${HOME}/qqbot-napcat"
repository="cjz-wr/qqbot-napcat-docker-deploy"
ref="main"
update=0
no_open=0

usage() {
  cat <<'EOF'
Usage: bash scripts/install.sh [--dir PATH] [--update] [--no-open]
                               [--repository OWNER/REPO] [--ref REF]
Existing .env is always preserved. --update backs up and replaces Compose.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir|--repository|--ref)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then echo "Missing value for $1" >&2; exit 2; fi
      case "$1" in
        --dir) install_dir="$2" ;;
        --repository) repository="$2" ;;
        --ref) ref="$2" ;;
      esac
      shift 2 ;;
    --update) update=1; shift ;;
    --no-open) no_open=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! [[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] ||
   ! [[ "$ref" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] || [[ "$ref" == *..* ]]; then
  echo "Invalid repository or ref." >&2; exit 2
fi

command -v docker >/dev/null 2>&1 || { echo "Install Docker first." >&2; exit 1; }
docker compose version >/dev/null
docker_os="$(docker info --format '{{.OSType}}')"
[ "$docker_os" = "linux" ] || { echo "Start Docker in Linux container mode." >&2; exit 1; }

mkdir -p -- "$install_dir"
install_dir="$(cd -- "$install_dir" && pwd -P)"
stage="$(mktemp -d "$install_dir/.qqbot-install.XXXXXXXX")"
trap 'rm -rf -- "$stage"' EXIT

# A cloned checkout can install without downloading deployment files. Updates
# always fetch the requested ref instead of reusing an outdated local copy.
local_source=""
script_path="${BASH_SOURCE[0]:-}"
if [ "$update" -eq 0 ] && [ -n "$script_path" ] && [ -f "$script_path" ]; then
  candidate="$(cd -- "$(dirname -- "$script_path")/.." && pwd -P)"
  if [ -f "$candidate/docker-compose.yml" ] && [ -f "$candidate/.env.example" ]; then
    local_source="$candidate"
  fi
fi
if [ -z "$local_source" ]; then
  command -v curl >/dev/null 2>&1 || { echo "Install curl first." >&2; exit 1; }
fi

files=(docker-compose.yml .env.example scripts/install.sh scripts/install.ps1 README.md LICENSE)
for file in "${files[@]}"; do
  mkdir -p -- "$stage/$(dirname -- "$file")"
  if [ -n "$local_source" ]; then
    cp -- "$local_source/$file" "$stage/$file"
  else
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 180 \
      "https://raw.githubusercontent.com/$repository/$ref/$file" -o "$stage/$file"
  fi
done

if [ -f "$install_dir/docker-compose.yml" ]; then
  if [ "$update" -eq 1 ]; then
    mkdir -p -- "$install_dir/.backups"
    cp -- "$install_dir/docker-compose.yml" \
      "$install_dir/.backups/docker-compose.$(date +%Y%m%d-%H%M%S).$$.yml"
  else
    echo "Keeping existing docker-compose.yml (use --update to replace it)."
    rm -- "$stage/docker-compose.yml"
  fi
fi
for file in "${files[@]}"; do
  if [ -f "$stage/$file" ]; then
    mkdir -p -- "$install_dir/$(dirname -- "$file")"
    mv -- "$stage/$file" "$install_dir/$file"
  fi
done
if [ ! -f "$install_dir/.env" ]; then
  (umask 077; cp -- "$install_dir/.env.example" "$install_dir/.env")
fi
chmod +x "$install_dir/scripts/install.sh"

compose=(docker compose --project-directory "$install_dir" -f "$install_dir/docker-compose.yml")
echo "Pulling images and starting services in $install_dir ..."
"${compose[@]}" pull
"${compose[@]}" up -d

endpoint() {
  local address
  address="$("${compose[@]}" port "$1" "$2" 2>/dev/null)" || return 1
  case "$address" in
    0.0.0.0:*|\[::\]:*) address="127.0.0.1:${address##*:}" ;;
  esac
  [ -n "$address" ] || return 1
  printf 'http://%s' "$address"
}
bot_url="$(endpoint bot 8881)" || bot_url="(see .env BOT_PORT)"
napcat_url="$(endpoint napcat 6099)" || napcat_url=""
echo "Bot console: $bot_url"
echo "NapCat login: ${napcat_url:-http://127.0.0.1:6099}/webui"
echo "Login details below may take a moment to appear; run docker compose logs bot napcat again if needed."
"${compose[@]}" logs --no-color --tail=80 bot napcat 2>&1 |
  grep -E 'WebUi Token:|WebUi User Panel Url:|Web 控制台初始口令:' || true
echo "Manage this deployment from: $install_dir"

if [ "$no_open" -eq 0 ] && [ -n "$napcat_url" ]; then
  if [ "$(uname -s)" = "Darwin" ] && command -v open >/dev/null 2>&1; then
    open "$napcat_url/webui" >/dev/null 2>&1 || true
  elif { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; } && command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$napcat_url/webui" >/dev/null 2>&1 || true
  fi
fi
