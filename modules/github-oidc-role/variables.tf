variable "role_name" {
  description = "IAM role name assumed by GitHub Actions."
  type        = string
}

variable "subject_claims" {
  description = <<-EOT
    Allowed GitHub OIDC `sub` claims (StringLike). Scope as tightly as possible, e.g.
      "repo:my-org/infra:ref:refs/heads/main"
      "repo:my-org/infra:environment:prod"
      "repo:my-org/infra:pull_request"
    Org- or repo-wide wildcards ("repo:*", "repo:my-org/*") are rejected.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subject_claims) > 0
    error_message = "At least one subject claim is required."
  }

  validation {
    condition     = alltrue([for s in var.subject_claims : can(regex("^repo:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+:[^*].*$", s))])
    error_message = "Each subject must be repo:<owner>/<repo>:<qualifier> with a literal owner and repo; wildcards are only allowed after the qualifier prefix."
  }
}

variable "create_oidc_provider" {
  description = "Create the token.actions.githubusercontent.com IAM OIDC provider. Set false if the account already has one (it is account-global)."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN. Required when create_oidc_provider = false."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Managed policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline policy document (JSON) for least-privilege, pipeline-specific permissions."
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary, commonly mandated in regulated / GovCloud accounts."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Max session length in seconds (3600-43200)."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags merged onto every resource."
  type        = map(string)
  default     = {}
}
