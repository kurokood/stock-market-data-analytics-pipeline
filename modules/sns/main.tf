resource "aws_sns_topic" "this" {
  name         = var.topic_name
  display_name = var.display_name
  kms_master_key_id = var.kms_master_key_id

  tags = var.tags
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = var.subscription_protocol
  endpoint  = var.subscription_endpoint

  raw_message_delivery = var.raw_message_delivery
}


