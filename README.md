# backbone

Bunkbed uses an on-premises server instead of cloud for our various projects in order to keep costs low and to use as many open source tools as possible. This server runs nixOS and hosts our source code, CI/CD, website, etc.

## Tools

- nixOS
- Forgejo
- k3s
- Traeffik Proxy
- And more...

## Commands

```bash
kubectl annotate ingress web-ingress cert-manager.io/issuer=letsencrypt-production --overwrite
```
