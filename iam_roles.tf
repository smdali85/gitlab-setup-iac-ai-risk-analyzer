resource "aws_iam_role" "ec2_roles" {
  for_each = var.ec2_servers

  name = "${var.app_name}-${each.value.iam_role_name}-${var.env}-main"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "${each.key}-ssm-ec2"
  }
}

resource "aws_iam_instance_profile" "ec2_profiles" {
  for_each = var.ec2_servers

  name = "${each.key}-ssm-ec2"
  role = aws_iam_role.ec2_roles[each.key].id
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachments" {
  for_each = var.ec2_servers

  #name       = "${each.key}-attachment"
  role       = aws_iam_role.ec2_roles[each.key].name
  policy_arn = each.value.iam_policy_arn
}

output "ec2_role_arns" {
  description = "ARNs of IAM roles for EC2 instances"
  value = {
    for key, role in aws_iam_role.ec2_roles : key => role.arn
  }
}

output "ec2_instance_profile_names" {
  description = "Names of IAM instance profiles for EC2 instances"
  value = {
    for key, profile in aws_iam_instance_profile.ec2_profiles : key => profile.name
  }
}