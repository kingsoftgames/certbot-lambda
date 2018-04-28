#!/usr/bin/env python3

import os
import shutil
import boto3
import certbot.main

# Let’s Encrypt acme-v02 server that supports wildcard certificates
CERTBOT_SERVER = 'https://acme-v02.api.letsencrypt.org/directory'

# Temp dir of Lambda runtime
CERTBOT_DIR = '/tmp/certbot'

def call_certbot(email, domains):
    certbot_args = [
        # Override directory paths so script doesn't have to be run as root
        '--config-dir', CERTBOT_DIR,
        '--work-dir', CERTBOT_DIR,
        '--logs-dir', CERTBOT_DIR,

        'certonly',                             # Obtain a cert but don't install it
        '--non-interactive',                    # Run in non-interactive mode
        '--agree-tos',                          # Agree to the terms of service
        '--email', email,                       # Email
        '--dns-route53',                        # Use dns challenge with route53
        '--preferred-challenges', 'dns-01',
        '--server', CERTBOT_SERVER,             # Use this server instead of default acme-v01
        '--domains', domains,                   # Domains to provision certs for (comma separated)
    ]
    return certbot.main.main(certbot_args)

def publish_certs_to_s3(bucket, prefix):
    client = boto3.client('s3')

    # /tmp/certbot
    # ├── live
    # │   └── [domain]
    # │       ├── README
    # │       ├── cert.pem
    # │       ├── chain.pem
    # │       ├── fullchain.pem
    # │       └── privkey.pem
    cert_dir = os.path.join(CERTBOT_DIR, 'live')
    for dirpath, _dirnames, filenames in os.walk(cert_dir):
        for filename in filenames:
            local_path = os.path.join(dirpath, filename)
            relative_path = os.path.relpath(local_path, cert_dir)
            key = os.path.join(prefix, relative_path)
            print(f'Uploading: {local_path} => s3://{bucket}/{key}')
            client.upload_file(local_path, bucket, key)

def guarded_handler(event, context):
    # Input parameters
    email = event['email']
    domains = event['domains']
    s3_bucket = event['s3_bucket']  # The S3 bucket to publish certificates
    s3_prefix = event['s3_prefix']  # The S3 key prefix to publish certificates

    call_certbot(email, domains)
    publish_certs_to_s3(s3_bucket, s3_prefix)

    return f'Certs published successfully.'

def cleanup():
    if os.path.exists(CERTBOT_DIR):
        try:
            shutil.rmtree(CERTBOT_DIR)
        except NotADirectoryError:
            os.remove(CERTBOT_DIR)

def lambda_handler(event, context):
    try:
        cleanup()
        return guarded_handler(event, context)
    finally:
        cleanup()
