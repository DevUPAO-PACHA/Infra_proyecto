output "rds_cluster_endpoint" {
  description = "El endpoint de conexión (escritura) del cluster Aurora."
  value       = aws_rds_cluster.aurora.endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "El endpoint de solo lectura del cluster Aurora."
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "db_secret_arn" {
  description = "El ARN del secreto en Secrets Manager."
  value       = aws_secretsmanager_secret.db.arn
}

output "alb_dns_name" {
  description = "El DNS público del Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "frontend_url" {
  description = "La URL pública (CloudFront) de la aplicación."
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}