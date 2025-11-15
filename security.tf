# --- 1. Security Group para el Load Balancer (ALB) ---
# Este es el "portero". Solo permite entrar tráfico web.
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Permite trafico HTTP/HTTPS al ALB"
  vpc_id      = aws_vpc.main.id

  # Entrada: Permite HTTP (puerto 80) desde cualquier lugar.
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

  # Salida: Permite todo el tráfico saliente.
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

# --- 2. Security Group para la API Fargate (Spring Boot) ---
# Este es el guardia de la API. Solo deja pasar al "portero" (ALB).
resource "aws_security_group" "fargate_api" {
  name        = "fargate-api-sg"
  description = "Permite trafico desde el ALB al puerto de la app"
  vpc_id      = aws_vpc.main.id

  # Entrada: Solo permite tráfico en el puerto de la app (8000)
  # Y *solamente* si viene del Security Group del ALB.
  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.alb.id]
  }

  # Salida: Permite todo (para hablar con NAT-GW, SQS, RDS, Secrets Manager)
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

# --- 3. Security Group para el Worker Fargate ---
# Este es un trabajador "tímido". No habla con nadie por delante.
resource "aws_security_group" "fargate_worker" {
  name        = "fargate-worker-sg"
  description = "SG para el worker de SQS"
  vpc_id      = aws_vpc.main.id

  # Entrada: SIN REGLAS. Nadie puede iniciar una conexión con él.
  # (Se vuelve "stateful" al permitir la salida).

  # Salida: Permite todo (para hablar con SQS, RDS, SES, Secrets Manager)
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

# --- 4. Security Group para la Base de Datos Aurora ---
# Este es el "castillo de datos". Solo Fargate (API y Worker) tienen la llave.
resource "aws_security_group" "rds" {
  name        = "rds-aurora-sg"
  description = "Permite conexiones a Aurora solo desde Fargate"
  vpc_id      = aws_vpc.main.id

  # Entrada: Permite el puerto de Aurora (3306) SOLO desde
  # el SG de la API y el SG del Worker.
  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [
      aws_security_group.fargate_api.id,
      aws_security_group.fargate_worker.id
    ]
  }

  # Salida: (Opcional, pero buena práctica) Limitar salida si es necesario.
  # Por ahora, permitir todo está bien ya que está en subred privada.
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