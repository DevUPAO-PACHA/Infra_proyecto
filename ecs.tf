# --- 1. El Cluster ECS ---
# Es solo un agrupador lógico para tus servicios.
resource "aws_ecs_cluster" "main" {
  name = "mi-app-cluster"

  tags = {
    Name = "mi-app-cluster"
  }
}

# --- 2. Grupos de Logs en CloudWatch ---
resource "aws_cloudwatch_log_group" "api" {
  name = "/ecs/mi-app-api"
  retention_in_days = 7 # Guarda logs por 7 días

  tags = {
    Name = "log-group-api"
  }
}

resource "aws_cloudwatch_log_group" "worker" {
  name = "/ecs/mi-app-worker"
  retention_in_days = 7

  tags = {
    Name = "log-group-worker"
  }
}

# --- 3. Definición de Tarea de la API (El plano de la API) ---
resource "aws_ecs_task_definition" "api" {
  family                   = "mi-app-api"
  network_mode             = "awsvpc" # Requerido por Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512  # 0.5 vCPU
  memory                   = 1024 # 1 GB RAM

  execution_role_arn = aws_iam_role.ecs_execution_role.arn # Rol para bajar imagen/logs
  task_role_arn      = aws_iam_role.api_task_role.arn      # Rol para la App (SQS, etc)

  # Esta es la definición de tu contenedor Spring Boot
  container_definitions = jsonencode([
    {
      name      = "mi-app-api-container"
      image     = var.api_image_uri
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
        }
      ]

      # Conexión a CloudWatch Logs
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api"
        }
      }

      # Variables de Entorno (¡Importante!)
      environment = [
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:mysql://${aws_rds_cluster.aurora.endpoint}:3306/${aws_rds_cluster.aurora.database_name}" },
        { name = "SQS_QUEUE_URL", value = aws_sqs_queue.reservas_queue.id }
      ]

      # Inyección de Secretos (¡Magia!)
      secrets = [
        {
          name      = "SPRING_DATASOURCE_USERNAME",
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.db_username}" # Nota: Esto es un truco para pasar un valor no-secreto
        },
        {
          name      = "SPRING_DATASOURCE_PASSWORD",
          valueFrom = aws_secretsmanager_secret.db.arn
        }
      ]
    }
  ])
}

# --- 4. Definición de Tarea del Worker (El plano del Worker) ---
resource "aws_ecs_task_definition" "worker" {
  family                   = "mi-app-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256  # 0.25 vCPU
  memory                   = 512  # 0.5 GB RAM

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.worker_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "mi-app-worker-container"
      image     = var.worker_image_uri
      essential = true

      # Sin portMappings, porque no recibe tráfico entrante.

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "worker"
        }
      }

      environment = [
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:mysql://${aws_rds_cluster.aurora.endpoint}:3306/${aws_rds_cluster.aurora.database_name}" },
        { name = "SQS_QUEUE_URL", value = aws_sqs_queue.reservas_queue.id }
      ]

      secrets = [
        {
          name      = "SPRING_DATASOURCE_USERNAME",
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.db_username}"
        },
        {
          name      = "SPRING_DATASOURCE_PASSWORD",
          valueFrom = aws_secretsmanager_secret.db.arn
        }
      ]
    }
  ])
}

# --- 5. Servicio Fargate de la API ---
# Esto *ejecuta* la definición de tarea de la API y la mantiene viva.
resource "aws_ecs_service" "api" {
  name            = "mi-app-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  launch_type     = "FARGATE"
  desired_count   = 2 # Ejecuta 2 copias para Alta Disponibilidad

  # Configuración de Red
  network_configuration {
    subnets         = aws_subnet.private.*.id       # Vive en subredes PRIVADAS
    security_groups = [aws_security_group.fargate_api.id]
  }

  # Conexión al Load Balancer
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "mi-app-api-container"
    container_port   = var.app_port
  }

  # Espera a que el ALB esté listo antes de intentar registrarse
  depends_on = [aws_lb_listener.http]
}

# --- 6. Servicio Fargate del Worker ---
# Ejecuta la definición de tarea del Worker
resource "aws_ecs_service" "worker" {
  name            = "mi-app-worker-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Puedes escalar esto con AutoScaling basado en la cola SQS

  network_configuration {
    subnets         = aws_subnet.private.*.id
    security_groups = [aws_security_group.fargate_worker.id]
  }

  # Sin bloque 'load_balancer'
}