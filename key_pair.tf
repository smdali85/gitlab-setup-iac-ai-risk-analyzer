resource "tls_private_key" "tls_key" {
  algorithm = "RSA"
}


module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  version = "2.0.0"

  key_name   = "${var.app_name}-${var.env}"
  public_key = trimspace(tls_private_key.tls_key.public_key_openssh)
}


output "key_pair"{
  value = module.key_pair.key_pair_id
  description = "Key Pair ID"
}

output "private_key" {
  value     = tls_private_key.tls_key.private_key_pem
  sensitive = true
  description = "Private key in PEM format"
}
