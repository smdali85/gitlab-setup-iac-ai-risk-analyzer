data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = var.cidr
  tags = {
    Name = "${var.app_name}-${var.env}"
    Stack = upper(var.env)
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}


resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.app_name}-${var.env}-public-subnet-${count.index}"
    "kubernetes.io/role/elb"                                = "1"
    "kubernetes.io/cluster/${var.app_name}-${var.env}-main"       = "shared"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags = {
    Name = "${var.app_name}-${var.env}-private-subnet-${count.index}"
    "kubernetes.io/cluster/${var.app_name}-${var.env}-main"       = "shared"
  }
}

resource "aws_nat_gateway" "public" {
  count       = length(aws_subnet.public)
  subnet_id  = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id

  tags = {
    Name = "${var.app_name}-${var.env}-private-subnet"
  }
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "nat" {
  count = length(var.public_subnets)
}

resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.main.id

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 101
    action     = "allow"
    ipv6_cidr_block = "::/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 101
    action     = "allow"
    ipv6_cidr_block = "::/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Pulic Rules"
  }
}

resource "aws_network_acl" "private_acl" {
  vpc_id = aws_vpc.main.id

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 101
    action     = "allow"
    ipv6_cidr_block = "::/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 101
    action     = "allow"
    ipv6_cidr_block = "::/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Private Rules"
  }
}

resource "aws_network_acl_association" "public_acl_association" {
  count       = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  network_acl_id = aws_network_acl.public_acl.id
}

resource "aws_network_acl_association" "private_acl_association" {
  count       = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  network_acl_id = aws_network_acl.private_acl.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.app_name}-${var.env}-public-route-table"
  }
}

# 9 private subnets and 3 NAT gateways mapping

locals {
  nat_gateway_mapping = [
    for index, subnet in var.private_subnets : {
      subnet_id     = subnet
      nat_gateway_id = aws_nat_gateway.public[index % length(aws_nat_gateway.public)].id
    }
  ]
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  count  = length(var.private_subnets)

  tags = {
    Name = "${var.app_name}-${var.env}-private-route-table-${count.index}"
  }
}

resource "aws_route" "private" {
  count = length(var.private_subnets)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.nat_gateway_mapping[count.index].nat_gateway_id
}



resource "aws_route_table_association" "public" {
  count        = length(aws_subnet.public)
  subnet_id    = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count        = length(aws_subnet.private)
  subnet_id    = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


resource "aws_flow_log" "logs" {
  log_destination      = module.s3_buckets["vpc_logs_s3"].s3_bucket_arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
}


output "vpc" {
  value = aws_vpc.main.id
}

#vpc_endpoints module

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.9.0"
  
  vpc_id = aws_vpc.main.id

  create_security_group      = true
  security_group_name_prefix = "${var.app_name}-vpc-endpoints-${var.env}"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [var.cidr]
    }
  }

  endpoints = {
    s3 = {
      service             = "s3"
      service_type        = "Gateway"
      private_dns_enabled = true
      
      tags = { Name = "${var.app_name}-${var.env}-s3-vpc-endpoint" }
    }
  }
  tags =  {
    Project  = "Secret"
    Endpoint = "true"
  }
}

# VPC endpoints
output "vpc_endpoints" {
  description = "Array containing the full resource object and attributes for all endpoints created"
  value       = module.vpc_endpoints.endpoints
}

output "vpc_endpoints_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = module.vpc_endpoints.security_group_arn
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group"
  value       = module.vpc_endpoints.security_group_id
}



