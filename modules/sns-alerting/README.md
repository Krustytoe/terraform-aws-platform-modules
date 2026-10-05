# sns-alerting

KMS-encrypted SNS topic that CloudWatch alarms and EventBridge rules can publish to, with email and HTTPS (e.g. PagerDuty) subscriptions.

## Gotchas this module handles

- **The AWS-managed `aws/sns` key silently breaks CloudWatch alarms.** Its key policy can't be edited to grant `cloudwatch.amazonaws.com`, so alarm actions fail. This module creates a CMK, with rotation on, that grants the publishing services `GenerateDataKey*` / `Decrypt`, scoped by `aws:SourceAccount`.
- **Webhook URLs are secrets.** PagerDuty integration URLs embed the routing key, so `https_endpoints` is `sensitive` and subscriptions are keyed by index, keeping the URL out of resource addresses.
- **TLS-only publishing.** The topic policy denies `sns:Publish` when `aws:SecureTransport` is false.

## Convention

Create one topic per severity:

| Topic | Meaning | Typical subscribers |
|---|---|---|
| `<env>-warning` | Awareness; act within business hours | Email, ticketing |
| `<env>-critical` | Service impact; act now | PagerDuty / on-call |

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Topic name |
| `kms_key_arn` | string | `null` | Bring your own CMK; otherwise one is created |
| `email_endpoints` | list(string) | `[]` | Email subscribers |
| `https_endpoints` | list(string), sensitive | `[]` | HTTPS webhooks (`https://` enforced) |
| `publisher_services` | list(string) | CloudWatch, EventBridge | Service principals allowed to publish |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`topic_arn`, `kms_key_arn`
