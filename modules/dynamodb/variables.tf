# =============================================================================
# DYNAMODB TABLE MODULE VARIABLES
# =============================================================================
# This module creates a DynamoDB table for storing processed stock market data
# Dependencies: None (independent service)
# Used by: Lambda function (writes processed data to this table)
# Schema: Partition key "symbol" (String), Sort key "timestamp" (String)

variable "table_name" {
  description = "Name of the DynamoDB table for storing processed stock market data. Must be unique within the AWS account and region. Used by Lambda function for data storage."
  type        = string

  validation {
    condition = can(regex("^[a-zA-Z0-9_.-]+$", var.table_name)) && length(var.table_name) >= 3 && length(var.table_name) <= 255
    error_message = "Table name must be 3-255 characters and contain only letters, numbers, underscores, periods, and hyphens."
  }
}

variable "billing_mode" {
  description = "Controls how you are charged for read and write throughput. PAY_PER_REQUEST is suitable for unpredictable workloads, PROVISIONED for predictable traffic patterns with potential cost savings."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Billing mode must be either 'PAY_PER_REQUEST' for on-demand pricing or 'PROVISIONED' for reserved capacity pricing."
  }
}

variable "read_capacity" {
  description = "Number of read capacity units for this table. Only used when billing_mode is PROVISIONED. Each unit provides 4KB/sec of strongly consistent reads or 8KB/sec of eventually consistent reads. Consider your read patterns and peak traffic."
  type        = number
  default     = 5

  validation {
    condition = var.read_capacity >= 1 && var.read_capacity <= 40000
    error_message = "Read capacity must be between 1 and 40000 units. Each unit costs approximately $0.00013 per hour."
  }
}

variable "write_capacity" {
  description = "Number of write capacity units for this table. Only used when billing_mode is PROVISIONED. Each unit provides 1KB/sec of write throughput. Consider your write patterns and peak traffic from Lambda function."
  type        = number
  default     = 5

  validation {
    condition = var.write_capacity >= 1 && var.write_capacity <= 40000
    error_message = "Write capacity must be between 1 and 40000 units. Each unit costs approximately $0.00065 per hour."
  }
}

variable "point_in_time_recovery" {
  description = "Enable point-in-time recovery for the table. Provides continuous backups for the last 35 days. Recommended for production environments but incurs additional storage costs."
  type        = bool
  default     = true
}

variable "encryption_enabled" {
  description = "Enable server-side encryption for the table. Recommended for sensitive data. Uses AWS managed keys by default or customer managed keys if kms_key_id is specified."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for server-side encryption. If not specified and encryption is enabled, uses AWS managed DynamoDB key. Custom keys provide more control but require key management and incur additional costs."
  type        = string
  default     = null

  validation {
    condition = var.kms_key_id == null || can(regex("^(arn:aws:kms:|alias/|[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}).*$", var.kms_key_id))
    error_message = "KMS key ID must be a valid key ID, key ARN, alias name, or alias ARN."
  }
}

variable "stream_enabled" {
  description = "Enable DynamoDB Streams to capture data modification events. Useful for triggering downstream processing or maintaining audit trails. Incurs additional costs based on stream reads."
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "When an item in the table is modified, StreamViewType determines what information is written to the stream. Only used when stream_enabled is true. KEYS_ONLY captures only key attributes, NEW_IMAGE captures entire item after modification, OLD_IMAGE captures entire item before modification, NEW_AND_OLD_IMAGES captures both."
  type        = string
  default     = "NEW_AND_OLD_IMAGES"

  validation {
    condition = contains([
      "KEYS_ONLY",
      "NEW_IMAGE", 
      "OLD_IMAGE",
      "NEW_AND_OLD_IMAGES"
    ], var.stream_view_type)
    error_message = "Stream view type must be one of: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection for the table. Prevents accidental table deletion. Recommended for production environments."
  type        = bool
  default     = false
}

variable "table_class" {
  description = "Storage class of the table. STANDARD for frequently accessed data, STANDARD_INFREQUENT_ACCESS for infrequently accessed data with lower storage costs but higher access costs."
  type        = string
  default     = "STANDARD"

  validation {
    condition = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.table_class)
    error_message = "Table class must be either 'STANDARD' or 'STANDARD_INFREQUENT_ACCESS'."
  }
}

variable "global_secondary_indexes" {
  description = "List of global secondary indexes for the table. Each GSI allows querying on different attributes but incurs additional costs for storage and throughput."
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = string
    non_key_attributes = optional(list(string))
    read_capacity   = optional(number)
    write_capacity  = optional(number)
  }))
  default = []

  validation {
    condition = alltrue([
      for gsi in var.global_secondary_indexes : contains(["ALL", "KEYS_ONLY", "INCLUDE"], gsi.projection_type)
    ])
    error_message = "GSI projection type must be one of: ALL, KEYS_ONLY, INCLUDE."
  }
}

variable "local_secondary_indexes" {
  description = "List of local secondary indexes for the table. LSIs share throughput with the main table and must be created at table creation time."
  type = list(object({
    name            = string
    range_key       = string
    projection_type = string
    non_key_attributes = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for lsi in var.local_secondary_indexes : contains(["ALL", "KEYS_ONLY", "INCLUDE"], lsi.projection_type)
    ])
    error_message = "LSI projection type must be one of: ALL, KEYS_ONLY, INCLUDE."
  }
}

variable "ttl_enabled" {
  description = "Enable Time to Live (TTL) for automatic item expiration. Useful for automatically removing old stock data to control storage costs."
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "Name of the table attribute to use for TTL. The attribute must contain a Unix timestamp. Only used when ttl_enabled is true."
  type        = string
  default     = "expires_at"

  validation {
    condition = can(regex("^[a-zA-Z0-9_.-]+$", var.ttl_attribute_name))
    error_message = "TTL attribute name must contain only letters, numbers, underscores, periods, and hyphens."
  }
}

variable "tags" {
  description = "A map of tags to assign to the DynamoDB table. Tags are used for resource organization, cost allocation, and access control."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[\\w\\s+=.:/@-]*$", k)) && can(regex("^[\\w\\s+=.:/@-]*$", v))
    ])
    error_message = "Tag keys and values must contain only alphanumeric characters, spaces, and the following characters: + = . : / @ -"
  }
}