environment = "stage"

aws_region = "us-east-1"

app_name    = "ares-iac-stage"
db_username = "dbadmin"

vpc_cidr = "10.1.0.0/16"

availability_zones = ["us-east-1a", "us-east-1b"]

public_subnets_cidr  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnets_cidr = ["10.1.10.0/24", "10.1.11.0/24"]
db_subnets_cidr      = ["10.1.20.0/24", "10.1.21.0/24"]

log_retention_days = 30

api_image_uri    = "111111111111.dkr.ecr.us-east-1.amazonaws.com/mi-api:stage"
worker_image_uri = "111111111111.dkr.ecr.us-east-1.amazonaws.com/mi-worker:stage"

backend_s3_bucket_name    = "tfstate-stage-974646089872"
backend_dynamo_table_name = "tf-lock-stage"
