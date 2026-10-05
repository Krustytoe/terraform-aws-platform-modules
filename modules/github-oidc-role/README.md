# github-oidc-role

IAM role that GitHub Actions assumes through OIDC, so no long-lived AWS keys live in repo secrets.

## Why the guardrails

The most common OIDC misconfiguration is a trust policy with `sub = "repo:my-org/*"` or no `sub` condition at all, which lets **any** repo in the org, or on GitHub, assume the role. This module refuses to plan those values:

| `subject_claims` value | Result |
|---|---|
| `repo:my-org/infra:environment:prod` | ✅ recommended: pairs with GitHub environment protection rules |
| `repo:my-org/infra:ref:refs/heads/main` | ✅ |
| `repo:my-org/infra:pull_request` | ✅ (give this one read-only permissions) |
| `repo:my-org/*` | ❌ rejected |
| `repo:*` | ❌ rejected |

## Workflow side

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    environment: prod
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws-us-gov:iam::123456789012:role/gha-platform-prod
          aws-region: us-gov-west-1
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `role_name` | string | — | Role name |
| `subject_claims` | list(string) | — | Allowed `sub` claims (validated) |
| `create_oidc_provider` | bool | `true` | The provider is account-global; set `false` if it already exists |
| `oidc_provider_arn` | string | `null` | Required when not creating the provider |
| `managed_policy_arns` | list(string) | `[]` | Managed policies to attach |
| `inline_policy_json` | string | `null` | Least-privilege inline policy |
| `permissions_boundary_arn` | string | `null` | Permissions boundary |
| `max_session_duration` | number | `3600` | Seconds |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`role_arn`, `role_name`, `oidc_provider_arn`
