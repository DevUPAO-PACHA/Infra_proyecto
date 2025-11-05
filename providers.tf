# Configuración general de Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Usar una versión reciente del provider de AWS
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # NOTA: Más adelante, aquí configuraremos el "Backend Remoto"
  # (S3 + DynamoDB) que discutimos, para guardar el estado .tfstate
  # de forma segura. Por ahora, para esta primera parte,
  # se guardará localmente.
  backend "s3" {
    bucket = "mi-app-tfstate-bucket-695100305629" # El nombre de tu bucket
    key = "global/terraform.tfstate"           # La ruta donde se guardará el estado
    region = "us-east-1"                          # La región donde creaste el bucket
    dynamodb_table = "mi-app-terraform-lock"            # El nombre de tu tabla
    encrypt = true
  }

}

# Configuración del proveedor de AWS
provider "aws" {
  region = var.aws_region
}