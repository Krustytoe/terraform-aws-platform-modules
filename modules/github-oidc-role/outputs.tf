output "role_arn" {
  description = "Role ARN to pass to aws-actions/configure-aws-credentials `role-to-assume`."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Role name."
  value       = aws_iam_role.this.name
}

output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN (created or supplied)."
  value       = local.oidc_provider_arn
}
