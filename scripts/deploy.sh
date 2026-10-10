#!/usr/bin/env bash
# deploy.sh - Despliegue automatizado: init, fmt, validate, plan, apply
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/terraform"

echo "==> [1/5] terraform init"
terraform init -input=false

echo "==> [2/5] terraform fmt"
terraform fmt -recursive

echo "==> [3/5] terraform validate"
terraform validate

echo "==> [4/5] terraform plan"
terraform plan -input=false -out=tfplan

echo "==> [5/5] terraform apply"
terraform apply -input=false tfplan
rm -f tfplan

echo
echo "Infraestructura desplegada correctamente."
terraform output
