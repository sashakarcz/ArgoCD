#!/usr/bin/env bash
# Resolve the current registry digest of the aur-builder image and rewrite every
# reference (build manifests, pac default, docs) to that digest. Run this AFTER
# `docker build && docker push` of the builder image, so the signer/build pods
# always run an immutable, just-pushed image instead of a floating :latest that
# push access to Harbor could swap.
#
#   ./pin-image.sh            # pin to current registry digest
#   ./pin-image.sh <digest>   # pin to an explicit sha256:... digest
set -euo pipefail

REG=registry.starnix.net
REPO=library/aur-builder
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"

digest="${1:-}"
if [[ -z "$digest" ]]; then
  auth=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.docker/config.json')))['auths']['$REG']['auth'])")
  chal=$(curl -sS -m 8 -D - "https://$REG/v2/" -o /dev/null | tr -d '\r' | grep -i '^www-authenticate:')
  realm=$(sed -n 's/.*realm="\([^"]*\)".*/\1/p' <<<"$chal")
  service=$(sed -n 's/.*service="\([^"]*\)".*/\1/p' <<<"$chal")
  token=$(curl -sS -m 8 -H "Authorization: Basic $auth" \
    "$realm?service=$service&scope=repository:$REPO:pull" \
    | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('token') or d.get('access_token'))")
  digest=$(curl -sS -m 8 -D - -o /dev/null -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.oci.image.index.v1+json" \
    -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    "https://$REG/v2/$REPO/manifests/latest" \
    | tr -d '\r' | sed -n 's/^[Dd]ocker-[Cc]ontent-[Dd]igest: //p')
fi
[[ "$digest" == sha256:* ]] || { echo "could not resolve a sha256 digest" >&2; exit 1; }

echo "Pinning aur-builder -> $REG/$REPO@$digest"

# A :tag, an existing @sha256:... pin, or the REPLACE_WITH_DIGEST placeholder.
pat="$REG/$REPO\(:latest\|@sha256:[A-Za-z0-9_]*\)"
new="$REG/$REPO@$digest"

# Only rewrite real image references, never prose: the k8s `image:` field in the
# manifests and the builder-image const in pac. Leaves `docker build/push
# ...:latest` instructions and docs untouched.
for f in "$HERE/builder.yaml" "$HERE/builder-hook.yaml"; do
  [[ -f "$f" ]] && sed -i "/^[[:space:]]*image:/ s#$pat#$new#g" "$f" && echo "  updated $f"
done
cfg="$REPO_ROOT/../pac/internal/config/config.go"
[[ -f "$cfg" ]] && sed -i "/aur-builder/ s#$pat#$new#g" "$cfg" && echo "  updated $cfg"
echo "Done. Review the diff and commit. (Update SCANNING.md's example digest by hand if you cite it.)"
