A couple of things worth noting as you integrate these:

**lego hook invocation** — I used `--run-hook` and `--renew-hook` in `certmgr` to call `acme-auth.sh`, but lego's actual DNS-01 hook flags are `--dns.resolvers` and the hook mechanism differs from certbot's. You'll want to check the exact lego flag names against your installed version (`lego --help`). The alternative is using lego's built-in `rfc2136` DNS provider directly rather than hooks, which would simplify things — the hooks would only be needed if you want the propagation-wait logic, which lego's provider may handle itself.

**Environment variables for hooks** — `acme-auth.sh` and `acme-cleanup.sh` expect `CERTMGR_DNS_SERVER`, `CERTMGR_TSIG_KEY`, and `CERTMGR_DNS_ZONE` to be set. These need to be exported by `certmgr` before calling lego, which I didn't explicitly add — worth checking that section when you test it.

**AXFR and SOA/NS records** — the `awk` filter in `axfr_fetch` deliberately skips SOA and NS records so the reconciler doesn't try to delete them. Worth verifying the AXFR output format from your specific BIND version looks as expected before the first real run.
