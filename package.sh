#!/bin/bash

set -e

readonly CERTBOT_VERSION=1.3.0

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}"

# Replace dns_route53.py in zip
cd "certbot/aws-cn/${CERTBOT_VERSION}"
zip "../../certbot-${CERTBOT_VERSION}.zip" "certbot_dns_route53/_internal/dns_route53.py"

# Replace disco.py in zip for add dns-tencentcloud plugin
# File Changed:
#   PREFIX_FREE_DISTRIBUTIONS = [
#       "certbot",
#       "certbot-apache",
#       "certbot-dns-cloudflare",
#       ......
#       "certbot-dns-tencentcloud", # Add dns-tencentcloud to plugins list
#   ]
zip -g "../../certbot-${CERTBOT_VERSION}.zip" "certbot/_internal/plugins/disco.py"

# Add main.py to zip
cd "${SCRIPT_DIR}"
zip -g "certbot/certbot-${CERTBOT_VERSION}.zip" main.py
