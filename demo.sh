#!/usr/bin/env bash
# Walks one Terraform state through a series of refactors, asserting what each plan says.
# Everything happens in ./work (gitignored) with hashicorp/local files, so no cloud is needed.
# Usage: ./demo.sh        (needs terraform >= 1.7 on PATH)
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
work="$root/work"
tf() { terraform -chdir="$work" "$@"; }

pass=0
fail=0

expect() { # expect <description> <regex> <text>
  if grep -Eq "$2" <<<"$3"; then
    echo "  PASS  $1"
    pass=$((pass + 1))
  else
    echo "  FAIL  $1 (wanted /$2/)"
    echo "$3" | sed 's/^/        | /'
    fail=$((fail + 1))
  fi
}

load_stage() { # replace the config in ./work, keep state and .terraform
  find "$work" -mindepth 1 -maxdepth 1 ! -name '.terraform' ! -name '.terraform.lock.hcl' ! -name 'terraform.tfstate*' ! -name 'out' -exec rm -rf {} +
  cp -R "$root/stages/$1/." "$work/"
}

plan() { tf plan -no-color -input=false 2>&1 || true; }

rm -rf "$work"
mkdir -p "$work"

echo "== 01 initial: three resources"
load_stage 01-initial
tf init -input=false -no-color >/dev/null
out="$(tf apply -auto-approve -no-color -input=false 2>&1)"
expect "3 resources created" "Resources: 3 added" "$out"

echo "== 02a rename WITHOUT a moved block (the mistake)"
load_stage 02a-rename-naive
out="$(plan)"
expect "plan wants to destroy and recreate" "Plan: 1 to add, 0 to change, 1 to destroy" "$out"

echo "== 02b same rename WITH a moved block"
load_stage 02b-rename-moved
out="$(plan)"
expect "plan reports the move" "local_file.config has moved to local_file.app_config" "$out"
expect "nothing destroyed or created" "Plan: 0 to add, 0 to change, 0 to destroy" "$out"
tf apply -auto-approve -no-color -input=false >/dev/null
expect "state holds the new address" "local_file.app_config" "$(tf state list)"

echo "== 03 move the resource into a module"
load_stage 03-into-module
tf init -input=false -no-color >/dev/null
out="$(plan)"
expect "plan reports the move into the module" "has moved to module.app.local_file.config" "$out"
expect "nothing destroyed or created" "Plan: 0 to add, 0 to change, 0 to destroy" "$out"
tf apply -auto-approve -no-color -input=false >/dev/null
expect "state holds the module address" "module.app.local_file.config" "$(tf state list)"

echo "== 04 lose a resource from state, then import it back"
registry_id="$(tf state show -no-color terraform_data.registry | sed -n 's/^ *id *= *"\(.*\)"$/\1/p')"
[ -n "$registry_id" ] || { echo "could not read registry id"; exit 1; }
tf state rm terraform_data.registry >/dev/null
load_stage 04-import
sed -i "s/REGISTRY_ID/$registry_id/" "$work/main.tf"
tf init -input=false -no-color >/dev/null
out="$(plan)"
expect "plan wants to import, not create" "1 to import" "$out"
expect "no resource is created from scratch" "0 to add" "$out"
tf apply -auto-approve -no-color -input=false >/dev/null
expect "resource is back in state" "terraform_data.registry" "$(tf state list)"
expect "imported id equals the original id" "\"$registry_id\"" "$(tf state show -no-color terraform_data.registry)"

echo "== 05 forget a resource without destroying it"
load_stage 05-removed
tf init -input=false -no-color >/dev/null
out="$(plan)"
expect "plan says it will stop managing, not destroy" "will no longer be managed by Terraform, but will not be destroyed" "$out"
tf apply -auto-approve -no-color -input=false >/dev/null
if [ -f "$work/out/legacy.txt" ]; then
  echo "  PASS  legacy.txt is still on disk"
  pass=$((pass + 1))
else
  echo "  FAIL  legacy.txt was deleted"
  fail=$((fail + 1))
fi
if tf state list | grep -q 'local_file.legacy'; then
  echo "  FAIL  legacy still in state"
  fail=$((fail + 1))
else
  echo "  PASS  legacy no longer in state"
  pass=$((pass + 1))
fi

echo
echo "checks passed: $pass, failed: $fail"
[ "$fail" -eq 0 ]
