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

# S3 Bucket Module
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

# IAM Role Module
module "iam_role" {
  source = "./modules/iam_role"

  role_name = "lambda_kinesis_dynamodb_role"
  
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
  filename                           = "lambda_function.zip"
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