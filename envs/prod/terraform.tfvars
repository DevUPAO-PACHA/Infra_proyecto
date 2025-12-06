environment = "prod"

aws_region = "us-east-1"

app_name    = "ares-iac-prod"
db_username = "dbadmin"

vpc_cidr = "10.2.0.0/16"

availability_zones = ["us-east-1a", "us-east-1b"]

public_subnets_cidr  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnets_cidr = ["10.2.10.0/24", "10.2.11.0/24"]
db_subnets_cidr      = ["10.2.20.0/24", "10.2.21.0/24"]

log_retention_days = 30

api_image_uri    = "111111111111.dkr.ecr.us-east-1.amazonaws.com/mi-api:prod"
worker_image_uri = "111111111111.dkr.ecr.us-east-1.amazonaws.com/mi-worker:prod"

backend_s3_bucket_name    = "tfstate-prod-974646089872"
backend_dynamo_table_name = "tf-lock-prod"
