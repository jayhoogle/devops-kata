terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.62.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "random_pet" "bucket_name" {
  prefix = "jcalmus-interview"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.bucket_name.id
  acl    = "private"
}

resource "aws_s3_bucket_object" "lambda_object" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "lambda.zip"
  source = data.archive_file.lambda_zip.output_path
}

resource "aws_dynamodb_table" "interview_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "COUNTER"

  attribute {
    name = "COUNTER"
    type = "S"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

resource "aws_iam_role_policy" "iam_role_for_lambda" {
  role = aws_iam_role.iam_for_lambda.id
  name = "iam_role_for_lambda"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
      Sid      = ""
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "interview_lambda" {
  function_name = "getCountOfSold"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "handler.getCountOfSold"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = "lambda.zip"

  runtime = "nodejs12.x"

  environment {
    variables = {
      DYNAMODB_TABLE = var.table_name
    }
  }
}

resource "aws_lambda_function" "update_vehicle_sales_lambda" {
  function_name = "updateVehicleSales"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "handler.updateVehicleSales"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = "lambda.zip"

  runtime = "nodejs12.x"

  environment {
    variables = {
      DYNAMODB_TABLE = var.table_name
    }
  }
}

