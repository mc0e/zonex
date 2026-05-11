#!/usr/bin/env bash
# acme-auth.sh - lego DNS-01 authentication hook
#
# Called by lego during certificate issuance/renewal to add the ACME
# challenge TXT record to DNS. Not intended to be run directly.
#
# Environment variables set by lego:
#   LEGO_DOMAIN          - the domain being validated
#   LEGO_VALIDATION      - the validation token value (for DNS-01, the TXT value)
#   LEGO_TOKEN           - the token
#   LEGO_CERT_PATH       - path to the certificate (on renewal)
#   LEGO_CERT_KEY_PATH   - path to the certificate key (on renewal)
#
# Required environment variables (set by certmgr):
#   CERTMGR_DNS_SERVER   - nameserver address (host or host:port)
#   CERTMGR_TSIG_KEY     - path to TSIG key file
#   CERTMGR_DNS_ZONE     - DNS zone (e.g. x.mc0e.net)
#
set -euo pipefail

log() { echo "[acme-auth] $*" >&2; }
err() { echo "[acme-auth] ERROR: $*" >&2; exit 1; }

: "${LEGO_DOMAIN:?LEGO_DOMAIN not set}"
: "${LEGO_VALIDATION:?LEGO_VALIDATION not set}"
: "${CERTMGR_DNS_SERVER:?CERTMGR_DNS_SERVER not set}"
: "${CERTMGR_TSIG_KEY:?CERTMGR_TSIG_KEY not set}"
: "${CERTMGR_DNS_ZONE:?CERTMGR_DNS_ZONE not set}"

RECORD="_acme-challenge.${LEGO_DOMAIN}."
VALUE="${LEGO_VALIDATION}"

log "Adding TXT record $RECORD"

nsupdate -k "$CERTMGR_TSIG_KEY" <<EOF
server ${CERTMGR_DNS_SERVER}
zone ${CERTMGR_DNS_ZONE}
update delete ${RECORD} TXT
update add ${RECORD} 60 TXT "${VALUE}"
send
EOF

# --- wait for propagation ---
log "Waiting for DNS propagation..."

for i in {1..30}; do
    if dig +short TXT "${RECORD}" @"${CERTMGR_DNS_SERVER}" \
            | grep -q "${VALUE}"; then
        log "DNS record is visible after $((i * 2)) seconds"
        exit 0
    fi
    sleep 2
done

err "DNS record not visible after 60 seconds"
