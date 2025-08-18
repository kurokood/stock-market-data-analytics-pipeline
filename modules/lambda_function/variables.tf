# =============================================================================
# LAMBDA FUNCTION MODULE VARIABLES
# =============================================================================
# This module creates a Lambda function for processing Kinesis stream data
# Dependencies: IAM role ARN (from iam_role module), Kinesis stream ARN (from kinesis module)
# Used by: Processes stock market data and writes to DynamoDB and S3
# Event Source: Kinesis Data Stream with configurable batch processing

variable "function_name" {
  description = "Name of the Lambda function that processes stock market data from Kinesis stream. Must be unique within the AWS account and region."
  type        = string
  default     = "ConsumerStockData"

  validation {
    condition = can(regex("^[a-zA-Z0-9-_]+$", var.function_name)) && length(var.function_name) >= 1 && length(var.function_name) <= 64
    error_message = "Function name must be 1-64 characters and contain only letters, numbers, hyphens, and underscores."
  }
}

variable "execution_role_arn" {
  description = "ARN of the IAM role for Lambda execution. This role must have permissions to access Kinesis, DynamoDB, S3, and CloudWatch Logs. Provided by the iam_role module."
  type        = string

  validation {
    condition = can(regex("^arn:aws:iam::[0-9]{12}:role/.*$", var.execution_role_arn))
    error_message = "Execution role ARN must be a valid IAM role ARN."
  }
}

variable "handler" {
  description = "Lambda function handler in format 'filename.function_name'. Must match the actual handler in your deployment package."
  type        = string
  default     = "lambda_function.lambda_handler"

  validation {
    condition = can(regex("^[a-zA-Z0-9_.-]+\\.[a-zA-Z0-9_]+$", var.handler))
    error_message = "Handler must be in format 'filename.function_name' (e.g., 'lambda_function.lambda_handler')."
  }
}

variable "runtime" {
  description = "Lambda function runtime environment. Must be a supported AWS Lambda runtime version. Python 3.13 is recommended for latest features and security updates."
  type        = string
  default     = "python3.13"

  validation {
    condition = contains([
      "python3.8", "python3.9", "python3.10", "python3.11", "python3.12", "python3.13",
      "nodejs18.x", "nodejs20.x", "java8", "java11", "java17", "java21",
      "dotnet6", "dotnet8", "go1.x", "ruby3.2", "ruby3.3", "provided.al2", "provided.al2023"
    ], var.runtime)
    error_message = "Runtime must be a supported AWS Lambda runtime version."
  }
}

variable "timeout" {
  description = "Lambda function timeout in seconds. Consider the time needed to process batch_size records. Longer timeouts allow processing larger batches but may increase costs."
  type        = number
  default     = 60

  validation {
    condition = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds (15 minutes maximum)."
  }
}

variable "memory_size" {
  description = "Lambda function memory size in MB. More memory provides more CPU power and may reduce execution time. Memory allocation affects pricing directly."
  type        = number
  default     = 128

  validation {
    condition = var.memory_size >= 128 && var.memory_size <= 10240 && var.memory_size % 64 == 0
    error_message = "Memory size must be between 128 and 10240 MB in 64 MB increments."
  }
}

variable "architecture" {
  description = "Instruction set architecture for the Lambda function. arm64 (Graviton2) offers better price-performance than x86_64 for most workloads."
  type        = string
  default     = "x86_64"

  validation {
    condition = contains(["x86_64", "arm64"], var.architecture)
    error_message = "Architecture must be either 'x86_64' or 'arm64'."
  }
}

variable "filename" {
  description = "Path to the Lambda deployment package (ZIP file). Must contain the function code and dependencies."
  type        = string
  default     = "lambda_function.zip"

  validation {
    condition = can(regex("\\.(zip|jar)$", var.filename))
    error_message = "Filename must end with .zip or .jar extension."
  }
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the deployment package. Used to detect changes and trigger updates. If not provided, Terraform will compute it automatically."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the Lambda function. Helps document the function's purpose and behavior."
  type        = string
  default     = "Processes stock market data from Kinesis stream and stores in DynamoDB and S3"

  validation {
    condition = length(var.description) <= 256
    error_message = "Description must be no more than 256 characters long."
  }
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function. Use to pass configuration like DynamoDB table name, S3 bucket name, and other runtime settings."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.environment_variables : can(regex("^[a-zA-Z_][a-zA-Z0-9_]*$", k))
    ])
    error_message = "Environment variable names must start with a letter or underscore and contain only letters, numbers, and underscores."
  }
}

variable "reserved_concurrent_executions" {
  description = "Number of concurrent executions to reserve for this function. Use to guarantee capacity or limit concurrency. -1 means unreserved."
  type        = number
  default     = -1

  validation {
    condition = var.reserved_concurrent_executions == -1 || (var.reserved_concurrent_executions >= 0 && var.reserved_concurrent_executions <= 1000)
    error_message = "Reserved concurrent executions must be -1 (unreserved) or between 0 and 1000."
  }
}

variable "provisioned_concurrency_config" {
  description = "Provisioned concurrency configuration to reduce cold starts. Incurs additional costs but improves performance for latency-sensitive applications."
  type = object({
    provisioned_concurrent_executions = number
  })
  default = null

  validation {
    condition = var.provisioned_concurrency_config == null || (var.provisioned_concurrency_config.provisioned_concurrent_executions >= 1 && var.provisioned_concurrency_config.provisioned_concurrent_executions <= 1000)
    error_message = "Provisioned concurrent executions must be between 1 and 1000."
  }
}

# Kinesis Event Source Mapping Configuration
variable "kinesis_stream_arn" {
  description = "ARN of the Kinesis stream to use as event source. Provided by the kinesis module. Lambda will poll this stream for new records."
  type        = string
  default     = null

  validation {
    condition = var.kinesis_stream_arn == null || can(regex("^arn:aws:kinesis:[a-z0-9-]+:[0-9]{12}:stream/.*$", var.kinesis_stream_arn))
    error_message = "Kinesis stream ARN must be a valid Kinesis stream ARN."
  }
}

variable "starting_position" {
  description = "Position in the stream where Lambda starts reading. LATEST starts from newest records, TRIM_HORIZON starts from oldest available records."
  type        = string
  default     = "LATEST"

  validation {
    condition = contains(["TRIM_HORIZON", "LATEST"], var.starting_position)
    error_message = "Starting position must be either 'TRIM_HORIZON' or 'LATEST'."
  }
}

variable "batch_size" {
  description = "Maximum number of records in each batch that Lambda pulls from the stream. Larger batches improve throughput but increase memory usage and processing time."
  type        = number
  default     = 2

  validation {
    condition = var.batch_size >= 1 && var.batch_size <= 10000
    error_message = "Batch size must be between 1 and 10000. Consider memory limits and timeout when setting this value."
  }
}

variable "maximum_batching_window_in_seconds" {
  description = "Maximum amount of time to gather records before invoking the function. Higher values reduce invocations but increase latency. 0 means no batching window."
  type        = number
  default     = 0

  validation {
    condition = var.maximum_batching_window_in_seconds >= 0 && var.maximum_batching_window_in_seconds <= 300
    error_message = "Maximum batching window must be between 0 and 300 seconds (5 minutes)."
  }
}

variable "parallelization_factor" {
  description = "Number of batches to process from each shard concurrently. Higher values increase throughput but may cause ordering issues and increase costs."
  type        = number
  default     = 1

  validation {
    condition = var.parallelization_factor >= 1 && var.parallelization_factor <= 10
    error_message = "Parallelization factor must be between 1 and 10."
  }
}

# Error Handling and Retry Configuration
variable "maximum_retry_attempts" {
  description = "Maximum number of retry attempts for failed records. Higher values improve reliability but may increase processing time for poison records."
  type        = number
  default     = 3

  validation {
    condition = var.maximum_retry_attempts >= 0 && var.maximum_retry_attempts <= 10000
    error_message = "Maximum retry attempts must be between 0 and 10000."
  }
}

variable "maximum_record_age_in_seconds" {
  description = "Maximum age of a record that Lambda sends to the function. Older records are discarded. Helps prevent processing very stale data."
  type        = number
  default     = 604800 # 7 days

  validation {
    condition = var.maximum_record_age_in_seconds >= 60 && var.maximum_record_age_in_seconds <= 604800
    error_message = "Maximum record age must be between 60 seconds (1 minute) and 604800 seconds (7 days)."
  }
}

variable "bisect_batch_on_function_error" {
  description = "If the function returns an error, split the batch in two and retry. Helps isolate poison records but may increase processing time."
  type        = bool
  default     = true
}

variable "tumbling_window_in_seconds" {
  description = "Duration of the tumbling window for processing records. Use for time-based aggregations. 0 disables tumbling windows."
  type        = number
  default     = 0

  validation {
    condition = var.tumbling_window_in_seconds >= 0 && var.tumbling_window_in_seconds <= 900
    error_message = "Tumbling window must be between 0 and 900 seconds (15 minutes)."
  }
}

# Dead Letter Queue Configuration
variable "dead_letter_queue_arn" {
  description = "ARN of the SQS queue to use as dead letter queue for failed records. Helps capture and analyze processing failures."
  type        = string
  default     = null

  validation {
    condition = var.dead_letter_queue_arn == null || can(regex("^arn:aws:sqs:[a-z0-9-]+:[0-9]{12}:.*$", var.dead_letter_queue_arn))
    error_message = "Dead letter queue ARN must be a valid SQS queue ARN."
  }
}

# VPC Configuration (optional)
variable "vpc_config" {
  description = "VPC configuration for the Lambda function. Only needed if function needs to access resources in a VPC. Increases cold start time."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null

  validation {
    condition = var.vpc_config == null || (length(var.vpc_config.subnet_ids) > 0 && length(var.vpc_config.security_group_ids) > 0)
    error_message = "VPC config must include at least one subnet ID and one security group ID."
  }
}

# File System Configuration (optional)
variable "file_system_config" {
  description = "EFS file system configuration for the Lambda function. Use to access shared file systems across multiple function instances."
  type = object({
    arn              = string
    local_mount_path = string
  })
  default = null

  validation {
    condition = var.file_system_config == null || can(regex("^arn:aws:elasticfilesystem:[a-z0-9-]+:[0-9]{12}:access-point/.*$", var.file_system_config.arn))
    error_message = "File system ARN must be a valid EFS access point ARN."
  }

  validation {
    condition = var.file_system_config == null || can(regex("^/mnt/.*$", var.file_system_config.local_mount_path))
    error_message = "Local mount path must start with /mnt/."
  }
}

# Tracing Configuration
variable "tracing_config" {
  description = "AWS X-Ray tracing configuration. Helps with debugging and performance analysis but incurs additional costs."
  type = object({
    mode = string
  })
  default = {
    mode = "PassThrough"
  }

  validation {
    condition = contains(["Active", "PassThrough"], var.tracing_config.mode)
    error_message = "Tracing mode must be either 'Active' or 'PassThrough'."
  }
}

variable "tags" {
  description = "A map of tags to assign to the Lambda function. Tags are used for resource organization, cost allocation, and access control."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[\\w\\s+=.:/@-]*$", k)) && can(regex("^[\\w\\s+=.:/@-]*$", v))
    ])
    error_message = "Tag keys and values must contain only alphanumeric characters, spaces, and the following characters: + = . : / @ -"
  }

  validation {
    condition = length(var.tags) <= 50
    error_message = "Maximum of 50 tags allowed per Lambda function."
  }
}