# --- 1. Generar una contraseña aleatoria y segura ---
resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "_%@" # Caracteres especiales permitidos por RDS
}

# --- 2. Crear el Secreto en AWS Secrets Manager ---
# Guardamos la contraseña generada aquí.
resource "aws_secretsmanager_secret" "db" {
  name = "mi-app/db-password"
  tags = {
    Name = "Secreto de BD para mi-app"
  }
}

# --- 3. Poblar el Secreto con el valor de la contraseña ---
resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}

# --- 4. Crear el Cluster de Amazon Aurora ---
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "mi-app-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.06.0" # Ejemplo, puedes elegir
  availability_zones      = var.availability_zones
  database_name           = "miAppDB"
  master_username         = var.db_username
  master_password         = random_password.db.result # Terraform pasa la contraseña

  db_subnet_group_name    = aws_db_subnet_group.aurora.name # Creado en vpc.tf
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = true # Poner 'false' para producción
  storage_encrypted       = true

  # Importante: le decimos a Terraform que el secreto DEBE crearse
  # ANTES de que intente crear la BD.
  depends_on = [
    aws_secretsmanager_secret_version.db
  ]

  tags = {
    Name = "mi-app-aurora-cluster"
  }
}

# --- 5. Crear las instancias del Cluster (Primaria y Standby) ---
# Tu diagrama muestra 2 (Primary, Standby), así que usamos count = 2
resource "aws_rds_cluster_instance" "aurora" {
  count              = 2
  cluster_identifier = aws_rds_cluster.aurora.id
  identifier         = "mi-app-aurora-instance-${count.index}"
  instance_class     = "db.t3.small" # Elige el tamaño adecuado
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  tags = {
    Name = "mi-app-aurora-instance-${count.index}"
  }
}