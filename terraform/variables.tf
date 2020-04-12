# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "lambda_name" {
  description = "Name of the certbot lambda function. Will also be used as prefix to create AWS resources with unique names."
  type        = string
}

variable "hosted_zone_id" {
  description = "ID of the Route53 hosted zone, where domains are hosted in."
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
