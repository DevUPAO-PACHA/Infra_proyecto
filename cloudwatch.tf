resource "aws_cloudwatch_log_group" "ecs_api" {
  name              = "/ecs/${var.app_name}-${var.environment}-api"
  retention_in_days = var.log_retention_days

  tags = {
    Service = "${var.app_name}-${var.environment}-api"
  }
}

resource "aws_cloudwatch_log_group" "ecs_worker" {
  name              = "/ecs/${var.app_name}-${var.environment}-worker"
  retention_in_days = var.log_retention_days

  tags = {
    Service = "${var.app_name}-${var.environment}-worker"
  }
}

resource "aws_cloudwatch_log_group" "aurora_logs" {
  name              = "/db/${var.app_name}-${var.environment}-aurora"
  retention_in_days = var.log_retention_days

  tags = {
    Service = "${var.app_name}-${var.environment}-aurora"
  }
}

resource "aws_cloudwatch_log_group" "alb_logs" {
  name              = "/alb/${var.app_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Service = "${var.app_name}-${var.environment}-alb"
  }
}
