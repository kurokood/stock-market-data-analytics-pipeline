# =============================================================================
# S3 BUCKET MODULE VARIABLES
# =============================================================================
# This module creates an S3 bucket for archiving stock market data
# Dependencies: None (independent service)
# Used by: Lambda function (writes archived data to this bucket)
# Purpose: Long-term storage, backup, and data lake functionality

variable "bucket_name" {
  description = "Name of the S3 bucket for archiving stock market data. Must be globally unique across all AWS accounts. Used by Lambda function for data archival and backup."
  type        = string

  validation {
    condition = can(regex("^[a-z0-9.-]+$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && !can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.bucket_name)) && !can(regex("^.*\\.$", var.bucket_name)) && !can(regex("^\\..*$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters, lowercase letters/numbers/periods/hyphens only, not formatted as IP address, and cannot start or end with a period."
  }
}

variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket. Recommended for data protection and compliance. Allows recovery of overwritten or deleted objects but increases storage costs."
  type        = bool
  default     = true
}

variable "mfa_delete" {
  description = "Enable MFA delete for the S3 bucket. Requires multi-factor authentication to delete object versions. Can only be enabled by the bucket owner using the root account."
  type        = bool
  default     = false
}

variable "encryption_algorithm" {
  description = "Server-side encryption algorithm to use. AES256 uses Amazon S3 managed keys (SSE-S3), aws:kms uses AWS KMS managed keys (SSE-KMS) with additional features but higher costs."
  type        = string
  default     = "AES256"

  validation {
    condition = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Encryption algorithm must be either 'AES256' for SSE-S3 or 'aws:kms' for SSE-KMS."
  }
}

variable "kms_key_id" {
  description = "KMS key ID to use for encryption. Only required when encryption_algorithm is aws:kms. If not specified, uses AWS managed S3 key. Custom keys provide more control but require key management."
  type        = string
  default     = null

  validation {
    condition = var.kms_key_id == null || can(regex("^(arn:aws:kms:|alias/|[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}).*$", var.kms_key_id))
    error_message = "KMS key ID must be a valid key ID, key ARN, alias name, or alias ARN."
  }
}

variable "bucket_key_enabled" {
  description = "Enable S3 bucket key for KMS encryption. Reduces KMS API calls and costs when using SSE-KMS. Only applies when encryption_algorithm is aws:kms."
  type        = bool
  default     = true
}

# Public Access Block settings - all default to true for security
variable "block_public_acls" {
  description = "Block public ACLs on the bucket and objects. Recommended security practice to prevent accidental public access."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies. Recommended security practice to prevent accidental public access through bucket policies."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs on the bucket and objects. Recommended security practice to treat public ACLs as private."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies. Recommended security practice to prevent public access even with public policies."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for cost optimization. Configure transitions to cheaper storage classes and expiration policies. Each rule can target specific prefixes or the entire bucket."
  type = list(object({
    id     = string
    status = string
    filter = optional(object({
      prefix = optional(string)
      tags   = optional(map(string))
    }))
    expiration = optional(object({
      days                         = optional(number)
      date                        = optional(string)
      expired_object_delete_marker = optional(bool)
    }))
    noncurrent_version_expiration = optional(object({
      noncurrent_days = number
    }))
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })))
    noncurrent_version_transitions = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })))
    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules : contains(["Enabled", "Disabled"], rule.status)
    ])
    error_message = "Lifecycle rule status must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules : rule.transitions == null ? true : alltrue([
        for transition in rule.transitions : contains([
          "STANDARD_IA", "ONEZONE_IA", "REDUCED_REDUNDANCY", "GLACIER", 
          "DEEP_ARCHIVE", "INTELLIGENT_TIERING", "GLACIER_IR"
        ], transition.storage_class)
      ])
    ])
    error_message = "Storage class must be one of: STANDARD_IA, ONEZONE_IA, REDUCED_REDUNDANCY, GLACIER, DEEP_ARCHIVE, INTELLIGENT_TIERING, GLACIER_IR."
  }
}

variable "bucket_policy" {
  description = "JSON policy document for the bucket. Use to grant specific permissions to AWS services or users. Ensure it doesn't conflict with public access block settings."
  type        = string
  default     = null

  validation {
    condition = var.bucket_policy == null || can(jsondecode(var.bucket_policy))
    error_message = "Bucket policy must be valid JSON."
  }
}

variable "cors_rules" {
  description = "List of CORS rules for the bucket. Required if bucket will be accessed from web applications. Each rule defines allowed origins, methods, and headers."
  type = list(object({
    allowed_headers = optional(list(string))
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.cors_rules : alltrue([
        for method in rule.allowed_methods : contains([
          "GET", "PUT", "POST", "DELETE", "HEAD"
        ], method)
      ])
    ])
    error_message = "CORS allowed methods must be one of: GET, PUT, POST, DELETE, HEAD."
  }
}

variable "notification_configurations" {
  description = "List of notification configurations for the bucket. Configure to trigger Lambda functions, SQS queues, or SNS topics on object events."
  type = list(object({
    id     = string
    events = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
    lambda_function_arn = optional(string)
    queue_arn          = optional(string)
    topic_arn          = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for config in var.notification_configurations : alltrue([
        for event in config.events : can(regex("^s3:", event))
      ])
    ])
    error_message = "Notification events must be valid S3 event types (e.g., s3:ObjectCreated:*, s3:ObjectRemoved:*)."
  }
}

variable "replication_configuration" {
  description = "Cross-region replication configuration for disaster recovery and compliance. Requires versioning to be enabled and appropriate IAM role."
  type = object({
    role_arn = string
    rules = list(object({
      id       = string
      status   = string
      priority = optional(number)
      filter = optional(object({
        prefix = optional(string)
        tags   = optional(map(string))
      }))
      destination = object({
        bucket             = string
        storage_class      = optional(string)
        replica_kms_key_id = optional(string)
        access_control_translation = optional(object({
          owner = string
        }))
        account_id = optional(string)
      })
      delete_marker_replication = optional(object({
        status = string
      }))
    }))
  })
  default = null

  validation {
    condition = var.replication_configuration == null || alltrue([
      for rule in var.replication_configuration.rules : contains(["Enabled", "Disabled"], rule.status)
    ])
    error_message = "Replication rule status must be either 'Enabled' or 'Disabled'."
  }
}

variable "logging_configuration" {
  description = "Access logging configuration for the bucket. Logs all requests made to the bucket for security auditing and analysis."
  type = object({
    target_bucket = string
    target_prefix = optional(string)
  })
  default = null
}

variable "website_configuration" {
  description = "Static website hosting configuration. Only use if bucket will serve static web content."
  type = object({
    index_document = string
    error_document = optional(string)
    redirect_all_requests_to = optional(object({
      host_name = string
      protocol  = optional(string)
    }))
    routing_rules = optional(list(object({
      condition = optional(object({
        http_error_code_returned_equals = optional(string)
        key_prefix_equals              = optional(string)
      }))
      redirect = object({
        host_name               = optional(string)
        http_redirect_code      = optional(string)
        protocol                = optional(string)
        replace_key_prefix_with = optional(string)
        replace_key_with        = optional(string)
      })
    })))
  })
  default = null
}

variable "object_lock_configuration" {
  description = "Object lock configuration for compliance and data retention. Prevents objects from being deleted or overwritten for a specified period."
  type = object({
    object_lock_enabled = string
    rule = optional(object({
      default_retention = object({
        mode  = string
        days  = optional(number)
        years = optional(number)
      })
    }))
  })
  default = null

  validation {
    condition = var.object_lock_configuration == null || contains(["Enabled"], var.object_lock_configuration.object_lock_enabled)
    error_message = "Object lock enabled must be 'Enabled' if specified."
  }

  validation {
    condition = var.object_lock_configuration == null || var.object_lock_configuration.rule == null || contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock_configuration.rule.default_retention.mode)
    error_message = "Object lock retention mode must be either 'GOVERNANCE' or 'COMPLIANCE'."
  }
}

variable "tags" {
  description = "A map of tags to assign to the S3 bucket. Tags are used for resource organization, cost allocation, and access control. Consider using consistent tagging strategy across all resources."
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
    error_message = "Maximum of 50 tags allowed per S3 bucket."
  }
}