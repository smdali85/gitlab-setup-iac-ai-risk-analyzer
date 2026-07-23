# COMMON
app_name="gitlab-setup"
env="test"
region_name="ap-south-1"
preferred_maintenance_window="Sun:18:30-Sun:19:30"
preferred_backup_window="19:57-20:57"
instance_keypair = "gitlab-setup-test"


# VPC
cidr="10.10.0.0/16"
public_subnets=["10.10.0.0/23","10.10.2.0/23","10.10.4.0/23"]
private_subnets=["10.10.6.0/23","10.10.8.0/23","10.10.10.0/23"]

# below variables are used to allow outbound traffic
ipv4_cidr = "0.0.0.0/0"
ipv6_cidr = "::/0"

# VPN
vpn_cidr = "10.10.100.0/24"

#EC2 

ec2_servers = {
  bastion_host = {
    instance_type       = "t3a.medium"
    volume_size         = 100
    volume_type         = "gp3"
    ec2_ami_id          = "ami-0f69cf253b12352e3"
    iam_role_name       = "bastion-host-role"
    iam_policy_arn      = "arn:aws:iam::aws:policy/AdministratorAccess"
    security_group_name = "bastion-host-sg"
    subnet_type         = "public"
    user_data_file      = "user_data/bastion.sh"
    eip                 = true
  }

  openvpn = {
    instance_type       = "t3a.medium"
    volume_size         = 50
    volume_type         = "gp3"
    ec2_ami_id          = "ami-0f69cf253b12352e3"
    iam_role_name       = "openvpn-role"
    iam_policy_arn      = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    security_group_name = "openvpn-sg"
    subnet_type         = "public"
    user_data_file      = "user_data/openvpn.sh"
    eip                 = true
  }

  gitlab = {
    instance_type       = "m6i.large"
    volume_size         = 100
    volume_type         = "gp3"
    ec2_ami_id          = "ami-0f69cf253b12352e3"
    iam_role_name       = "gitlab-role"
    iam_policy_arn      = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    security_group_name = "gitlab-sg"
    subnet_type         = "private"
    user_data_file      = "user_data/gitlab.sh"
    eip                 = false
  }
}



# S3

bucket_names = {
    "s3_log_access" = {
      bucket_name     = "s3-log-access"
      create_bucket   = true
    }
    "vpc_logs_s3" = {
      bucket_name     = "vpc-logs"
      create_bucket   = true
    }
    "data_s3" = {
      bucket_name     = "data"
      create_bucket   = true
    }
}


