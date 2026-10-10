output "sqs_queue_url" {
  description = "URL de la cola SQS para conectar el Mock del CORE en Spring Boot"
  value       = aws_sqs_queue.core_mock_queue.url
}

output "api_gateway_url" {
  description = "URL pública de tu API Gateway en AWS"
  value       = aws_apigatewayv2_api.api_gateway.api_endpoint
}