# Offline unit tests: `terraform test` against a mocked provider, no AWS credentials required.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-gov-west-1a", "us-gov-west-1b", "us-gov-west-1c"]
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111111111111"
    }
  }
}

variables {
  name       = "unit-test"
  cidr_block = "10.10.0.0/16"
}

run "defaults_two_az_single_nat" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Expected 2 public and 2 private subnets by default."
  }

  assert {
    condition     = aws_subnet.public[0].cidr_block == "10.10.0.0/20" && aws_subnet.private[0].cidr_block == "10.10.128.0/20"
    error_message = "Public subnets should start at the bottom of the range, private at the midpoint."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_route.private_nat) == 2
    error_message = "single mode should create one NAT shared by every private route table."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Public subnets must not auto-assign public IPs."
  }

  assert {
    condition     = length(aws_flow_log.this) == 1 && aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Flow logs should be on and capture ALL traffic by default."
  }
}

run "per_az_nat_three_az" {
  command = plan

  variables {
    az_count         = 3
    nat_gateway_mode = "per_az"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3 && length(aws_route_table.private) == 3
    error_message = "per_az mode should create one NAT and one private route table per AZ."
  }
}

run "isolated_no_nat_no_flow_logs" {
  command = plan

  variables {
    nat_gateway_mode = "none"
    enable_flow_logs = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_route.private_nat) == 0
    error_message = "none mode must not create NAT gateways or private default routes."
  }

  assert {
    condition     = length(aws_flow_log.this) == 0 && length(aws_iam_role.flow_logs) == 0
    error_message = "Flow log resources should be skipped when disabled."
  }
}

run "rejects_bad_nat_mode" {
  command = plan

  variables {
    nat_gateway_mode = "multi"
  }

  expect_failures = [var.nat_gateway_mode]
}
