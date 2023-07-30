# backbone

backbone is the infrastructure behind our projects

We choose to host the entirety of our company's efforts on an on-premises server instead of cloud not because it is easy, but because it is hard.

## Details

This project helps us keep as many tools totally supported by free and open source software as possible.

### Tools Used

- nixOS
- Forgejo
- k3s
- Traeffik Proxy
- And more...

## Helpful Commands

```bash
kubectl annotate ingress web-ingress cert-manager.io/issuer=letsencrypt-production --overwrite
```
