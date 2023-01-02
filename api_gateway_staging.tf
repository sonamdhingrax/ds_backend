# This is the staging API Gateway hosted at https://staging-api.simplifycloud.uk
resource "aws_apigatewayv2_api" "timeInformation_api_gateway_staging" {
  name          = "staging-${var.app_name}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
  }
  disable_execute_api_endpoint = true
}

# Defines the integration with the staging Alias of Lambda with the API Gateway
resource "aws_apigatewayv2_integration" "timeInformation_apigateway_lambda_staging" {
  api_id                 = aws_apigatewayv2_api.timeInformation_api_gateway_staging.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = "${aws_lambda_function.timeInformation.arn}:${aws_lambda_alias.staging.name}"
  payload_format_version = "2.0"
}

# Defines the route at which time information api works and the associated lambda function
resource "aws_apigatewayv2_route" "time_route_staging" {
  api_id    = aws_apigatewayv2_api.timeInformation_api_gateway_staging.id
  route_key = "GET /time"

  target = "integrations/${aws_apigatewayv2_integration.timeInformation_apigateway_lambda_staging.id}"
}

# Defines the stage and also the throttle limits of the stage associated with the API
resource "aws_apigatewayv2_stage" "timeInformation_staging" {
  api_id      = aws_apigatewayv2_api.timeInformation_api_gateway_staging.id
  name        = "$default"
  auto_deploy = true
  default_route_settings {
    throttling_burst_limit = 1
    throttling_rate_limit  = 1
  }
}

# Defines the permission to invoke staging alias of lambda
resource "aws_lambda_permission" "allow_api_gw_to_invoke_lambda_Staging" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.timeInformation.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.timeInformation_api_gateway_staging.execution_arn}/*/*/time"
  qualifier  = aws_lambda_alias.staging.name
}

# Associated the staging-api.simplifycloud.uk domain name with the API Gateway
# https is enabled by the certificate in AWS ACM
resource "aws_apigatewayv2_domain_name" "timeInformation_staging" {
  domain_name = "staging-api.${var.domain_name}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# Creates an Alias Record in Route53 corresponding to staging-api.simplifycloud.uk
resource "aws_route53_record" "staging_record" {
  name    = aws_apigatewayv2_domain_name.timeInformation_staging.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.domain_name.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.timeInformation_staging.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.timeInformation_staging.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Maps the stage with the domain name and API Gateway
resource "aws_apigatewayv2_api_mapping" "apigateway_domain_mapping_staging" {
  api_id      = aws_apigatewayv2_api.timeInformation_api_gateway_staging.id
  domain_name = aws_apigatewayv2_domain_name.timeInformation_staging.domain_name
  stage       = aws_apigatewayv2_stage.timeInformation_staging.id
}

# Creates output when terraform apply is run
output "endpoing_staging" {
  value = "${aws_apigatewayv2_domain_name.timeInformation_staging.domain_name}/time"
}
