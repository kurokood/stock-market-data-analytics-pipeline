output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.stock_market_data.arn
}

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.stock_market_data.name
}

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.stock_market_data.id
}

output "stream_arn" {
  description = "ARN of the DynamoDB table stream"
  value       = aws_dynamodb_table.stock_market_data.stream_arn
}

output "stream_label" {
  description = "Timestamp of when the stream was enabled"
  value       = aws_dynamodb_table.stock_market_data.stream_label
}