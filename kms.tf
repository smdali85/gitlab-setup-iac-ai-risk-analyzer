data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# KMS policy with arns
module "kms_key" {
  source = "clouddrove/kms/aws"
  version = "< 1.3.0"
  name        = "${var.app_name}-${var.env}-main"
  deletion_window_in_days = 7
  enabled     = true
  description = "${var.app_name}-${var.env}-main"
  alias       = "alias/${var.app_name}-${var.env}-main"
  enable_key_rotation     = true
  policy      = jsonencode(
{
    "Version": "2012-10-17",
    "Id": "key-consolepolicy-3",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${local.account_id}:root"
             },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "${aws_iam_role.ec2_roles["bastion_host"].arn}"
                    /*"${aws_iam_role.ec2_roles["airflow"].arn}",
                    "${aws_iam_role.ec2_roles["Jenkins"].arn}"*/
                    
                ]
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "${aws_iam_role.ec2_roles["bastion_host"].arn}"
                    /*"${aws_iam_role.ec2_roles["airflow"].arn}",
                    "${aws_iam_role.ec2_roles["Jenkins"].arn}"*/
                    
                ]
            },
            "Action": "kms:*",
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        },
        {
            "Sid": "AllowAccessResources",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "cloudwatch.amazonaws.com"
                    
                ]
            },
            "Action": [
                "kms:Decrypt",
                "kms:GenerateDataKey",
                "kms:Encrypt",
                "kms:ReEncrypt*"
            ],
            "Resource": "*"
        }

    ]
})

# Dependency on EKS and EC2 roles
  depends_on = [
    aws_iam_role.ec2_roles
  ]

}

output "kms_key" {
  value       = module.kms_key.key_arn
  description = "KMS Key ARN"
}