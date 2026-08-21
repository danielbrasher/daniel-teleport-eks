#!/usr/bin/env bash
# Pull the Teleport operator CRDs out of the chart and convert them into JSON
# schemas kubeconform can use. Run by .github/workflows/validate.yaml.
set -euo pipefail

OUT=${1:-/tmp/crd-schemas}
VERSION=$(grep 'TELEPORT_VERSION:' infrastructure/base/cluster-vars.yaml | tr -d '" ' | cut -d: -f2)

mkdir -p "$OUT"
helm repo add teleport https://charts.releases.teleport.dev >/dev/null 2>&1 || true
helm repo update teleport >/dev/null

helm template teleport teleport/teleport-cluster \
  --version "$VERSION" \
  --set operator.enabled=true \
  --include-crds \
  --show-only crds \
  > /tmp/teleport-crds.yaml 2>/dev/null \
  || helm template teleport teleport/teleport-cluster \
       --version "$VERSION" --set operator.enabled=true --include-crds \
       > /tmp/teleport-crds.yaml

pip install --quiet --break-system-packages openapi2jsonschema
openapi2jsonschema --kubernetes --stand-alone --expanded -o "$OUT" /tmp/teleport-crds.yaml

echo "Wrote $(ls -1 "$OUT" | wc -l) schemas to $OUT"
