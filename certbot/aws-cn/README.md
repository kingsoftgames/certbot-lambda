# aws-cn

This folder contains modified code for certbot to work in AWS China Regions.

Override them in `certbot-<version>.zip`

```bash
VERSION=1.3.0
cd "${VERSION}"
zip "../../certbot-${VERSION}.zip" "certbot_dns_route53/_internal/dns_route53.py"
```
