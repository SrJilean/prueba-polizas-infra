# ==========================================
# 1. BASE DE DATOS (RDS PostgreSQL)
# ==========================================
resource "aws_security_group" "db_sg" {
  name        = "polizas_db_sg"
  description = "Permitir conexion a PostgreSQL"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permite conexión desde EB y desde tu Mac
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "polizas_db" {
  identifier             = "polizas-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "polizasdb"
  username               = "adminpolizas"
  password               = "PruebaTecnica2026!" 
  skip_final_snapshot    = true
  publicly_accessible    = true 
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

# ==========================================
# 2. BACKEND (AWS Elastic Beanstalk)
# ==========================================
# Rol necesario para que EC2 corra Beanstalk
resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role_polizas"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile_polizas"
  role = aws_iam_role.eb_ec2_role.name
}

# Aplicación y Entorno Java
resource "aws_elastic_beanstalk_application" "polizas_app" {
  name = "plataforma-polizas"
}

resource "aws_elastic_beanstalk_environment" "polizas_env" {
  name                = "plataforma-polizas-env"
  application         = aws_elastic_beanstalk_application.polizas_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.2.1 running Corretto 17" # Entorno Java 17

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  # Variables de entorno inyectadas al Spring Boot
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_DATASOURCE_URL"
    value     = "jdbc:postgresql://${aws_db_instance.polizas_db.endpoint}/${aws_db_instance.polizas_db.db_name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_DATASOURCE_USERNAME"
    value     = aws_db_instance.polizas_db.username
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_DATASOURCE_PASSWORD"
    value     = aws_db_instance.polizas_db.password
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVER_PORT"
    value     = "5000" # Beanstalk espera tráfico en el puerto 5000 por defecto
  }
}

# ==========================================
# 3. API GATEWAY (Apuntando al Backend)
# ==========================================
resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "polizas-api-gateway"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["api-key", "Content-Type"]
  }
}

resource "aws_apigatewayv2_integration" "eb_integration" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  integration_type   = "HTTP_PROXY"
  # Apuntamos dinámicamente a la URL del backend recién creado
  integration_uri    = "http://${aws_elastic_beanstalk_environment.polizas_env.cname}" 
  integration_method = "ANY"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.eb_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "$default"
  auto_deploy = true
}