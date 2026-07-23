############################################
# Locals - Filter only required buckets
############################################
locals {
  filtered_bucket_names = {
    for key, bucket in var.bucket_names : key => bucket
    if bucket.create_bucket
  }

  # List of bucket full names for policy attachment
  bucket_full_names = toset([
    for key, bucket in local.filtered_bucket_names :
    "${var.app_name}-${bucket.bucket_name}-${var.env}"
  ])
}

############################################
# S3 Buckets Creation
############################################
module "s3_buckets" {
  source   = "terraform-aws-modules/s3-bucket/aws"
  version  = "~> 3.0"
  for_each = local.filtered_bucket_names

  bucket = "${var.app_name}-${each.value.bucket_name}-${var.env}"

  force_destroy = true

  versioning = {
    status = true
  }
 
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_key.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  logging = {
    target_bucket = module.s3_buckets["s3_log_access"].s3_bucket_id
    target_prefix = "log/"
  }

    tags = {
    Stack = upper(var.env)
  }
}

############################################
# Enforce HTTPS-only access for all buckets
############################################
resource "aws_s3_bucket_policy" "bucket_policy" {
  for_each = local.bucket_full_names

  bucket = each.value

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSSLRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [
          "arn:aws:s3:::${each.value}",
          "arn:aws:s3:::${each.value}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [module.s3_buckets]
}

############################################
# Outputs
############################################
output "s3_bucket_arns" {
  description = "ARNs of the S3 buckets"
  value       = [for bucket in module.s3_buckets : bucket.s3_bucket_arn]
}

output "s3_bucket_ids" {
  description = "IDs of the S3 buckets"
  value       = [for bucket in module.s3_buckets : bucket.s3_bucket_id]
}
