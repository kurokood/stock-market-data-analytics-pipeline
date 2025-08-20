# IAM Role for Lambda function with required permissions
resource "aws_iam_role" "lambda_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each  = toset(var.managed_policy_arns)
  role      = aws_iam_role.lambda_role.name
  policy_arn = each.value
}