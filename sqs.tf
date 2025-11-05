# --- 1. Dead Letter Queue (DLQ) ---
# Aquí caen los mensajes que fallan repetidamente.
resource "aws_sqs_queue" "reservas_dlq" {
  name = "reservas-dlq"

  tags = {
    Name = "reservas-dlq"
  }
}

# --- 2. Cola Principal de Reservas ---
resource "aws_sqs_queue" "reservas_queue" {
  name = "reservas-queue"

  # Política de "Redrive": Después de 3 intentos fallidos (maxReceiveCounts),
  # mueve el mensaje a la DLQ.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.reservas_dlq.arn
    maxReceiveCount    = 3
  })

  tags = {
    Name = "reservas-queue"
  }
}