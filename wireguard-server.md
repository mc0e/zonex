# Server-side WireGuard configuration

On your DNS server, add a WireGuard interface that accepts connections from
your laptop.

First, generate the server's keypair:

```bash
wg genkey | tee /etc/wireguard/server-privatekey | wg pubkey > /etc/wireguard/server-publickey
chmod 600 /etc/wireguard/server-privatekey
```

Create `/etc/wireguard/wg-cert.conf`, pasting in the keys from the files
above. The server's address is `10.20.0.1` — the other end of the `/24` your
laptop config references. `AllowedIPs` is a `/32` since only one laptop is
peering:

```ini
[Interface]
Address = 10.20.0.1/24
PrivateKey = <contents of server-privatekey>
ListenPort = 51820

[Peer]
PublicKey = <contents of laptop publickey>
AllowedIPs = 10.20.0.2/32
```

Once the config file is saved, remove the plain-text key files:

```bash
rm /etc/wireguard/server-privatekey /etc/wireguard/server-publickey
```

Then bring up the interface and enable it on boot:

```bash
sudo wg-quick up wg-cert
sudo systemctl enable wg-quick@wg-cert
```

## Key exchange

You need to cross-populate the keys between client and server:

| Value | Where it goes |
|---|---|
| Server public key (`server-publickey`) | `[Peer] PublicKey` in your laptop's `wg-cert.conf` |
| Laptop public key (from your laptop's `publickey` file) | `[Peer] PublicKey` in the server's `wg-cert.conf` |

## BIND access

Once the tunnel is up, your laptop will appear to BIND as `10.20.0.2`. The
TSIG key is the primary authentication mechanism and WireGuard provides
network-level isolation — there is no need to also restrict by IP unless you
want defence in depth. The zone configuration described in the BIND section is
sufficient:

```
zone "x.mc0e.net" {
    allow-transfer { key zonereconcile-key; };
    update-policy {
        grant zonereconcile-key zonesub ANY;
    };
};
```

## Verify the tunnel

```bash
# On the server
sudo wg show

# From your laptop (after wg-quick up)
ping 10.20.0.1
dig @10.20.0.1 x.mc0e.net SOA
```
