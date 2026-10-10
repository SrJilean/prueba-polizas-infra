# 1. La cola SQS que ya creamos
resource "aws_sqs_queue" "core_mock_queue" {
  name                      = "core-mock-event-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0

  tags = {
    Environment = "Test-Modulo2"
    Project     = var.project_name
  }
}

# 2. Variable temporal para enlazar el API Gateway con tu Spring Boot local
variable "backend_url" {
  description = "URL de tu backend (ej. URL de ngrok para desarrollo local)"
  type        = string
  default     = "http://example.com" # URL temporal válida para pasar la validación de AWS
}

# 3. Creación del API Gateway proxy
resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "polizas-api-gateway"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["api-key", "Content-Type"]
  }
}

# 4. Integración: Hacia dónde envía el tráfico el API Gateway
resource "aws_apigatewayv2_integration" "backend_integration" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = "${var.backend_url}/{proxy}"
  integration_method = "ANY"
}

# 5. Ruta: Atrapa cualquier endpoint
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.backend_integration.id}"
}

# 6. Despliegue automático
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "$default"
  auto_deploy = true
}