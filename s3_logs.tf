# s3_logs.tf

# 1. El Bucket donde se guardarán los logs
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "alb-logs-${var.app_name}-${random_string.suffix.result}"
  force_destroy = true 
}

# Necesitamos un sufijo random porque los nombres de bucket son globales
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 2. Política obligatoria para que el ALB pueda escribir en este bucket
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = data.aws_iam_policy_document.alb_logs_policy_doc.json
}

# Datos necesarios para la política
data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "alb_logs_policy_doc" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.alb_logs.arn}/AWSLogs/*"]
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.alb_logs.id # Cambiar según el bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt_example" {
  bucket = aws_s3_bucket.alb_logs.id # Cambiar según el bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}