# Creates the zip file when terraform apply is run. The zip file is to update the lambda function
data "archive_file" "lambda_function" {
  type             = "zip"
  source_file      = "${path.module}/lambda_function.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/lambda_code.zip"
}

# Creates the IAM execution role for AWS Lambda
resource "aws_iam_role" "timeInformation_lambda_exec_role" {
  name = "${var.app_name}_lambda_exec_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Creates the IAM policy for the Lambda
resource "aws_iam_policy" "timeInformation_lambda_policy" {
  name   = "${var.app_name}_lambda_policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${var.region}:${var.account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/${var.app_name}:*"
            ]
        }
    ]
}
EOF
}

# Association of role and policy
resource "aws_iam_role_policy_attachment" "timeInformation_role_policy_attachment" {
  role       = aws_iam_role.timeInformation_lambda_exec_role.name
  policy_arn = aws_iam_policy.timeInformation_lambda_policy.arn
}


# This creates the AWS Lambda function which serves as the target for API gateway call to /time endpoint
resource "aws_lambda_function" "timeInformation" {
  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  function_name    = var.app_name
  runtime          = "python3.9"
  architectures    = ["arm64"]
  handler          = "lambda_function.lambda_handler"
  role             = aws_iam_role.timeInformation_lambda_exec_role.arn
  memory_size      = "128"
  publish          = true
  provisioner "local-exec" {
    command = "rm ${data.archive_file.lambda_function.output_path}"
  }
}

# Creates the Alias "prod". It uses the same version of Lambda as "staging" alias when the function is created from scratch
resource "aws_lambda_alias" "prod" {
  name             = "prod"
  description      = "This is the production version of the timeInformation Lambda Function"
  function_name    = aws_lambda_function.timeInformation.function_name
  function_version = aws_lambda_function.timeInformation.version
}

# Creates the Alias "staging" for the Lambda Function
resource "aws_lambda_alias" "staging" {
  name             = "staging"
  description      = "This is the production version of the timeInformation Lambda Function"
  function_name    = aws_lambda_function.timeInformation.function_name
  function_version = aws_lambda_function.timeInformation.version
}

# Writes the version of the Lambda Function to the output when terraform apply is run
output "lambda_version" {
  value = "Lambda Version: ${aws_lambda_function.timeInformation.version}"
}
