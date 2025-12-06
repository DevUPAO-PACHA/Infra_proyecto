resource "aws_kms_key" "logs_key" {
  description = "KMS key for CloudWatch logs"
  key_usage   = "ENCRYPT_DECRYPT"
  is_enabled  = true
}

resource "aws_kms_key" "secrets_key" {
  description = "KMS key for Secrets Manager"
  key_usage   = "ENCRYPT_DECRYPT"
  is_enabled  = true
}
