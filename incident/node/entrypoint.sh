#!/bin/bash
set -euo pipefail

CLI="/opt/osctrl/bin/osctrl-cli --db"
FLAGS=/etc/osquery/osquery.flags

if [ ! -f "$FLAGS" ]; then
  $CLI env node-actions --name "$ENV_NAME" secret > /etc/osquery/osquery.secret
  $CLI env node-actions --name "$ENV_NAME" show-flags > "$FLAGS"
  # Containers share the kernel UUID: identify each node by its hostname.
  sed -i -e "s#__SECRET_FILE__#/etc/osquery/osquery.secret#" -e "s#__CERT_FILE__#/tls/osctrl.crt#" \
    -e "/--host_identifier=/d" "$FLAGS"
  printf '%s\n' --host_identifier=specified "--specified_identifier=$(hostname)" >> "$FLAGS"
fi

# The "incident": a renamed copy of the harmless sleep binary running from /tmp.
# Launched from a bash parent so the process tree looks like a user ran it.
if [ -n "${PLANT:-}" ]; then
  cp /bin/sleep "$PLANT"
  setsid bash -c "$PLANT infinity; :" </dev/null >/dev/null 2>&1 &
fi

exec /opt/osquery/bin/osqueryd --flagfile="$FLAGS"
