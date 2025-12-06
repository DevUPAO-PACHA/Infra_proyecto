###############################################
# 1. ECS EXECUTION ROLE
###############################################

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.app_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-ecs-execution-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "execution_secrets_policy" {
  name = "${var.app_name}-${var.environment}-execution-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = [aws_secretsmanager_secret.db.arn]
    }]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-execution-secrets-policy"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "execution_secrets_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.execution_secrets_policy.arn
}

###############################################
# 2. API TASK ROLE
###############################################

resource "aws_iam_role" "api_task_role" {
  name = "${var.app_name}-${var.environment}-api-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-api-task-role"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "api_permissions" {
  name = "${var.app_name}-${var.environment}-api-permissions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "ReadSecret",
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = [aws_secretsmanager_secret.db.arn]
      },
      {
        Sid      = "SendSQS",
        Effect   = "Allow",
        Action   = ["sqs:SendMessage"],
        Resource = [aws_sqs_queue.reservas_queue.arn]
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-api-permissions"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "api_permissions_attach" {
  role       = aws_iam_role.api_task_role.name
  policy_arn = aws_iam_policy.api_permissions.arn
}

###############################################
# 3. WORKER TASK ROLE
###############################################

resource "aws_iam_role" "worker_task_role" {
  name = "${var.app_name}-${var.environment}-worker-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-worker-task-role"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "worker_permissions" {
  name = "${var.app_name}-${var.environment}-worker-permissions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "ReadSecret",
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = [aws_secretsmanager_secret.db.arn]
      },
      {
        Sid    = "ReceiveDeleteSQS",
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = [aws_sqs_queue.reservas_queue.arn]
      },
      {
        Sid    = "SendEmail",
        Effect = "Allow",
        Action = ["ses:SendEmail"],
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-${var.environment}-worker-permissions"
    Environment = var.environment
  }
}

resource "aws_iam_role" "backup_role" {
  name = "${var.app_name}-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy" "backup_role_policy" {
  name   = "${var.app_name}-${var.environment}-backup-policy"
  role   = aws_iam_role.backup_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:CreateDBClusterSnapshot",
          "rds:CreateDBSnapshot",
          "rds:CopyDBSnapshot",
          "rds:DeleteDBClusterSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:DescribeDBClusterSnapshots"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "backup:StartBackupJob"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
