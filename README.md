# certbot-lambda

Running Certbot on AWS Lambda.

Inspired by [Deploying EFF's Certbot in AWS Lambda](https://arkadiyt.com/2018/01/26/deploying-effs-certbot-in-aws-lambda/).

## Features

- Supports wildcard certificates (Let's Encrypt ACME v2).
- Uploads certificates to specified Amazon S3 bucket.
- Works with CloudWatch Scheduled Events for certificate renewal.

## Sample Event

```json
{
    "domains": "*.foobar.com,foobar.com",
    "email": "[EMAIL]",
    "s3_bucket": "[BUCKET]",
    "s3_prefix": "[KEY_PREFIX]"
}
```
