data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  root_arn    = "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root"
  kms_key_arn = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.this[0].arn
}

# CloudWatch alarms cannot publish to a topic encrypted with the AWS-managed aws/sns key,
# so encrypted alerting topics need a CMK whose policy grants the publishing services.
resource "aws_kms_key" "this" {
  count = var.kms_key_arn == null ? 1 : 0

  description         = "SNS encryption for ${var.name}"
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = local.root_arn }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowAlertPublishers"
        Effect    = "Allow"
        Principal = { Service = var.publisher_services }
        Action    = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource  = "*"
        Condition = { StringEquals = { "aws:SourceAccount" = local.account_id } }
      },
    ]
  })
  tags = var.tags
}

resource "aws_kms_alias" "this" {
  count = var.kms_key_arn == null ? 1 : 0

  name          = "alias/sns-${var.name}"
  target_key_id = aws_kms_key.this[0].key_id
}

resource "aws_sns_topic" "this" {
  name              = var.name
  kms_master_key_id = local.kms_key_arn
  tags              = var.tags
}

resource "aws_sns_topic_policy" "this" {
  arn = aws_sns_topic.this.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAlertPublishers"
        Effect    = "Allow"
        Principal = { Service = var.publisher_services }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.this.arn
        Condition = { StringEquals = { "aws:SourceAccount" = local.account_id } }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.this.arn
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.email_endpoints)

  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = each.value
}

# Keyed by index so the (sensitive) URL never becomes a resource address in plan output or state paths.
resource "aws_sns_topic_subscription" "https" {
  count = nonsensitive(length(var.https_endpoints))

  topic_arn              = aws_sns_topic.this.arn
  protocol               = "https"
  endpoint               = var.https_endpoints[count.index]
  endpoint_auto_confirms = true
}
