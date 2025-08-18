# =============================================================================
# KINESIS DATA STREAM MODULE VARIABLES
# =============================================================================
# This module creates a Kinesis Data Stream for real-time data ingestion
# Dependencies: None (independent service)
# Used by: Lambda function module (for event source mapping)

variable "stream_name" {
  description = "Name of the Kinesis data stream for ingesting stock market data. Must be unique within the AWS account and region. Used as event source for Lambda function."
  type        = string
  default     = "stock-market-stream"

  validation {
    condition = can(regex("^[a-zA-Z0-9_.-]+$", var.stream_name)) && length(var.stream_name) >= 1 && length(var.stream_name) <= 128
    error_message = "Stream name must be 1-128 characters and contain only letters, numbers, underscores, periods, and hyphens."
  }
}

variable "shard_count" {
  description = "Number of shards for the Kinesis stream. Each shard can handle 1MB/sec or 1000 records/sec ingress and 2MB/sec egress. Scale based on expected throughput. Consider costs when increasing shard count."
  type        = number
  default     = 1

  validation {
    condition = var.shard_count >= 1 && var.shard_count <= 10000
    error_message = "Shard count must be between 1 and 10000. Each shard costs approximately $0.015/hour plus $0.014 per million PUT payload units."
  }
}

variable "retention_period" {
  description = "Length of time data records are accessible after they are added to the stream (in hours). Longer retention periods increase storage costs but provide more time for data recovery and reprocessing."
  type        = number
  default     = 24

  validation {
    condition = var.retention_period >= 24 && var.retention_period <= 168
    error_message = "Retention period must be between 24 and 168 hours (1 to 7 days). Extended retention beyond 24 hours incurs additional charges."
  }
}

variable "encryption_type" {
  description = "Server-side encryption type for the Kinesis stream. KMS provides additional security but may increase latency and costs."
  type        = string
  default     = "KMS"

  validation {
    condition = contains(["NONE", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either 'NONE' for no encryption or 'KMS' for server-side encryption with AWS KMS."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for server-side encryption. If not specified and encryption_type is KMS, uses AWS managed key for Kinesis. Custom keys provide more control but require key management."
  type        = string
  default     = null

  validation {
    condition = var.kms_key_id == null || can(regex("^(arn:aws:kms:|alias/|[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}).*$", var.kms_key_id))
    error_message = "KMS key ID must be a valid key ID, key ARN, alias name, or alias ARN."
  }
}

variable "shard_level_metrics" {
  description = "List of shard-level CloudWatch metrics to enable. Available metrics: IncomingRecords, IncomingBytes, OutgoingRecords, OutgoingBytes, WriteProvisionedThroughputExceeded, ReadProvisionedThroughputExceeded, IteratorAgeMilliseconds, ALL. Enabling metrics incurs additional CloudWatch charges."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for metric in var.shard_level_metrics : contains([
        "IncomingRecords", "IncomingBytes", "OutgoingRecords", "OutgoingBytes",
        "WriteProvisionedThroughputExceeded", "ReadProvisionedThroughputExceeded",
        "IteratorAgeMilliseconds", "ALL"
      ], metric)
    ])
    error_message = "Shard level metrics must be valid CloudWatch metric names or 'ALL' for all metrics."
  }
}

variable "tags" {
  description = "A map of tags to assign to the Kinesis stream. Tags are used for resource organization, cost allocation, and access control."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[\\w\\s+=.:/@-]*$", k)) && can(regex("^[\\w\\s+=.:/@-]*$", v))
    ])
    error_message = "Tag keys and values must contain only alphanumeric characters, spaces, and the following characters: + = . : / @ -"
  }
}