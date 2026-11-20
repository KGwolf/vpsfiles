# VPS Nginx configuration (Debian 12)

This is a **configuration template**, not an automatic installer. It is designed
for the planned layout:

- `license.448910.xyz` -> `127.0.0.1:3080`
- `panel.448910.xyz` -> `127.0.0.1:2053` (3x-ui must be configured to bind localhost)
- `node.448910.xyz` -> `127.0.0.1:10000` (Xray VLESS + WebSocket)
- TLS terminates at Nginx.
- WebSocket upgrade handling is shared.

## Important safety notes

1. Do not replace `/etc/nginx/nginx.conf` or enable these files until the
   existing Nginx configuration has been backed up and the current services
   and DNS records have been checked.
2. The old Xray currently owns public TCP/443. Nginx cannot bind 443 until
   that listener is stopped/reconfigured during the planned cutover.
3. `panel.conf` assumes 3x-ui listens on `127.0.0.1:2053`. This is a planning
   value, not a claim about the installer default. Set the actual 3x-ui panel
   port to 2053 and bind it to localhost, or update `proxy_pass`.
4. Cloudflare Access must be configured separately in the Cloudflare Zero Trust
   dashboard for `panel.448910.xyz`. Nginx reverse proxying alone does NOT
   enforce Cloudflare Access. Protect the origin too: restrict public TCP/443
   to Cloudflare IP ranges (or use an authenticated origin design) so users
   cannot bypass Cloudflare by connecting directly to the VPS IP. Plan firewall
   rules carefully to avoid locking yourself out. Keep SSH access separate.
5. `node.conf` contains a placeholder WebSocket path. Replace it with the exact
   path configured in 3x-ui. Do not reuse a publicly known/simple path.
6. The certificate paths assume a Certbot certificate named
   `services-448910`. Do not enable the TLS server blocks until that certificate
   exists. The existing certificate for `448910.xyz` is not assumed to cover
   these subdomains.
7. Never commit private keys, passwords, UUIDs, API tokens, or exported panel
   databases to GitHub. Keep this repository Private, but still treat it as
   non-secret configuration storage.

## Files

- `nginx.conf`: proposed complete main configuration for Debian 12.
- `conf.d/00-websocket-map.conf`: WebSocket connection map.
- `snippets/proxy-common.conf`: common reverse-proxy headers/timeouts.
- `snippets/ssl-common.conf`: shared TLS certificate reference.
- `sites-available/*.conf`: one virtual host per service.

## Planned deployment

The intended deployment process is staged:

1. Keep the current Nginx configuration active while preparing the new files.
2. Install the shared snippets and WebSocket map.
3. Configure and test the HTTP-01 challenge before issuing the certificate.
4. Install/enable the service virtual hosts only after backend ports and paths
   have been confirmed.
5. During cutover, ensure Nginx is the only process listening on public TCP/443.
6. Run `nginx -t` before every reload. If it fails, do not reload.
7. Validate all three hostnames, Cloudflare Access, and the FClash connection.

No script in this repository automatically overwrites the active configuration.
