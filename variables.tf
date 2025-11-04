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