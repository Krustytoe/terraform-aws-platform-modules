# vpc-baseline

## Requirements

Terraform >= 1.7, AWS provider >= 5.0. Run `terraform test` for offline validation (no AWS credentials required).

Multi-AZ VPC with public and private tiers, configurable NAT, and VPC flow logs to CloudWatch.

## Layout

With `cidr_block = "10.20.0.0/16"` and the default `subnet_newbits = 4`:

| Tier | AZ a | AZ b | AZ c |
|---|---|---|---|
| public | 10.20.0.0/20 | 10.20.16.0/20 | 10.20.32.0/20 |
| private | 10.20.128.0/20 | 10.20.144.0/20 | 10.20.160.0/20 |

Public subnets take the lower half of the range and private subnets the upper half, so adding AZs later never re-numbers existing subnets.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Name prefix (3-32 chars, `[a-z0-9-]`) |
| `cidr_block` | string | — | VPC IPv4 CIDR |
| `az_count` | number | `2` | AZs to span (1-6) |
| `subnet_newbits` | number | `4` | Bits added per subnet |
| `nat_gateway_mode` | string | `"single"` | `none` \| `single` \| `per_az` |
| `enable_flow_logs` | bool | `true` | Flow logs (ALL traffic) to CloudWatch |
| `flow_log_retention_days` | number | `365` | Log retention |
| `flow_log_kms_key_arn` | string | `null` | Optional CMK for the log group |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`vpc_id`, `vpc_cidr_block`, `azs`, `public_subnet_ids`, `private_subnet_ids`, `private_route_table_ids`, `nat_gateway_public_ips`, `flow_log_group_name`
