variable "topic_name" {
  description = "Name of the SNS topic"
  type        = string
}

variable "display_name" {
  description = "Display name for SMS notifications (optional)"
  type        = string
  default     = null
}

variable "kms_master_key_id" {
  description = "KMS key ID or ARN for encrypting SNS topic (optional)"
  type        = string
  default     = null
}

variable "subscription_protocol" {
  description = "Protocol for the SNS subscription (e.g., email, https, sms)"
  type        = string
  default     = "email"
}

variable "subscription_endpoint" {
  description = "Endpoint for the SNS subscription (e.g., email address or URL)"
  type        = string
}

variable "raw_message_delivery" {
  description = "Enable raw message delivery for subscriptions that support it"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the SNS topic"
  type        = map(string)
  default     = {}
}


