#!/usr/bin/env bash
set -euo pipefail

: "${RC_DEMOS_ROOT:?set RC_DEMOS_ROOT to the pinned rc-demos checkout}"

demo="$RC_DEMOS_ROOT/dev-container-profile"
app="$demo/reference/application.profile.yaml"
wrapper="$demo/examples/dev-container.conditions.yaml"
recipe="$demo/examples/dev-container.compose.yaml"

for path in "$app" "$wrapper" "$recipe"; do
  test -f "$path"
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

before=$(sha256sum "$app" | awk '{print $1}')

(
  cd "$demo"
  go run ./cmd/profile-compose     -application-profile "$app"     -wrapper-additions "$wrapper"     -recipe "$recipe"     -out "$tmp/dev-container.profile.yaml"     -provenance-out "$tmp/dev-container.provenance.yaml"
)

after=$(sha256sum "$app" | awk '{print $1}')
if [[ "$before" != "$after" ]]; then
  echo "application Profile bytes changed during composition" >&2
  exit 1
fi

python3 - "$app" "$tmp/dev-container.profile.yaml" "$tmp/dev-container.provenance.yaml" <<'PY'
import sys
import yaml

app_path, composed_path, provenance_path = sys.argv[1:]
with open(app_path, encoding="utf-8") as f:
    app = yaml.safe_load(f)
with open(composed_path, encoding="utf-8") as f:
    composed = yaml.safe_load(f)
with open(provenance_path, encoding="utf-8") as f:
    provenance = yaml.safe_load(f)

def names(profile):
    return [c["name"] for c in profile.get("conditions", [])]

app_names = names(app)
composed_names = names(composed)

assert app["workload"]["uri"].endswith("/dev-container-profile/app"), app["workload"]
assert "content-api" in app_names
assert "site-analytics" in app_names
assert "application-source" not in app_names

assert composed["workload"]["uri"].endswith("/dev-container-profile#dev-container"), composed["workload"]
assert "content-api" in composed_names
assert "site-analytics" in composed_names
assert "application-source" in composed_names
assert any("source-control" in ext for ext in composed.get("extensions", [])), composed.get("extensions")

sources = {s["id"]: s for s in provenance.get("sources", [])}
assert set(sources["application-profile"]["conditions"]) == {"content-api", "site-analytics"}
assert sources["wrapper-additions"]["conditions"] == ["application-source"]

print("application_conditions=" + ",".join(app_names))
print("composed_conditions=" + ",".join(composed_names))
print("application_workload=" + app["workload"]["uri"])
print("composed_workload=" + composed["workload"]["uri"])
print("composition_provenance=pass")
PY

echo "application_profile_sha256=$before"
echo "experiment_003_composition=pass"
