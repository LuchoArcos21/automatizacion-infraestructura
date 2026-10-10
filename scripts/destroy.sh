#!/usr/bin/env bash
# destroy.sh - Elimina toda la infraestructura
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/terraform"

echo "==> terraform destroy"
terraform destroy -auto-approve -input=false
echo "Infraestructura destruida."
