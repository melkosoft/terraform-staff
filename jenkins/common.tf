provider "aws" {
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
  region     = var.AWS_DEFAULT_REGION
}

data "aws_caller_identity" "current" {
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role" "s3_signed_url" {
  name               = "s3_signed_url"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}
## Lambda Function Resources
##
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/files/${var.lambda_func_name}.zip"
  source_file = "${path.module}/src/${var.lambda_func_name}.py"
}

resource "aws_lambda_function" "s3_signed_url" {
  function_name    = var.lambda_func_name
  role             = aws_iam_role.s3_signed_url.arn
  handler          = "${var.lambda_func_name}.lambda_handler"
  runtime          = "python2.7"
  timeout          = "7"
  filename         = "${path.module}/files/${var.lambda_func_name}.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  depends_on = [aws_cloudwatch_log_group.s3_signed_url]
}

resource "aws_cloudwatch_log_group" "s3_signed_url" {
  name              = "/aws/lambda/${var.lambda_func_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "s3_signed_url" {
  name        = "s3_signed_url"
  description = "Policy for Lambda function S3 Signed URL"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        },
        {
            "Action": [
                "s3:*"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::softwareupdater*/*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_signed_url" {
  role       = aws_iam_role.s3_signed_url.name
  policy_arn = aws_iam_policy.s3_signed_url.arn
}


