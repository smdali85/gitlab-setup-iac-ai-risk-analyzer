terraform {
  backend "s3" {
    bucket         = "gitlab-iac-setup-test"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
  }
}
