# Simplified root module configuration for realtime stock analytics pipeline
# All values are hardcoded directly to eliminate variables complexity

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "stock-analytics"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

# Kinesis Data Stream Module
module "kinesis" {
  source = "./modules/kinesis"

  stream_name      = "stock-market-stream"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"

  tags = {
    Project     = "stock-analytics"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# DynamoDB Table Module
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name             = "stock-market-data"
  billing_mode           = "PAY_PER_REQUEST"
  point_in_time_recovery = true

  tags = {
    Project     = "stock-analytics"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# S3 Bucket for Raw Stock Market Data
module "s3_bucket" {
  source = "./modules/s3_bucket"

  bucket_name        = "stock-market-data-bucket-121485"
  versioning_enabled = true

  tags = {
    Project     = "stock-analytics"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# S3 Bucket Module for Athena query results
module "s3_bucket_athena_results" {
  source = "./modules/s3_bucket"

  bucket_name        = "athena-query-results-121485"
  versioning_enabled = true

  tags = {
    Project     = "stock-analytics"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# IAM Lambda Role for Kinesis and DynamoDB
module "iam_role" {
  source = "./modules/iam_role"

  role_name = "lambda_kinesis_dynamodb_role"

  tags = {
    Project     = "stock-analytics"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# IAM Role for Stock Trend Lambda (SNS, DynamoDB, and Lambda basic execution)
module "iam_role_trend" {
  source = "./modules/iam_role"

  role_name = "StockTrendLambdaRole"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSNSFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  tags = {
    Project     = "stock-analytics"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Lambda Function Module
module "lambda_function" {
  source = "./modules/lambda_function"

  function_name                      = "ConsumerStockData"
  execution_role_arn                 = module.iam_role.role_arn
  runtime                            = "python3.13"
  handler                            = "lambda_function.lambda_handler"
  timeout                            = 60
  memory_size                        = 128
  filename                           = "modules/lambda_function/lambda_consumer/lambda_function.zip"
  source_code_hash                   = filebase64sha256("modules/lambda_function/lambda_consumer/lambda_function.zip")
  kinesis_stream_arn                 = module.kinesis.stream_arn
  batch_size                         = 2
  maximum_batching_window_in_seconds = 0
  starting_position                  = "LATEST"

  environment_variables = {
    DYNAMODB_TABLE_NAME = module.dynamodb.table_name
    S3_BUCKET_NAME      = module.s3_bucket.bucket_name
  }

  tags = {
    Project     = "stock-analytics"
    Environment = "dev"
    ManagedBy   = "terraform"
  }

  depends_on = [
    module.kinesis,
    module.dynamodb,
    module.s3_bucket,
    module.iam_role
  ]
}

# Glue Catalog Module for Athena
module "glue_catalog" {
  source = "./modules/glue_catalog"

  database_name = "stock_data_db"
  table_name    = "stock_data_table"
  s3_location   = "s3://stock-market-data-bucket-121485/raw/"
  data_format   = "JSON"

  tags = {
    Project     = "stock-analytics"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# SNS Topic for stock trend alerts with email subscription
module "sns_trend_alerts" {
  source = "./modules/sns"

  topic_name              = "stock-trend-alerts"
  subscription_protocol   = "email"
  subscription_endpoint   = "villarinmon@gmail.com"

  tags = {
    Project     = "stock-analytics"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Lambda Function for Trend Analysis (triggered by DynamoDB stream)
module "lambda_trend_analysis" {
  source = "./modules/lambda_function"

  function_name      = "StockTrendAnalysis"
  execution_role_arn = module.iam_role_trend.role_arn
  runtime            = "python3.13"
  handler            = "lambda_function.lambda_handler"
  timeout            = 60
  memory_size        = 128

  filename         = "modules/lambda_function/lambda_trend/lambda_function.zip"
  source_code_hash = filebase64sha256("modules/lambda_function/lambda_trend/lambda_function.zip")

  # Use DynamoDB stream as event source
  event_source_arn  = module.dynamodb.stream_arn
  starting_position = "LATEST"
  batch_size        = 2

  environment_variables = {
    DYNAMODB_TABLE_NAME = module.dynamodb.table_name
    SNS_TOPIC_ARN       = module.sns_trend_alerts.topic_arn
  }

  tags = {
    Project     = "stock-analytics"
    Environment = "dev"
    ManagedBy   = "terraform"
  }

  depends_on = [
    module.dynamodb,
    module.iam_role_trend,
    module.sns_trend_alerts
  ]
}
