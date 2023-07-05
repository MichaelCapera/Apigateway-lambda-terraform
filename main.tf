provider "aws" {
  region = "us-east-1"  # Cambia esto a la región deseada
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "lambda_payload.zip"  # Reemplaza esto con la ruta a tu código Lambda
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "example_lambda" {
  function_name    = "example-lambda"
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role = "<IAM-role-ARN>"  # TODO

  environment {
    variables = {
      EXAMPLE_VAR = "example-value"
    }
  }
}

resource "aws_api_gateway_rest_api" "example_api" {
  name        = "example-api"
  description = "API Gateway Example"
  body        = file("oas.json")
}

resource "aws_api_gateway_integration" "example_integration" {
  rest_api_id             = aws_api_gateway_rest_api.example_api.id
  resource_id             = aws_api_gateway_rest_api.example_api.root_resource_id
  http_method             = "GET"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.example_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "example_deployment" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  stage_name  = "prod"
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.example_deployment.invoke_url
}
