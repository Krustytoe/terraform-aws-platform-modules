# Offline unit tests: `terraform test` against a mocked provider, no AWS credentials required.

mock_provider "aws" {}

variables {
  role_name      = "gha-deploy"
  subject_claims = ["repo:example-org/infra:ref:refs/heads/main", "repo:example-org/infra:environment:prod"]
}

run "creates_provider_by_default" {
  command = plan

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 1
    error_message = "OIDC provider should be created by default."
  }

  assert {
    condition     = one(aws_iam_openid_connect_provider.github[*].client_id_list) == toset(["sts.amazonaws.com"])
    error_message = "Audience must be sts.amazonaws.com."
  }
}

run "trust_policy_is_scoped" {
  command = plan

  variables {
    create_oidc_provider = false
    oidc_provider_arn    = "arn:aws-us-gov:iam::111111111111:oidc-provider/token.actions.githubusercontent.com"
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 0
    error_message = "Provider must not be created when an existing ARN is supplied."
  }

  assert {
    condition = (
      tolist(jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"])
      == tolist(var.subject_claims)
    )
    error_message = "Trust policy sub condition must match subject_claims exactly."
  }

  assert {
    condition     = jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Principal.Federated == var.oidc_provider_arn
    error_message = "Trust policy must federate to the supplied provider ARN."
  }
}

run "rejects_wildcard_repo" {
  command = plan

  variables {
    subject_claims = ["repo:example-org/*"]
  }

  expect_failures = [var.subject_claims]
}

run "rejects_global_wildcard" {
  command = plan

  variables {
    subject_claims = ["repo:*"]
  }

  expect_failures = [var.subject_claims]
}
