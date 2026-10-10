resource "aws_sqs_queue" "core_mock_queue" {
  name                      = "core-mock-event-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400 # 1 día de retención
  receive_wait_time_seconds = 0

  tags = {
    Environment = "Test-Modulo2"
    Project     = var.project_name
  }
}