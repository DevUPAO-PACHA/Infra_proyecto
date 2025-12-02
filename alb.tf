# --- 1. Application Load Balancer (ALB) ---
resource "aws_lb" "main" {
  name               = "mi-app-alb"
  internal           = false # Es público
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id] # El SG que ya creamos
  subnets            = aws_subnet.public.*.id      # Vive en las subredes PÚBLICAS

  tags = {
    Name = "${var.app_name}-alb"
  }
}

# --- 2. Target Group (TG) ---
# El ALB no envía tráfico a Fargate, lo envía a un "grupo".
# Fargate se registra en este grupo.
resource "aws_lb_target_group" "api" {
  name        = "${var.app_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled = true
    path    = "/actuator/health"
    protocol = "HTTP"
  }

  tags = {
    Name = "api-fargate-tg"
  }
}

# --- 3. Listener del ALB ---
# Escucha en el puerto 80 (HTTP) y reenvía el tráfico al Target Group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.api.arn 
  }
}
/* Esto es solo por si fuera con dominio real pero no hay pue :c
resource "aws_lb_listener" "https" { 
  load_balancer_arn = aws_lb.main.arn 
  port = 443 
  protocol = "HTTPS"
  default_action { 
    type = "forward" 
    target_group_arn = aws_lb_target_group.api.arn 
  } 
}*/