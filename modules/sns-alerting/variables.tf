variable "name" {
  description = "Topic name, e.g. \"platform-prod-critical\". Create one topic per severity so routing stays explicit."
  type        = string
}

variable "kms_key_arn" {
  description = "Existing CMK for SNS server-side encryption. When null, a dedicated key is created with a policy that lets CloudWatch and EventBridge publish."
  type        = string
  default     = null
}

variable "email_endpoints" {
  description = "Email addresses to subscribe (each must confirm the subscription)."
  type        = list(string)
  default     = []
}

variable "https_endpoints" {
  description = "HTTPS webhook endpoints, e.g. a PagerDuty CloudWatch integration URL. Treated as secret: these URLs usually embed an integration key."
  type        = list(string)
  default     = []
  sensitive   = true

  validation {
    condition     = alltrue([for u in var.https_endpoints : startswith(u, "https://")])
    error_message = "All webhook endpoints must use https://."
  }
}

variable "publisher_services" {
  description = "AWS service principals allowed to publish to the topic."
  type        = list(string)
  default     = ["cloudwatch.amazonaws.com", "events.amazonaws.com"]
}

variable "tags" {
  description = "Tags merged onto every resource."
  type        = map(string)
  default     = {}
}
