output "sqs_queue_url" {
  description = "URL de la cola SQS para conectar el Mock del CORE en Spring Boot"
  value       = aws_sqs_queue.core_mock_queue.url
}

# Variable temporal para enlazar el API Gateway con tu Spring Boot local
variable "backend_url" {
  description = "URL de tu backend (ej. URL de ngrok para desarrollo local)"
  type        = string
  default     = "http://localhost:8080" # La cambiaremos cuando levantes el backend
}

# 1. Creación del API Gateway (HTTP API - Más rápido y moderno)
resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "polizas-api-gateway"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["api-key", "Content-Type"]
  }
}

# 2. Integración: Hacia dónde envía el tráfico el API Gateway
resource "aws_apigatewayv2_integration" "backend_integration" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = "{var.backend_url}/{proxy}"
  integration_method = "ANY"
}

# 3. Ruta: Atrapa cualquier endpoint (/polizas, /renovar, etc)
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.backend_integration.id}"
}

# 4. Despliegue automático
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "$default"
  auto_deploy = true
}

output "api_gateway_url" {
  description = "URL pública de tu API Gateway en AWS"
  value       = aws_apigatewayv2_api.api_gateway.api_endpoint
}