variable "name" {
  description = "Name prefix applied to every resource (e.g. \"platform-prod\")."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.name))
    error_message = "name must be 3-32 chars of lowercase letters, digits and hyphens."
  }
}

variable "cidr_block" {
  description = "IPv4 CIDR for the VPC. A /16 with the default subnet_newbits yields /20 subnets."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 6
    error_message = "az_count must be between 1 and 6."
  }
}

variable "subnet_newbits" {
  description = "Bits added to the VPC prefix for each subnet. Public subnets use the lower half of the range, private the upper half."
  type        = number
  default     = 4
}

variable "nat_gateway_mode" {
  description = "\"none\" (no egress from private subnets), \"single\" (one shared NAT: cheaper, single-AZ dependency) or \"per_az\" (one NAT per AZ: HA)."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be one of: none, single, per_az."
  }
}

variable "enable_flow_logs" {
  description = "Ship VPC flow logs (ALL traffic) to CloudWatch Logs. Expected by most FedRAMP / NIST 800-53 AU-family baselines."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "CloudWatch Logs retention for flow logs."
  type        = number
  default     = 365
}

variable "flow_log_kms_key_arn" {
  description = "Optional CMK ARN to encrypt the flow log group. The key policy must allow logs.<region>.amazonaws.com."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags merged onto every resource."
  type        = map(string)
  default     = {}
}
