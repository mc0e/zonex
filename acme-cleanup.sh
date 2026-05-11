#!/usr/bin/env bash
# acme-cleanup.sh - lego DNS-01 cleanup hook
#
# Called by lego after certificate issuance/renewal to remove the ACME
# challenge TXT record from DNS. Not intended to be run directly.
#
# Environment variables set by lego:
#   LEGO_DOMAIN          - the domain being validated
#   LEGO_VALIDATION      - the validation token value
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

log() { echo "[acme-cleanup] $*" >&2; }
err() { echo "[acme-cleanup] ERROR: $*" >&2; exit 1; }

: "${LEGO_DOMAIN:?LEGO_DOMAIN not set}"
: "${CERTMGR_DNS_SERVER:?CERTMGR_DNS_SERVER not set}"
: "${CERTMGR_TSIG_KEY:?CERTMGR_TSIG_KEY not set}"
: "${CERTMGR_DNS_ZONE:?CERTMGR_DNS_ZONE not set}"

RECORD="_acme-challenge.${LEGO_DOMAIN}."

log "Removing TXT record $RECORD"

nsupdate -k "$CERTMGR_TSIG_KEY" <<EOF
server ${CERTMGR_DNS_SERVER}
zone ${CERTMGR_DNS_ZONE}
update delete ${RECORD} TXT
send
EOF

log "Done"

