variable "aws_region" {
  description = "Región de AWS para desplegar los recursos."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Rango CIDR para la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

# --- Subredes para 2 Zonas de Disponibilidad (Multi-AZ) ---

variable "availability_zones" {
  description = "Zonas de Disponibilidad (2) a usar."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets_cidr" {
  description = "Rangos CIDR para las subredes públicas (para ALB y NAT-GW)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  description = "Rangos CIDR para las subredes privadas (para Fargate)."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "db_subnets_cidr" {
  description = "Rangos CIDR para las subredes de base de datos."
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "app_port" {
  description = "Puerto en el que escucha la aplicación Spring Boot (Diagrama: 8000)."
  type        = number
  default     = 8000
}

variable "db_username" {
  description = "Usuario 'master' para la base de datos Aurora."
  type        = string
  default     = "dbadmin"
}

variable "api_image_uri" {
  description = "URI de la imagen Docker para la API Spring Boot (ej: desde ECR)."
  type        = string
  # No hay 'default'. Esto DEBE ser proporcionado por el pipeline.
}

variable "worker_image_uri" {
  description = "URI de la imagen Docker para el Worker (ej: desde ECR)."
  type        = string
  # No hay 'default'.
}

variable "backend_s3_bucket_name" {
  description = "El nombre del bucket S3 para el backend."
  type        = string
  default     = "mi-app-tfstate-bucket-695100305629" # El nombre que creaste
}

variable "backend_dynamo_table_name" {
  description = "El nombre de la tabla DynamoDB para el backend."
  type        = string
  default     = "mi-app-terraform-lock" # El nombre que creaste
}