Bootstrap note:
The final site files already answer HTTP-01 challenges under
/.well-known/acme-challenge/ and redirect all other HTTP requests to HTTPS.

Before enabling the final site files:
1. Create /var/www/letsencrypt.
2. Ensure inbound TCP/80 reaches this VPS (Cloudflare orange-cloud proxy is OK).
3. Enable the site files and use Certbot webroot authentication to issue a
   certificate named services-448910 for:
   license.448910.xyz, panel.448910.xyz, node.448910.xyz
4. The certificate path must then be:
   /etc/letsencrypt/live/services-448910/fullchain.pem
   /etc/letsencrypt/live/services-448910/privkey.pem

Do not issue/replace the certificate until DNS records for all three hostnames
point to this VPS and the HTTP challenge path is reachable.
