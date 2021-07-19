terraform {
  # The configuration for this backend will be filled in by terragrunt
  backend "s3" {}
  required_version = ">= 0.15"
  required_providers {
    aws = ">= 3.48.0"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Data SOURCES
# ---------------------------------------------------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_arn" "current" {
  arn = data.aws_caller_identity.current.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLE AND POLICY
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "route53" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = ["arn:${local.aws_partition}:route53:::hostedzone/${var.hosted_zone_id}"]
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:${local.aws_partition}:s3:::${var.upload_s3.bucket}"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:${local.aws_partition}:s3:::${var.upload_s3.bucket}/${var.upload_s3.prefix}*"]
  }
}

# Allow certbot to use dns challenges with route53
resource "aws_iam_role_policy" "route53" {
  count  = var.create_aws_route53_iam_role ? 1 : 0
  name   = "certbot-dns-route53"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.route53.json
}

# Allow uploading generated certs to S3
resource "aws_iam_role_policy" "s3" {
  count  = var.create_aws_s3_iam_role ? 1 : 0
  name   = "certbot-upload-s3"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.s3.json
}

# AWS managed policy, which provides write permissions to CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.id
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    # Note: both Global/China regions use "lambda.amazonaws.com" as service ID.
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name_prefix        = local.name_prefix
  assume_role_policy = data.aws_iam_policy_document.lambda_role.json

  # aws_iam_instance_profile.instance_profile in this module sets create_before_destroy to true, which means
  # everything it depends on, including this resource, must set it as well, or you'll get cyclic dependency errors
  # when you try to do a terraform destroy.
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LAMBDA
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_function" "certbot" {
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda.arn
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  handler          = local.lambda_handler
  filename         = local.lambda_filename
  source_code_hash = local.lambda_hash
  description      = local.lambda_description

  environment {
    variables = local.aws_partition == "aws-cn" ? local.lambda_environment_cn : local.lambda_environment
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH EVENTS RULE THAT TRIGGERS ON A SCHEDULE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "schedule" {
  name_prefix         = local.name_prefix
  description         = "Triggers lambda function ${aws_lambda_function.certbot.function_name} on a regular schedule."
  schedule_expression = "cron(${var.cron_expression})"
}

resource "aws_cloudwatch_event_target" "schedule" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = aws_lambda_function.certbot.arn
  # Since certbot lambda function gets all input from environment variables,
  # an empty JSON object is good enough.
  input = "{}"
}

resource "aws_lambda_permission" "schedule" {
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.certbot.function_name
  # Note: both Global/China regions use "events.amazonaws.com" as service ID of CloudWatch Events.
  principal = "events.amazonaws.com"
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

# Put locals to the end due to fmt issue with heredocs: https://github.com/hashicorp/terraform/issues/21434
locals {
  name_prefix = "${var.lambda_name}-"

  aws_region     = data.aws_region.current.name
  aws_partition  = data.aws_arn.current.partition
  aws_account_id = data.aws_caller_identity.current.account_id

  certbot_version = "1.3.0"

  certbot_emails  = join(",", var.emails)
  certbot_domains = join(",", var.domains)

  lambda_handler  = "main.lambda_handler"
  lambda_filename = "${path.module}/../certbot/certbot-${local.certbot_version}.zip"
  lambda_hash     = filebase64sha256(local.lambda_filename)

  lambda_description = var.lambda_description != "" ? var.lambda_description : "Run certbot for ${local.certbot_domains}"

  lambda_environment = merge({
    EMAILS     = local.certbot_emails
    DOMAINS    = local.certbot_domains
    DNS_PLUGIN = var.certbot_dns_plugin
    S3_BUCKET  = var.upload_s3.bucket
    S3_PREFIX  = var.upload_s3.prefix
    S3_REGION  = var.upload_s3.region
  }, var.lambda_custom_environment)

  # See dns_route53.py
  lambda_environment_cn = merge(local.lambda_environment, {
    AWS_ROUTE53_REGION   = "cn-northwest-1"
    AWS_ROUTE53_ENDPOINT = "https://route53.amazonaws.com.cn"
  })
}
