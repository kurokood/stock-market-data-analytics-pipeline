output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_version" {
  description = "Version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = aws_lambda_function.this.qualified_arn
}

output "event_source_mapping_uuid" {
  description = "UUID of the Kinesis event source mapping"
  value       = aws_lambda_event_source_mapping.kinesis.uuid
}

output "event_source_mapping_state" {
  description = "State of the Kinesis event source mapping"
  value       = aws_lambda_event_source_mapping.kinesis.state
}

output "event_source_mapping_last_modified" {
  description = "Last modified date of the Kinesis event source mapping"
  value       = aws_lambda_event_source_mapping.kinesis.last_modified
}