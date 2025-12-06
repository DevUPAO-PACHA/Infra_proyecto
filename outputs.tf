output "rds_cluster_endpoint" {
  description = "Endpoint de escritura del cluster Aurora para el entorno actual."
  value       = aws_rds_cluster.aurora.endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "Endpoint de solo lectura del cluster Aurora para el entorno actual."
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "db_secret_arn" {
  description = "ARN del secreto en Secrets Manager que almacena la contraseña de la base de datos para el entorno actual."
  value       = aws_secretsmanager_secret.db.arn
  sensitive   = true
}

output "alb_dns_name" {
  description = "DNS público del Application Load Balancer del entorno actual."
  value       = aws_lb.main.dns_name
}

output "frontend_url" {
  description = "URL pública (CloudFront) del frontend para el entorno actual."
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "environment" {
  description = "Entorno actual desplegado."
  value       = var.environment
}
