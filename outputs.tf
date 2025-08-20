# Root-level outputs exposing important resource identifiers

# Kinesis Data Stream Outputs
output "kinesis_stream_name" {
  description = "Name of the Kinesis data stream"
  value       = module.kinesis.stream_name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis data stream"
  value       = module.kinesis.stream_arn
}

output "kinesis_stream_endpoint" {
  description = "Endpoint of the Kinesis data stream"
  value       = module.kinesis.stream_endpoint
}

# DynamoDB Table Outputs
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb.table_arn
}

output "dynamodb_table_stream_arn" {
  description = "ARN of the DynamoDB table stream"
  value       = module.dynamodb.stream_arn
}

# S3 Bucket Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3_bucket.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_bucket.bucket_arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = module.s3_bucket.bucket_domain_name
}

# IAM Role Outputs
output "iam_role_name" {
  description = "Name of the IAM role"
  value       = module.iam_role.role_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = module.iam_role.role_arn
}

# Lambda Function Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_function.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_function.function_arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = module.lambda_function.invoke_arn
}

# Environment Information (hardcoded values)
output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = "us-east-1"
}

output "environment" {
  description = "Environment name"
  value       = "dev"
}

output "project_name" {
  description = "Project name"
  value       = "stock-analytics"
}

# Glue Catalog Outputs
output "glue_database_name" {
  description = "Name of the Glue Catalog database"
  value       = module.glue_catalog.database_name
}

output "glue_table_name" {
  description = "Name of the Glue Catalog table"
  value       = module.glue_catalog.table_name
}

output "athena_sample_query" {
  description = "Sample Athena query to get started"
  value       = module.glue_catalog.sample_athena_query
}