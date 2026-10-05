output "topic_arn" {
  description = "SNS topic ARN to use as a CloudWatch alarm / EventBridge rule target."
  value       = aws_sns_topic.this.arn
}

output "kms_key_arn" {
  description = "CMK encrypting the topic (created or supplied)."
  value       = local.kms_key_arn
}
