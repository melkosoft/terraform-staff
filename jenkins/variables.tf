variable "AWS_ACCESS_KEY_ID" {
}

variable "AWS_SECRET_ACCESS_KEY" {
}

variable "AWS_DEFAULT_REGION" {
}

variable "lambda_func_name" {
  default = "s3_signed_url"
}

variable "s3_bucket_arn" {
  default = "arn:aws:s3:::softwareupdater*/*"
}
