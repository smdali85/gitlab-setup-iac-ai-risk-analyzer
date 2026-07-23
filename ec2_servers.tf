locals {
   security_group_map = { for name, sg in module.security_groups : name => {
      id   = sg.security_group_id
      name = sg.security_group_name
    }}
}


module "ec2_server" {
  source   = "terraform-aws-modules/ec2-instance/aws"
  version  = "4.0.0"
  for_each = var.ec2_servers

  name                   = "${var.app_name}-${each.key}-${var.env}"
  instance_type          = each.value.instance_type
  ami                    = each.value.ec2_ami_id
  key_name               = module.key_pair.key_pair_name
  vpc_security_group_ids = [local.security_group_map[each.key].id]

  subnet_id                     = each.value.subnet_type == "public" ? aws_subnet.public[0].id : aws_subnet.private[0].id
  associate_public_ip_address   = each.value.subnet_type == "public"

  user_data_base64 = base64encode(file(each.value.user_data_file))

  root_block_device = [{
    encrypted   = true
    volume_type = each.value.volume_type
    volume_size = each.value.volume_size
    kms_key_id  = module.kms_key.key_arn
  }]

  iam_instance_profile = aws_iam_instance_profile.ec2_profiles[each.key].id

  tags = {
    Name  = each.key
    Stack = upper(var.env)
  }
}



# Allocate Elastic IP for Bastion Host and OpenVPN
resource "aws_eip" "ec2_eip" {
  for_each = {
    for k, v in var.ec2_servers : k => v if v.eip
  }

  domain = "vpc"
}

resource "aws_eip_association" "ec2_eip_assoc" {
  for_each = aws_eip.ec2_eip

  instance_id   = module.ec2_server[each.key].id
  allocation_id = each.value.id
}





