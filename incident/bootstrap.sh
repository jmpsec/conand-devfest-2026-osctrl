#!/bin/bash
# Idempotent: creates the workshop environment and admin user on first run.
set -euo pipefail

CLI="/opt/osctrl/bin/osctrl-cli --db"

until $CLI check-db >/dev/null 2>&1; do echo "Waiting for DB"; sleep 2; done

if ! $CLI env show --name "$ENV_NAME" >/dev/null 2>&1; then
  $CLI env add --name "$ENV_NAME" --hostname osctrl-nginx --certificate /tls/osctrl.crt
  # Short intervals so demos answer in seconds, not minutes. Lab only.
  $CLI env update --name "$ENV_NAME" --logging 10 --config 30 --query 10
fi

if ! $CLI user show --username "$OSCTRL_USER" >/dev/null 2>&1; then
  $CLI user add --admin --username "$OSCTRL_USER" --password "$OSCTRL_PASS" \
    --environment "$ENV_NAME" --fullname "$OSCTRL_USER"
fi

echo "Environment '$ENV_NAME' and user '$OSCTRL_USER' are ready."
