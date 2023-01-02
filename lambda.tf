data "archive_file" "lambda_function" {
  type             = "zip"
  source_file      = "${path.module}/lambda_function.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/lambda_code.zip"
}

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

# Create the IAM policy for the Lambda
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


resource "aws_iam_role_policy_attachment" "timeInformation_role_policy_attachment" {
  role       = aws_iam_role.timeInformation_lambda_exec_role.name
  policy_arn = aws_iam_policy.timeInformation_lambda_policy.arn
}


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

resource "aws_lambda_alias" "prod" {
  name             = "prod"
  description      = "This is the production version of the timeInformation Lambda Function"
  function_name    = aws_lambda_function.timeInformation.function_name
  function_version = aws_lambda_function.timeInformation.version
}

resource "aws_lambda_alias" "staging" {
  name             = "staging"
  description      = "This is the production version of the timeInformation Lambda Function"
  function_name    = aws_lambda_function.timeInformation.function_name
  function_version = aws_lambda_function.timeInformation.version
}

output "lambda_version" {
  value = "Lambda Version: ${aws_lambda_function.timeInformation.version}"
}
