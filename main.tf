# ==========================================
# 1. BASE DE DATOS (RDS PostgreSQL)
# ==========================================
resource "aws_security_group" "db_sg" {
  name        = "polizas_db_sg"
  description = "Permitir conexion a PostgreSQL desde tu Mac"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
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

# Buscamos dinámicamente la última versión de Java 17 disponible en AWS
data "aws_elastic_beanstalk_solution_stack" "java_17" {