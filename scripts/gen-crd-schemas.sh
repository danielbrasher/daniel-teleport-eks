#!/usr/bin/env bash
# Pull the Teleport operator CRDs out of the chart and convert them into JSON schemas kubeconform can use. Run by .github/workflows/validate.yaml.
set -euo pipefail

OUT=${1:-/tmp/crd-schemas}
VERSION=$(grep 'TELEPORT_VERSION:' infrastructure/base/cluster-vars.yaml | tr -d '" ' | cut -d: -f2)
RAW=/tmp/teleport-crds.yaml

mkdir -p "$OUT"
helm repo add teleport https://charts.releases.teleport.dev >/dev/null 2>&1 || true
helm repo update teleport >/dev/null

# path 1, authoritative if it exists
helm show crds teleport/teleport-cluster --version "$VERSION" > "$RAW" 2>/dev/null || true

# path 2, for charts where operator CRDs are under templates/ instead
# add additional "--set" here if chart adds another required value in a future release...revisit...
if [ ! -s "$RAW" ]; then
  echo "crds/ directory empty; rendering templates instead"
  helm template teleport teleport/teleport-cluster \
    --version "$VERSION" \
    --include-crds \
    --set clusterName=placeholder.example.com \
    --set operator.enabled=true \
    > /tmp/teleport-rendered.yaml

  # --include-crds emits Deployments, Services and hooks alongside the CRDs, so keep only the CRDs
  python3 - "$RAW" << 'PYEOF'
import sys, yaml
keep = [
    d for d in yaml.safe_load_all(open("/tmp/teleport-rendered.yaml"))
    if isinstance(d, dict) and d.get("kind") == "CustomResourceDefinition"
]
if not keep:
    sys.exit("no CustomResourceDefinition documents found in rendered chart")
with open(sys.argv[1], "w") as f:
    yaml.safe_dump_all(keep, f)
print(f"kept {len(keep)} CRDs")
PYEOF
fi

grep -c '^kind: CustomResourceDefinition' "$RAW" >/dev/null 2>&1 || true
echo "CRD source: $(grep -c 'kind: CustomResourceDefinition' "$RAW" || echo 0) definitions"

pip install --quiet --break-system-packages openapi2jsonschema pyyaml
openapi2jsonschema --kubernetes --stand-alone --expanded -o "$OUT" "$RAW"

echo "Wrote $(ls -1 "$OUT" | wc -l) schemas to $OUT"
ls -1 "$OUT" | grep -i teleport | head