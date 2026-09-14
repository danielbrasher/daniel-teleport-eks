#!/usr/bin/env bash
# Pull the Teleport operator CRDs out of the chart and convert them into JSON schemas kubeconform can use (run by .github/workflows/validate.yaml)
set -euo pipefail

OUT=${1:-/tmp/crd-schemas}
VERSION=$(grep 'TELEPORT_VERSION:' infrastructure/base/cluster-vars.yaml | tr -d '" ' | cut -d: -f2)

KUBECONFORM_VERSION=v0.8.0
CONVERTER=/tmp/crd-openapi2jsonschema.py
curl -sSL -o "$CONVERTER" \
  "https://raw.githubusercontent.com/yannh/kubeconform/${KUBECONFORM_VERSION}/scripts/openapi2jsonschema.py"

mkdir -p "$OUT"
helm repo add teleport https://charts.releases.teleport.dev >/dev/null 2>&1 || true
helm repo update teleport >/dev/null

# add additional "--set" here if chart adds another required value in a future release...revisit...
helm template teleport teleport/teleport-cluster \
  --version "$VERSION" \
  --set operator.enabled=true \
  --set clusterName=placeholder.example.com \
  --include-crds \
  --show-only crds \
  > /tmp/teleport-crds.yaml 2>/dev/null \
  || helm template teleport teleport/teleport-cluster \
       --version "$VERSION" --set operator.enabled=true --include-crds \
       --set clusterName=placeholder.example.com \
       > /tmp/teleport-crds.yaml

( cd "$OUT" && FILENAME_FORMAT='{kind}_{version}' python3 "$CONVERTER" /tmp/teleport-crds.yaml )

echo "Wrote $(ls -1 "$OUT" | wc -l) schemas to $OUT"
