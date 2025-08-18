output "stream_arn" {
  description = "The Amazon Resource Name (ARN) specifying the Stream"
  value       = aws_kinesis_stream.stock_stream.arn
}

output "stream_name" {
  description = "The unique Stream name"
  value       = aws_kinesis_stream.stock_stream.name
}

output "stream_endpoint" {
  description = "The endpoint for the Kinesis stream"
  value       = "https://kinesis.${data.aws_region.current.name}.amazonaws.com"
}

output "shard_count" {
  description = "The number of shards that the stream uses"
  value       = aws_kinesis_stream.stock_stream.shard_count
}

data "aws_region" "current" {}