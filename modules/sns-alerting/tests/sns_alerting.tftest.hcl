# Offline unit tests: `terraform test` against a mocked provider, no AWS credentials required.

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws-us-gov"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111111111111"
    }
  }
}

variables {
  name = "platform-test-critical"
}

run "creates_cmk_when_none_supplied" {
  command = plan

  assert {
    condition     = length(aws_kms_key.this) == 1 && aws_kms_key.this[0].enable_key_rotation
    error_message = "A rotating CMK should be created when kms_key_arn is null."
  }

  assert {
    condition     = jsondecode(aws_kms_key.this[0].policy).Statement[0].Principal.AWS == "arn:aws-us-gov:iam::111111111111:root"
    error_message = "Key admin principal must be partition-aware (GovCloud-safe)."
  }
}

run "uses_supplied_key" {
  command = plan

  variables {
    kms_key_arn = "arn:aws-us-gov:kms:us-gov-west-1:111111111111:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(aws_kms_key.this) == 0 && aws_sns_topic.this.kms_master_key_id == var.kms_key_arn
    error_message = "Supplied key should be used and no key created."
  }
}

run "subscriptions" {
  command = plan

  variables {
    email_endpoints = ["oncall@example.com"]
    https_endpoints = ["https://events.example.com/integration/abc/enqueue"]
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 1 && length(aws_sns_topic_subscription.https) == 1
    error_message = "Expected one email and one https subscription."
  }
}

run "rejects_plain_http_webhook" {
  command = plan

  variables {
    https_endpoints = ["http://insecure.example.com/hook"]
  }

  expect_failures = [var.https_endpoints]
}
