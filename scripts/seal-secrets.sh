#!/usr/bin/env bash
# Seal Red Hat credentials with Ansible Vault.
#
# Usage:
#   1. cp ~/Downloads/pull-secret secrets/pull-secret.plain.json
#   2. cp secrets/vault.yml.example secrets/vault.plain.yml
#      # edit secrets/vault.plain.yml — set rh_offline_token
#   3. ./scripts/seal-secrets.sh
#
# Run playbooks (vault password read from .vault_pass automatically):
#   ansible-playbook playbooks/create-cluster-and-iso.yml
#
# Or prompt for vault password:
#   ansible-playbook playbooks/create-cluster-and-iso.yml --ask-vault-pass

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VAULT_PASS_FILE="${VAULT_PASS_FILE:-$ROOT/.vault_pass}"
PLAIN_PULL="$ROOT/secrets/pull-secret.plain.json"
VAULT_PULL="$ROOT/secrets/pull-secret.json"
PLAIN_VAULT="$ROOT/secrets/vault.plain.yml"
VAULT_VARS="$ROOT/secrets/vault.yml"

if [[ ! -f "$VAULT_PASS_FILE" ]]; then
  echo "Creating vault password file: $VAULT_PASS_FILE"
  openssl rand -base64 32 >"$VAULT_PASS_FILE"
  chmod 600 "$VAULT_PASS_FILE"
  echo "Store this password safely. AAP: use a Machine credential or custom vault password."
fi

if [[ ! -f "$PLAIN_PULL" ]]; then
  echo "ERROR: Missing $PLAIN_PULL"
  echo "Download from https://console.redhat.com/openshift/install/pull-secret (Download button)"
  echo "  cp ~/Downloads/pull-secret secrets/pull-secret.plain.json"
  exit 1
fi

if [[ ! -f "$PLAIN_VAULT" ]]; then
  echo "ERROR: Missing $PLAIN_VAULT"
  echo "  cp secrets/vault.yml.example secrets/vault.plain.yml"
  echo "  # edit rh_offline_token, then re-run this script"
  exit 1
fi

if grep -q 'PASTE_OFFLINE_TOKEN_HERE' "$PLAIN_VAULT"; then
  echo "ERROR: Set rh_offline_token in $PLAIN_VAULT before sealing"
  exit 1
fi

if grep -q 'rh_ssh_public_key: "ssh-rsa AAAA\.\.\.' "$PLAIN_VAULT"; then
  echo "ERROR: Set rh_ssh_public_key in $PLAIN_VAULT before sealing"
  exit 1
fi

echo "Sealing pull secret -> $VAULT_PULL"
cp "$PLAIN_PULL" "$VAULT_PULL"
if head -1 "$VAULT_PULL" | grep -q '$ANSIBLE_VAULT'; then
  echo "  pull-secret.json already encrypted; re-encrypting"
  ansible-vault decrypt --vault-password-file "$VAULT_PASS_FILE" --vault-id default "$VAULT_PULL"
fi
ansible-vault encrypt --vault-password-file "$VAULT_PASS_FILE" --encrypt-vault-id default "$VAULT_PULL"

echo "Sealing vault vars -> $VAULT_VARS"
cp "$PLAIN_VAULT" "$VAULT_VARS"
if head -1 "$VAULT_VARS" | grep -q '$ANSIBLE_VAULT'; then
  ansible-vault decrypt --vault-password-file "$VAULT_PASS_FILE" --vault-id default "$VAULT_VARS"
fi
ansible-vault encrypt --vault-password-file "$VAULT_PASS_FILE" --encrypt-vault-id default "$VAULT_VARS"

echo ""
echo "Done. Encrypted files:"
echo "  secrets/pull-secret.json"
echo "  secrets/vault.yml"
echo ""
echo "Plaintext sources remain gitignored:"
echo "  secrets/pull-secret.plain.json"
echo "  secrets/vault.plain.yml"
echo ""
echo "Run: ansible-playbook playbooks/create-cluster-and-iso.yml"
