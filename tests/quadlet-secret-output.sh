#!/usr/bin/env bash
# Run only against prepared disposable lifecycle hosts; pass their inventory.
set -euo pipefail
umask 077
output=$(mktemp)
trap 'rm -f "$output"' EXIT
if ! ANSIBLE_NOCOLOR=1 ANSIBLE_STDOUT_CALLBACK=default ansible-playbook "$(dirname "$0")/quadlet-secret-output.yml" -vvv --diff "$@" >"$output" 2>&1; then
  echo "Secret-output runtime fixture failed; captured output withheld." >&2
  exit 1
fi
if grep -Eq 'OUTPUT_REGRESSION_(CURRENT_4927|LEGACY_8361)' "$output"; then
  echo "Secret-output regression: synthetic value appeared in captured output." >&2
  exit 1
fi
if ! grep -Eq '^[[:space:]]*"msg": "PODMAN_OUTPUT_REGRESSION_COMPLETE_49278361"' "$output"; then
  echo "Secret-output regression did not complete on a target host." >&2
  exit 1
fi
echo "Verbose repeat and legacy migration output contains no synthetic secrets."
