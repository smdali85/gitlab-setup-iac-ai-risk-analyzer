# COMMON

variable "app_name" {
  description = "Application Name"
  type        = string
}

variable "env" {
  description = "Environment Name"
  type        = string
}

variable "region_name" {
  description = "Region Name"
  type        = string
}

variable "preferred_maintenance_window" {
  description = "Preferred Maintenance Window"
  type        = string
}

variable "preferred_backup_window" {
  description = "Preferred Backup Window"
  type        = string
}



# VPC

variable "cidr" {
  description = "CIDR Range"
  type        = string
}

variable "public_subnets" {
  description = "Public Subnets"
  type        = list
}

variable "private_subnets" {
  description = "Private Subnets"
  type        = list
}

variable "ipv4_cidr" {
  description = "Allowed CIDR block for egress traffic"
  type        = string
}

variable "ipv6_cidr" {
  description = "Allowed IPv6 CIDR block for egress traffic"
  type        = string
}

#vpn

variable "vpn_cidr" {
  description = "VPN CIDR Range"
  type        = string
}

# EC2

variable "ec2_servers" {
  description = "Map of EC2 server configurations"
  type = map(object({
    instance_type       = string
    volume_size         = number
    volume_type         = string
    ec2_ami_id          = string
    iam_role_name       = string
    iam_policy_arn      = string
    security_group_name = string
    subnet_type         = string
    user_data_file      = string
    eip                 = bool
  }))
}



#S3

variable "bucket_names" {
  description = "Map of S3 bucket names to create"
  type = map(object({
    bucket_name    = string
    create_bucket  = bool
  }))
}


# AWS EC2 Instance Key Pair
variable "instance_keypair" {
  description = "AWS EC2 Key pair that need to be associated with EC2 Instance"
  type = string
  
}

