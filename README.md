# certbot-lambda

Running Certbot on AWS Lambda.

Inspired by [Deploying EFF's Certbot in AWS Lambda](https://arkadiyt.com/2018/01/26/deploying-effs-certbot-in-aws-lambda/).

## Features

- Supports wildcard certificates (Let's Encrypt ACME v2).
- Uploads certificates to specified Amazon S3 bucket.
- Works with CloudWatch Scheduled Events for certificate renewal.
- Use Terraform to deploy to AWS (See [terraform folder](terraform)).

## How to update certbot version

1. Recreate requirements.txt with only certbot and any certbot plugins
2. Run ./package.sh 
```bash
certbot-lambda $ ./package.sh
```
3. Source virtualenv created by the above script
```bash
certbot-lambda $ source certbot/venv/bin/activate
```
4. Create new requirements file
```bash
certbox-lambda $ pip freeze > requirements.txt
```

