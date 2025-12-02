
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Permite trafico HTTP/HTTPS al ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Entrada: (Opcional) Habilitar para HTTPS más adelante.
  # ingress {
  #   protocol    = "tcp"
  #   from_port   = 443
  #   to_port     = 443
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_security_group" "fargate_api" {
  name        = "fargate-api-sg"
  description = "Permite trafico desde el ALB al puerto de la app"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fargate-api-sg"
  }
}

resource "aws_security_group" "fargate_worker" {
  name        = "fargate-worker-sg"
  description = "SG para el worker de SQS"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fargate-worker-sg"
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-aurora-sg"
  description = "Permite conexiones a Aurora solo desde Fargate"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [
      aws_security_group.fargate_api.id,
      aws_security_group.fargate_worker.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-aurora-sg"
  }
}