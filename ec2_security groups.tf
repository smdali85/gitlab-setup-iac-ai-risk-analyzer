/*#security groups

module "security_groups" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"
  #count      = var.create_jenkins_server_sg ? 1 : 0
  version = "4.10.0"
  for_each               = var.ec2_servers

  name        = "${var.app_name}-${each.value.security_group_name}-${var.env}"
  description = "Security group for ec2 Server ${upper(var.env)}"
  vpc_id      = aws_vpc.main.id

  ingress_cidr_blocks = [ var.cidr ]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = [ var.ipv4_cidr ]
  egress_ipv6_cidr_blocks = [ var.ipv6_cidr ]
 
}*/

#security groups

module "security_groups" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.10.0"

  for_each = var.ec2_servers

  name        = "${var.app_name}-${each.value.security_group_name}-${var.env}"
  description = "Security group for ${each.key}"
  vpc_id      = aws_vpc.main.id

  # -----------------------------
  # INGRESS RULES PER SERVER
  # -----------------------------
  ingress_with_cidr_blocks = concat(

    # --------------------------------
    # BASTION HOST RULES
    # --------------------------------
    each.key == "bastion_host" ? [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        description = "SSH from Office"
        cidr_blocks = var.cidr
      }
    ] : [],

    # --------------------------------
    # OPENVPN RULES
    # --------------------------------
    each.key == "openvpn" ? [
      {
        from_port   = 1194
        to_port     = 1194
        protocol    = "udp"
        description = "OpenVPN Access"
        cidr_blocks = var.ipv4_cidr
      },
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        description = "SSH Connectivity"
        cidr_blocks = var.cidr
      }
    ] : [],

    # --------------------------------
    # GITLAB RULES
    # --------------------------------
    each.key == "gitlab" ? [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        description = "SSH from Bastion"
        cidr_blocks = var.cidr
      },
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        description = "HTTP from VPN"
        cidr_blocks = var.vpn_cidr
      },
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        description = "HTTPS from VPN"
        cidr_blocks = var.vpn_cidr
      }
    ] : []
  )

  # -----------------------------
  # EGRESS RULES
  # -----------------------------
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = var.ipv4_cidr
    }
  ]

  egress_with_ipv6_cidr_blocks = [
    {
      rule             = "all-all"
      ipv6_cidr_blocks = var.ipv6_cidr
    }
  ]

  tags = {
    Project = var.app_name
    Env     = var.env
  }
}





