# Configuración general de Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket = "mi-app-tfstate-bucket-695100305629"   # El nombre de tu bucket
    key = "global/terraform.tfstate"                # La ruta donde se guardará el estado
    region = "us-east-1"                            # La región donde creaste el bucket
    dynamodb_table = "mi-app-terraform-lock"        # El nombre de tu tabla
    encrypt = true
  }

}

provider "aws" {
  region = var.aws_region
}