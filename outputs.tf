output "api_gateway_url" {
  description = "URL pública de tu API Gateway en AWS"
  value       = aws_apigatewayv2_api.api_gateway.api_endpoint
}

output "rds_endpoint" {
  description = "Endpoint de conexion a la base de datos PostgreSQL"
  value       = aws_db_instance.polizas_db.endpoint
}