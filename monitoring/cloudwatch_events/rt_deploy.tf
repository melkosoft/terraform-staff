data "archive_file" "rt_lambda_zip" {
  type = "zip"
  output_path = "${path.module}/files/rt_notify.zip"
  source_file = "${path.module}/src/rt_notify.py"
}

resource "aws_lambda_function" "rt_notify" {
    function_name = "${var.rt_notify_func_name}"
    role = "${aws_iam_role.iam_for_lambda.arn}"
    handler = "rt_notify.lambda_handler"
    runtime = "python2.7"
    timeout = "5"
    filename = "${path.module}/files/rt_notify.zip"
    source_code_hash = "${data.archive_file.rt_lambda_zip.output_base64sha256}"
    depends_on = [aws_cloudwatch_log_group.rt_notify]
    environment {
      variables = "${var.rt_notify_lambda_env}"
    }
}

resource "aws_cloudwatch_log_group" "rt_notify" {
  name              = "/aws/lambda/${var.rt_notify_func_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "rt_notify" {
  name = "rt_watcher"
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
      "CreateRoute",
      "CreateRouteTable",
      "ReplaceRoute",
      "ReplaceRouteTableAssociation",
      "DeleteRouteTable",
      "DeleteRoute",
      "DisassociateRouteTable"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "rt_notify" {
  rule = "${aws_cloudwatch_event_rule.rt_notify.name}"
  target_id = "Lambda"
  arn = "${aws_lambda_function.rt_notify.arn}"
  
}

resource "aws_lambda_permission" "rt_notify" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.rt_notify.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.rt_notify.arn}"
}

resource "aws_iam_policy" "rt_notify_policy" {
  name = "rt_notify_policy"
  description = "Policy for Lambda function rt_notify"
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
                "ec2:DescribeVpcs"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "rt_notify-attach" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.rt_notify_policy.arn}"
}

