
provider "aws" {
  region     = "ap-south-1"

}

# Create SG for RDS service
resource "aws_security_group" "sg_rds" {
  name        = "sg1"
  description = "security group for RDS"
ingress {
    description = "RDS Database Rule"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Use mysql service of aws 
resource "aws_db_instance" "mydb" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7.21"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "deep"
  password             = "redhat123"
  port                 = 3306
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  parameter_group_name = "default.mysql5.7"
  publicly_accessible = true
  skip_final_snapshot = true
  auto_minor_version_upgrade = false
  depends_on = [
    aws_security_group.sg_rds,
  ]
}




provider "kubernetes" {
  config_context_cluster = "minikube"
}
resource "kubernetes_service" "service" {
  metadata {
    name = "wordpress"
  }
  spec {
    selector = {
      app = "wordpress"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 80
      node_port = 30017
    }
type = "NodePort"
  }
}
resource "kubernetes_deployment" "deployment" {
  metadata {
    name = "wordpress"
    labels = {
      app = "wordpress"
    }
  }
spec {
    replicas = 2
selector {
      match_labels = {
        app = "wordpress"
      }
    }
template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }
spec {
        container {
          image = "wordpress"
          name  = "wordpress"
        }
      }
    }
  }
}


