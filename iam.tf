# --- 1. Rol de Ejecución de Tarea (Task Execution Role) ---
# El rol que Fargate *asume* para poder:
# 1. Bajar imágenes de ECR.
# 2. Enviar logs a CloudWatch.
# 3. (En nuestro caso) Jalar secretos de Secrets Manager.
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

# Política estándar de AWS para ejecución
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- 2. Rol de Tarea de la API (API Task Role) ---
# El rol que tu *aplicación* Spring Boot usa para hablar con AWS.
resource "aws_iam_role" "api_task_role" {
  name = "api-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

# --- 3. Rol de Tarea del Worker (Worker Task Role) ---
resource "aws_iam_role" "worker_task_role" {
  name = "worker-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

# --- 4. Política de Permisos Personalizada (La Magia) ---
# Esta política define QUÉ pueden hacer tus roles.
resource "aws_iam_policy" "fargate_permissions" {
  name        = "fargate-app-permissions"
  description = "Permisos para SQS, Secrets Manager y SES"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # Permiso para LEER EL SECRETO de la BD
        Sid    = "AllowSecretRead",
        Effect = "Allow",
        Action = "secretsmanager:GetSecretValue",
        Resource = [
          aws_secretsmanager_secret.db.arn
        ]
      },
      {
        # Permiso para ENVIAR mensajes a SQS (solo la API)
        Sid    = "AllowSQSSend",
        Effect = "Allow",
        Action = "sqs:SendMessage",
        Resource = [
          aws_sqs_queue.reservas_queue.arn
        ]
      },
      {
        # Permiso para LEER/BORRAR de SQS (solo el Worker)
        Sid    = "AllowSQSReceiveDelete",
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = [
          aws_sqs_queue.reservas_queue.arn
        ]
      },
      {
        # Permiso para ENVIAR EMAILS (solo el Worker)
        Sid    = "AllowSESSend",
        Effect = "Allow",
        Action = "ses:SendEmail",
        Resource = "*" # Ajustar si se usa un ARN específico de SES
      }
    ]
  })
}

# --- 5. Adjuntar la política a los roles ---
# La API solo necesita enviar a SQS y leer secretos
resource "aws_iam_role_policy_attachment" "api_permissions" {
  role       = aws_iam_role.api_task_role.name
  policy_arn = aws_iam_policy.fargate_permissions.arn
}

# El Worker necesita recibir/borrar de SQS, leer secretos y enviar emails
resource "aws_iam_role_policy_attachment" "worker_permissions" {
  role       = aws_iam_role.worker_task_role.name
  policy_arn = aws_iam_policy.fargate_permissions.arn
}

# El Rol de Ejecución (Paso 1) también necesita leer el secreto
resource "aws_iam_role_policy_attachment" "ecs_execution_secret_access" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.fargate_permissions.arn
  # Reutilizamos la política; solo usará la parte de SecretsManager
}