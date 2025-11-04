# Configuración general de Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Usar una versión reciente del provider de AWS
    }
  }

  # NOTA: Más adelante, aquí configuraremos el "Backend Remoto"
  # (S3 + DynamoDB) que discutimos, para guardar el estado .tfstate
  # de forma segura. Por ahora, para esta primera parte,
  # se guardará localmente.
}

# Configuración del proveedor de AWS
provider "aws" {
  region = var.aws_region
}