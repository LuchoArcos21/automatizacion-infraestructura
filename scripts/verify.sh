#!/usr/bin/env bash
# verify.sh - Verifica que la infraestructura creada corresponde con el código
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF="$ROOT/terraform"
LOG="$ROOT/evidencias/verify_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$ROOT/evidencias"

OK=0; FAIL=0
check() {  # check "descripción" comando...
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "[ OK ] $desc"; OK=$((OK+1))
  else
    echo "[FAIL] $desc"; FAIL=$((FAIL+1))
  fi
}

ip_of() { docker inspect -f "{{(index .NetworkSettings.Networks \"$2\").IPAddress}}" "$1"; }

{
echo "=== Verificación de infraestructura - $(date) ==="

NET=$(terraform -chdir="$TF" output -raw network_name 2>/dev/null || echo "lab-network")
WEB=$(terraform -chdir="$TF" output -raw web_container_name 2>/dev/null || echo "lab-web")
APP=$(terraform -chdir="$TF" output -raw app_container_name 2>/dev/null || echo "lab-app")
DB=$(terraform -chdir="$TF" output -raw db_container_name 2>/dev/null || echo "lab-db")
URL=$(terraform -chdir="$TF" output -raw web_url 2>/dev/null || echo "http://localhost")

echo; echo "--- terraform validate ---"
terraform -chdir="$TF" validate

echo; echo "--- terraform state list ---"
terraform -chdir="$TF" state list

echo; echo "--- docker ps ---"
docker ps --filter "name=lab-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo; echo "--- docker network ls ---"
docker network ls

echo; echo "--- IPs asignadas en $NET ---"
docker network inspect "$NET" \
  --format '{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{"\n"}}{{end}}'

echo; echo "--- curl $URL ---"
curl -s -i "$URL" | head -n 12

echo; echo "--- Comprobaciones automáticas ---"
check "Configuración Terraform válida"   terraform -chdir="$TF" validate
check "Red $NET existe"                  docker network inspect "$NET"
check "Contenedor WEB en ejecución"      docker exec "$WEB" true
check "Contenedor APP en ejecución"      docker exec "$APP" true
check "Contenedor DB en ejecución"       docker exec "$DB" true
check "WEB tiene IP 10.10.0.10"          test "$(ip_of "$WEB" "$NET")" = "10.10.0.10"
check "APP tiene IP 10.10.0.20"          test "$(ip_of "$APP" "$NET")" = "10.10.0.20"
check "DB tiene IP 10.10.0.30"           test "$(ip_of "$DB" "$NET")" = "10.10.0.30"
check "WEB -> APP (ping 10.10.0.20)"     docker exec "$WEB" ping -c 2 -W 2 10.10.0.20
check "WEB -> DB  (ping 10.10.0.30)"     docker exec "$WEB" ping -c 2 -W 2 10.10.0.30
check "APP -> DB  (ping 10.10.0.30)"     docker exec "$APP" ping -c 2 -W 2 10.10.0.30
check "PostgreSQL acepta conexiones"     docker exec "$DB" pg_isready
check "HTTP responde en $URL"            curl -sf "$URL"
check "Proxy WEB -> APP (/app/)"         curl -sf "$URL/app/"

echo
echo "Resultado: $OK correctas, $FAIL fallidas"
} 2>&1 | tee "$LOG"

echo "Log guardado en: $LOG"
grep -q " 0 fallidas" "$LOG"
