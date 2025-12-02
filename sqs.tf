
resource "aws_sqs_queue" "reservas_dlq" {
  name = "reservas-dlq"

  tags = {
    Name = "reservas-dlq"
  }
}

resource "aws_sqs_queue" "reservas_queue" {
  name = "reservas-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.reservas_dlq.arn
    maxReceiveCount    = 3
  })

  tags = {
    Name = "reservas-queue"
  }
}