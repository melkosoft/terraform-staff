## API Gateway Resources
##
resource "aws_api_gateway_rest_api" "s3_api" {
  name        = "s3_api"
  description = "Manage files in S3 buckets without aws key pairs"
}

resource "aws_api_gateway_resource" "s3_api" {
  rest_api_id = "${aws_api_gateway_rest_api.s3_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.s3_api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "s3_api" {
  rest_api_id   = "${aws_api_gateway_rest_api.s3_api.id}"
  resource_id   = "${aws_api_gateway_resource.s3_api.id}"
  http_method   = "ANY"
  authorization = "NONE"
   request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "s3_api" {
  rest_api_id          = "${aws_api_gateway_rest_api.s3_api.id}"
  resource_id          = "${aws_api_gateway_resource.s3_api.id}"
  http_method          = "${aws_api_gateway_method.s3_api.http_method}"
  type                 = "AWS_PROXY"
  uri                  = aws_lambda_function.s3_signed_url.invoke_arn
  integration_http_method = "ANY"

  #cache_key_parameters = ["method.request.path.proxy"]

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "s3_api" {
  depends_on = [
    "aws_api_gateway_integration.s3_api"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.s3_api.id}"
  stage_name  = "mike-test"
}

resource "aws_lambda_permission" "s3_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_signed_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.AWS_DEFAULT_REGION}:${local.account_id}:${aws_api_gateway_rest_api.s3_api.id}/*/*/*"
}


resource "aws_api_gateway_method_response" "s3_api_200" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.s3_api.id
  http_method = aws_api_gateway_method.s3_api.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "s3_api" {
  rest_api_id = aws_api_gateway_rest_api.s3_api.id
  resource_id = aws_api_gateway_resource.s3_api.id
  http_method = aws_api_gateway_method.s3_api.http_method
  status_code = aws_api_gateway_method_response.s3_api_200.status_code
}

