resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "_#"
}

resource "aws_secretsmanager_secret" "db" {
  name       = "${var.app_name}-${var.environment}-db-password"
  kms_key_id = aws_kms_key.secrets_key.arn

  tags = {
    Name        = "${var.app_name}-${var.environment}-db-secret"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${var.app_name}-${var.environment}-aurora-cluster"
  engine             = "aurora-mysql"
  kms_key_id         = aws_kms_key.secrets_key.arn

  availability_zones                  = var.availability_zones
  database_name                       = "miAppDB"
  master_username                     = var.db_username
  master_password                     = random_password.db.result
  enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery"]
  copy_tags_to_snapshot               = true
  iam_database_authentication_enabled = true
  db_subnet_group_name                = aws_db_subnet_group.aurora.name
  vpc_security_group_ids              = [aws_security_group.rds.id]
  skip_final_snapshot                 = true
  storage_encrypted                   = true
  deletion_protection                 = false

  backtrack_window = 3600

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4
  }

  depends_on = [
    aws_secretsmanager_secret_version.db
  ]

  tags = {
    Name        = "${var.app_name}-${var.environment}-aurora-cluster"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  count              = 2
  cluster_identifier = aws_rds_cluster.aurora.id
  identifier         = "${var.app_name}-${var.environment}-aurora-instance-${count.index}"

  instance_class = "db.serverless"

  engine         = aws_rds_cluster.aurora.engine
  engine_version = aws_rds_cluster.aurora.engine_version

  tags = {
    Name        = "${var.app_name}-${var.environment}-aurora-instance-${count.index}"
    Environment = var.environment
  }
}

resource "aws_backup_plan" "aws_backup_db" {
  name = "${var.app_name}-${var.environment}-aurora-backup-plan"

  rule {
    rule_name         = "DailyBackups"
    target_vault_name = "Default"
    schedule          = "cron(0 12 * * ? *)"
  }
}

resource "aws_backup_selection" "aurora_backup_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "aurora_backup_selection"
  plan_id      = aws_backup_plan.aws_backup_db.id

  resources = [
    aws_rds_cluster.aurora.arn
  ]
}
