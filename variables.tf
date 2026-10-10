variable "aws_region" {
  description = "Región de AWS para el despliegue"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto para etiquetado"
  type        = string
  default     = "Prueba-Tecnica-Polizas"
}