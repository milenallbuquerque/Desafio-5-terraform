terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
  }
}

resource "aws_security_group" "api_sg" {
  name        = "desafio-5-api-sg"
  description = "Security group da API do Desafio 5"

  ingress {
    description = "Acesso a API Node.js"
    from_port   = 3000
    to_port     = 3000
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

resource "aws_instance" "api_server" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  security_groups = [aws_security_group.api_sg.name]

  user_data = <<-EOF
    #!/bin/bash

    apt-get update
    apt-get install -y nodejs npm

    mkdir -p /app/src/controllers
    mkdir -p /app/src/routes

    cat > /app/package.json <<'PACKAGE'
    ${file("${path.module}/package.json")}
    PACKAGE

    cat > /app/src/app.js <<'APP'
    ${file("${path.module}/src/app.js")}
    APP

    cat > /app/src/server.js <<'SERVER'
    ${file("${path.module}/src/server.js")}
    SERVER

    cat > /app/src/controllers/user.controller.js <<'CONTROLLER'
    ${file("${path.module}/src/controllers/user.controller.js")}
    CONTROLLER

    cat > /app/src/routes/user.routes.js <<'ROUTES'
    ${file("${path.module}/src/routes/user.routes.js")}
    ROUTES

    cd /app
    npm install

    nohup node src/server.js > /var/log/desafio-5.log 2>&1 &
  EOF

  tags = {
    Name = "desafio-5-api"
  }
}