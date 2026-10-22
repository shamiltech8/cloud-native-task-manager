#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${K8S_NAMESPACE:-default}"

read -r -p "PostgreSQL username: " DB_USER
read -r -s -p "PostgreSQL password: " DB_PASSWORD
printf '\n'
read -r -p "PostgreSQL database name: " DB_NAME

if [[ -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$DB_NAME" ]]; then
  echo "Error: all three values are required." >&2
  exit 1
fi

kubectl create secret generic postgres-secret \
  --namespace "$NAMESPACE" \
  --from-env-file=<(printf \
    'POSTGRES_USER=%s\nPOSTGRES_PASSWORD=%s\nPOSTGRES_DB=%s\n' \
    "$DB_USER" "$DB_PASSWORD" "$DB_NAME") \
  --dry-run=client -o yaml |
  kubectl apply -f -

unset DB_USER DB_PASSWORD DB_NAME
echo "Secret postgres-secret applied in namespace: $NAMESPACE"
