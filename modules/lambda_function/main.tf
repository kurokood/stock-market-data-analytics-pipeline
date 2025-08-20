resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.execution_role_arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename         = var.filename
  source_code_hash = var.source_code_hash

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "kinesis" {
  event_source_arn                   = coalesce(var.event_source_arn, var.kinesis_stream_arn)
  function_name                      = aws_lambda_function.this.arn
  starting_position                  = var.starting_position
  batch_size                         = var.batch_size
  maximum_batching_window_in_seconds = var.maximum_batching_window_in_seconds

  # Error handling and retry configuration
  maximum_retry_attempts         = var.maximum_retry_attempts
  maximum_record_age_in_seconds  = var.maximum_record_age_in_seconds
  bisect_batch_on_function_error = var.bisect_batch_on_function_error
  parallelization_factor         = var.parallelization_factor

  # Dead letter queue configuration
  dynamic "destination_config" {
    for_each = var.dead_letter_queue_arn != null ? [1] : []
    content {
      on_failure {
        destination_arn = var.dead_letter_queue_arn
      }
    }
  }

  depends_on = [aws_lambda_function.this]
}