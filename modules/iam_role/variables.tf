# =============================================================================
# IAM ROLE MODULE VARIABLES
# =============================================================================
# This module creates an IAM role for Lambda function execution
# Dependencies: None (independent service)
# Used by: Lambda function module (requires role ARN for execution)
# Permissions: Kinesis, DynamoDB, S3, CloudWatch Logs access

variable "role_name" {
  description = "Name of the IAM role for Lambda function execution. This role provides permissions to access Kinesis streams, DynamoDB tables, S3 buckets, and CloudWatch Logs. Must be unique within the AWS account."
  type        = string
  default     = "lambda_kinesis_dynamodb_role"

  validation {
    condition = can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.role_name)) && length(var.role_name) >= 1 && length(var.role_name) <= 64
    error_message = "Role name must be 1-64 characters and contain only alphanumeric characters and +=,.@_- symbols."
  }
}

variable "path" {
  description = "Path for the IAM role. Use to organize roles hierarchically. Must begin and end with forward slash."
  type        = string
  default     = "/"

  validation {
    condition = can(regex("^/", var.path)) && can(regex("/$", var.path)) && length(var.path) <= 512
    error_message = "Path must begin and end with '/' and be no more than 512 characters long."
  }
}

variable "description" {
  description = "Description of the IAM role. Helps document the role's purpose and permissions."
  type        = string
  default     = "IAM role for Lambda function to process stock market data from Kinesis and store in DynamoDB and S3"

  validation {
    condition = length(var.description) <= 1000
    error_message = "Description must be no more than 1000 characters long."
  }
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for the role. Determines how long the role can be assumed before requiring re-authentication."
  type        = number
  default     = 3600

  validation {
    condition = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Max session duration must be between 3600 (1 hour) and 43200 (12 hours) seconds."
  }
}

variable "force_detach_policies" {
  description = "Whether to force detaching any IAM policies the role has before destroying it. Useful for cleanup but may cause issues if policies are shared."
  type        = bool
  default     = false
}

variable "permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the role. Limits the maximum permissions the role can have."
  type        = string
  default     = null

  validation {
    condition = var.permissions_boundary == null || can(regex("^arn:aws:iam::[0-9]{12}:policy/.*$", var.permissions_boundary))
    error_message = "Permissions boundary must be a valid IAM policy ARN."
  }
}

variable "assume_role_policy" {
  description = "Custom assume role policy document in JSON format. If not provided, defaults to allowing Lambda service to assume the role."
  type        = string
  default     = null

  validation {
    condition = var.assume_role_policy == null || can(jsondecode(var.assume_role_policy))
    error_message = "Assume role policy must be valid JSON."
  }
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to the role. Default includes policies for Kinesis, DynamoDB, S3, and Lambda basic execution."
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonKinesisFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess", 
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  validation {
    condition = alltrue([
      for arn in var.managed_policy_arns : can(regex("^arn:aws:iam::(aws|[0-9]{12}):policy/.*$", arn))
    ])
    error_message = "All managed policy ARNs must be valid AWS IAM policy ARNs."
  }
}

variable "inline_policies" {
  description = "Map of inline policies to attach to the role. Key is policy name, value is policy document in JSON format. Use for role-specific permissions that don't warrant a separate managed policy."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for name, policy in var.inline_policies : can(jsondecode(policy))
    ])
    error_message = "All inline policies must be valid JSON."
  }

  validation {
    condition = alltrue([
      for name, policy in var.inline_policies : can(regex("^[a-zA-Z0-9+=,.@_-]+$", name)) && length(name) >= 1 && length(name) <= 128
    ])
    error_message = "Inline policy names must be 1-128 characters and contain only alphanumeric characters and +=,.@_- symbols."
  }
}

variable "create_instance_profile" {
  description = "Whether to create an instance profile for the role. Only needed if the role will be used by EC2 instances."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the IAM role. Tags are used for resource organization, cost allocation, and access control. Consider using consistent tagging strategy across all resources."
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
    error_message = "Maximum of 50 tags allowed per IAM role."
  }
}