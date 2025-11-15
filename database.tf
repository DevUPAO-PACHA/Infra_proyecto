# --- 1. Generar una contraseña aleatoria y segura ---
resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# --- 2. Crear el Secreto en AWS Secrets Manager ---
resource "aws_secretsmanager_secret" "db" {
  name = "mi-app/db-password"

  tags = {
    Name = "Secreto de BD para mi-app"
  }
}

# --- 3. Poblar el Secreto ---
resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}

# --- 4. Crear el Cluster Aurora Serverless v2 ---
resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "mi-app-aurora-cluster"
  engine             = "aurora-mysql"

  # Si quieres versión automática no pongas engine_version.
  # engine_version = "8.0.mysql_aurora.3.05.2"

  availability_zones     = var.availability_zones
  database_name          = "miAppDB"
  master_username        = var.db_username
  master_password        = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  storage_encrypted      = true

  # ACTIVAR SERVERLESS V2
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4
  }

  depends_on = [
    aws_secretsmanager_secret_version.db
  ]

  tags = {
    Name = "mi-app-aurora-cluster"
  }
}

# --- 5. Crear las Instancias del Cluster ---
resource "aws_rds_cluster_instance" "aurora" {
  count              = 2
  cluster_identifier = aws_rds_cluster.aurora.id
  identifier         = "mi-app-aurora-instance-${count.index}"

  # Instancia compatible con Serverless v2
  instance_class = "db.serverless"

  engine         = aws_rds_cluster.aurora.engine
  engine_version = aws_rds_cluster.aurora.engine_version

  tags = {
    Name = "mi-app-aurora-instance-${count.index}"
  }
}
