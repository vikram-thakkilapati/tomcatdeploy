#!/usr/bin/env bash
# Installs the Wiz Kubernetes Integration (connector, sensor, admission controller)
# into the current kubectl context.
# Required env: WIZ_CLIENT_ID, WIZ_CLIENT_SECRET, WIZ_SENSOR_PULL_USER, WIZ_SENSOR_PULL_PASSWORD
set -euo pipefail

NS=wiz
: "${WIZ_CLIENT_ID:?}" "${WIZ_CLIENT_SECRET:?}" "${WIZ_SENSOR_PULL_USER:?}" "${WIZ_SENSOR_PULL_PASSWORD:?}"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NS" create secret generic wiz-api-token \
  --from-literal=clientId="$WIZ_CLIENT_ID" \
  --from-literal=clientToken="$WIZ_CLIENT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NS" create secret docker-registry wiz-sensor-pull \
  --docker-server=wizio.azurecr.io \
  --docker-username="$WIZ_SENSOR_PULL_USER" \
  --docker-password="$WIZ_SENSOR_PULL_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

helm repo add wiz-sec https://wiz-sec.github.io/charts
helm repo update wiz-sec
helm upgrade --install wiz-integration wiz-sec/wiz-kubernetes-integration \
  --namespace "$NS" \
  --values "$(dirname "$0")/values.yaml" \
  --wait
