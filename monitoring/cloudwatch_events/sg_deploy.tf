data "archive_file" "lambda_zip" {
  type = "zip"
  output_path = "${path.module}/files/sg_notify.zip"
  source_file = "${path.module}/src/sg_notify.py"
}
resource "aws_lambda_function" "sg_notify" {
    function_name = "${var.sg_notify_func_name}"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    handler = "sg_notify.lambda_handler"
    runtime = "python2.7"
    timeout = "7"
    filename = "${path.module}/files/sg_notify.zip"
    source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
    depends_on = [aws_cloudwatch_log_group.sg_notify]
    environment {
      variables = "${var.sg_notify_lambda_env}"
    }
}
resource "aws_cloudwatch_log_group" "sg_notify" {
  name              = "/aws/lambda/${var.sg_notify_func_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "sg_notify" {
  name = "sg_watcher"
  description = "Watch for API calls"
  event_pattern = <<PATTERN
{
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "ec2.amazonaws.com"
    ],
    "eventName": [
      "AuthorizeSecurityGroupIngress",
      "RevokeSecurityGroupIngress"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "sg_notify" {
  rule = "${aws_cloudwatch_event_rule.sg_notify.name}"
  target_id = "Lambda"
  arn = "${aws_lambda_function.sg_notify.arn}"
  
}

resource "aws_lambda_permission" "sg_notify" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.sg_notify.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.sg_notify.arn}"
}
resource "aws_iam_policy" "sg_notify_policy" {
  name = "sg_notify_policy"
  description = "Policy for Lambda function sg_notify"
  policy = <<EOF
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
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail"
            ],
            "Resource": [
                "arn:aws:ses:${var.AWS_DEFAULT_REGION}:${local.account_id}:identity/*"
            ]
        },
        {
            "Action": [
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:DescribeStaleSecurityGroups",
                "ec2:DescribeVpcs"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sg_notify-attach" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.sg_notify_policy.arn}"
}

