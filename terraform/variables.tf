# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "lambda_name" {
  description = "Name of the certbot lambda function. Will also be used as prefix to create AWS resources with unique names."
  type        = string
}

variable "domains" {
  description = "A list of domains to provision certificates. Can contain wildcard domains like *.example.com"
  type        = list(string)
}

# https://letsencrypt.org/docs/expiration-emails/
variable "emails" {
  description = "A list of emails used for registration, recovery contact and expiry notification."
  type        = list(string)
}

variable "upload_s3" {
  description = "The S3 bucket to upload certificates."
  type = object({
    bucket = string,
    prefix = string,
    region = string,
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "hosted_zone_id" {
  description = "ID of the Route53 hosted zone, where domains are hosted in."
  type        = string
  default     = ""
}

variable "create_aws_route53_iam_role" {
  description = "Controls if route53 iam role for lambda should be created. If set value to false, the environment of credentials could be provided in `lambda_custom_environment`"
  type        = bool
  default     = true
}

variable "create_aws_s3_iam_role" {
  description = "Controls if route53 iam role for lambda should be created. If set value to false, the environment of credentials could be provided in `lambda_custom_environment`"
  type        = bool
  default     = true
}

# https://certbot.eff.org/docs/using.html#dns-plugins
variable "certbot_dns_plugin" {
  description = "The dns plugin for certbot."
  type        = string
  default     = "dns-route53"
}

variable "lambda_custom_environment" {
  description = "The custom environment in Lambda. (e.g.) `TENCENTCLOUD_SECRET_ID`, `TENCENTCLOUD_SECRET_KEY`"
  sensitive   = true
  type        = map(string)
  default     = {}
}

variable "lambda_description" {
  description = "Description for the lambda function."
  type        = string
  default     = ""
}

variable "lambda_runtime" {
  description = "Name of the runtime for lambda function."
  type        = string
  default     = "python3.6"
}

variable "lambda_memory_size" {
  description = "The amount of memory in MB that lambda function has access to."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "The amount of time that lambda function has to run in seconds."
  type        = number
  default     = 300
}

variable "cron_expression" {
  description = "A cron expression for CloudWatch event rule that triggers lambda. Default is 00:00:00+0800 at 1st day of every month."
  type        = string
  default     = "0 16 L * ? *"
}
