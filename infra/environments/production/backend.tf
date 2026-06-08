

terraform {
  backend "s3" {
    bucket         = "cloudmart-tf-state-537090271991"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "cloudmart-tf-locks"
  }
}
