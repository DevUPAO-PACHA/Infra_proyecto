environment = "dev"

aws_region = "us-east-1"

app_name    = "ares-iac-dev"
db_username = "dbadmin"

# Red
vpc_cidr = "10.0.0.0/16"

availability_zones = ["us-east-1a", "us-east-1b"]

public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets_cidr = ["10.0.10.0/24", "10.0.11.0/24"]
db_subnets_cidr      = ["10.0.20.0/24", "10.0.21.0/24"]

# Logs
log_retention_days = 30

# Imagenes
api_image_uri    = "111111111111.dkr.ecr.us-east-1.amazonaws.com/mi-api:dev"
worker_image_uri = "111111111111.dkr.ecr.us-east-1.amazonaws.com/mi-worker:dev"

# Backend
backend_s3_bucket_name     = "tfstate-dev-974646089872"
backend_dynamo_table_name  = "tf-lock-dev"
