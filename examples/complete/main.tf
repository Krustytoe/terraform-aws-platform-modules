# End-to-end example: network baseline + CI/CD deploy role + severity-split alert topics.
# Works unchanged in commercial and GovCloud partitions (set region accordingly).

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "terraform-aws-platform-modules"
    }
  }
}

variable "region" {
  type    = string
  default = "us-gov-west-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "github_repository" {
  description = "owner/repo allowed to deploy, e.g. \"my-org/platform-infra\"."
  type        = string
}

variable "oncall_email" {
  type = string
}

variable "pagerduty_cloudwatch_url" {
  description = "PagerDuty CloudWatch integration URL. Pass via TF_VAR_pagerduty_cloudwatch_url, never commit it."
  type        = string
  sensitive   = true
  default     = null
}

module "vpc" {
  source = "../../modules/vpc-baseline"

  name             = "platform-${var.environment}"
  cidr_block       = "10.20.0.0/16"
  az_count         = 3
  nat_gateway_mode = var.environment == "prod" ? "per_az" : "single"
}

module "deploy_role" {
  source = "../../modules/github-oidc-role"

  role_name = "gha-platform-${var.environment}"
  subject_claims = [
    "repo:${var.github_repository}:environment:${var.environment}",
  ]
  managed_policy_arns = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"]
}

# Alerting convention: warning = awareness (email/ticket), critical = page someone.
module "alerts_warning" {
  source = "../../modules/sns-alerting"

  name            = "platform-${var.environment}-warning"
  email_endpoints = [var.oncall_email]
}

module "alerts_critical" {
  source = "../../modules/sns-alerting"

  name            = "platform-${var.environment}-critical"
  email_endpoints = [var.oncall_email]
  https_endpoints = var.pagerduty_cloudwatch_url == null ? [] : [var.pagerduty_cloudwatch_url]
}

data "aws_partition" "current" {}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "deploy_role_arn" {
  value = module.deploy_role.role_arn
}

output "alert_topics" {
  value = {
    warning  = module.alerts_warning.topic_arn
    critical = module.alerts_critical.topic_arn
  }
}
