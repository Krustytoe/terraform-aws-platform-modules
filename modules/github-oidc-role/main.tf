locals {
  issuer_host       = "token.actions.githubusercontent.com"
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.oidc_provider_arn
}

check "provider_arn_supplied" {
  assert {
    condition     = var.create_oidc_provider || var.oidc_provider_arn != null
    error_message = "oidc_provider_arn is required when create_oidc_provider = false."
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://${local.issuer_host}"
  client_id_list = ["sts.amazonaws.com"]
  # AWS validates GitHub's issuer via its trusted CA store; thumbprints are kept for older provider versions that require them.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
  tags = var.tags
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary_arn

  # jsonencode (not aws_iam_policy_document) keeps the trust policy assertable in offline tests.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "GitHubActionsOIDC"
      Effect    = "Allow"
      Principal = { Federated = local.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "${local.issuer_host}:aud" = "sts.amazonaws.com" }
        StringLike   = { "${local.issuer_host}:sub" = var.subject_claims }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json == null ? 0 : 1

  name   = "${var.role_name}-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
