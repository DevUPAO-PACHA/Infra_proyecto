resource "aws_lb" "main" {
  name               = "${var.app_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    enabled = true
    prefix  = "load-balancer-logs"
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "api" {
  name        = "${var.app_name}-${var.environment}-tg"
  port        = var.app_port
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled  = true
    path     = "/actuator/health"
    protocol = "HTTPS"
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-api-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_s3_bucket" "lb_logs" {
  bucket = "${var.app_name}-${var.environment}-alb-logs" # Nombre del bucket

  tags = {
    Name = "${var.app_name}-${var.environment}-alb-logs"
  }
}

resource "aws_s3_bucket_policy" "lb_logs_policy" {
  bucket = aws_s3_bucket.lb_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSALBLogs"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::127311923021:root" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.lb_logs.arn}/*"
      }
    ]
  })
}
