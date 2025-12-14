# Intentionally Misconfigured Amazon MSK Cluster - FOR SECURITY TESTING ONLY
# This file contains multiple security misconfigurations and should NOT be used in production

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets in different availability zones
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# MISCONFIGURATION 1: Security group allowing Kafka access from anywhere
resource "aws_security_group" "misconfigured_msk_sg" {
  name_prefix = "misconfigured-msk-sg-"
  vpc_id      = data.aws_vpc.default.id
  description = "Misconfigured security group allowing public access to MSK cluster"

  # Allow Kafka plaintext from anywhere (port 9092)
  ingress {
    description = "Kafka plaintext from anywhere"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Kafka TLS from anywhere (port 9094)
  ingress {
    description = "Kafka TLS from anywhere"
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Zookeeper from anywhere (port 2181)
  ingress {
    description = "Zookeeper from anywhere"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "MisconfiguredMSKSecurityGroup"
    Environment = "SecurityTesting"
    Purpose     = "Intentionally vulnerable for testing"
  }
}

# CloudWatch log group for MSK logs (optional, but good practice)
resource "aws_cloudwatch_log_group" "msk_logs" {
  name              = "/aws/msk/misconfigured-cluster"
  retention_in_days = 1

  tags = {
    Name        = "MisconfiguredMSKLogGroup"
    Environment = "SecurityTesting"
  }
}

# MISCONFIGURATION 2: MSK cluster with public access enabled
resource "aws_msk_cluster" "misconfigured_cluster" {
  cluster_name           = "misconfigured-msk-cluster"
  kafka_version          = "3.5.1"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type = "kafka.t3.small"
    client_subnets = slice(
      data.aws_subnets.default.ids,
      0,
      min(2, length(data.aws_subnets.default.ids))
    )
    
    # MISCONFIGURATION: Use overly permissive security group
    security_groups = [aws_security_group.misconfigured_msk_sg.id]

    storage_info {
      ebs_storage_info {
        volume_size = 10
        # MISCONFIGURATION: Unencrypted EBS volumes
      }
    }

    # CRITICAL MISCONFIGURATION: Public access enabled
    connectivity_info {
      public_access {
        type = "SERVICE_PROVIDED_EIPS"
      }
    }
  }

  # MISCONFIGURATION: Plaintext authentication enabled (no encryption in transit)
  client_authentication {
    unauthenticated = true
  }

  # MISCONFIGURATION: No encryption at rest
  encryption_info {
    encryption_at_rest_kms_key_arn = null
    
    encryption_in_transit {
      client_broker = "PLAINTEXT"
      in_cluster    = false
    }
  }

  # MISCONFIGURATION: Minimal logging enabled
  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = false
        log_group = null
      }
      firehose {
        enabled = false
      }
      s3 {
        enabled = false
      }
    }
  }

  # MISCONFIGURATION: Enhanced monitoring disabled
  enhanced_monitoring = "DEFAULT"

  tags = {
    Name        = "MisconfiguredMSKCluster"
    Environment = "SecurityTesting"
    Purpose     = "Intentionally vulnerable for testing"
    Account     = "13437518"
  }
}

# Output important information
output "cluster_arn" {
  value       = aws_msk_cluster.misconfigured_cluster.arn
  description = "ARN of the misconfigured MSK cluster"
}

output "bootstrap_brokers" {
  value       = aws_msk_cluster.misconfigured_cluster.bootstrap_brokers
  description = "Plaintext bootstrap brokers (INSECURE)"
}

output "bootstrap_brokers_public_tls" {
  value       = try(aws_msk_cluster.misconfigured_cluster.bootstrap_brokers_public_tls, "Not available")
  description = "Public TLS bootstrap brokers"
}

output "zookeeper_connect_string" {
  value       = aws_msk_cluster.misconfigured_cluster.zookeeper_connect_string
  description = "Zookeeper connection string"
}

output "security_warnings" {
  value = <<-EOT
    ⚠️  CRITICAL SECURITY WARNINGS ⚠️
    
    This MSK cluster is intentionally misconfigured with the following issues:
    
    1. ❌ PUBLIC ACCESS ENABLED - Cluster is accessible from the internet
    2. ❌ No encryption at rest
    3. ❌ Plaintext client communication (no TLS)
    4. ❌ No authentication required
    5. ❌ Security group allows access from 0.0.0.0/0
    6. ❌ Minimal logging enabled
    7. ❌ No enhanced monitoring
    8. ❌ Unencrypted EBS volumes
    
    DO NOT USE THIS CONFIGURATION IN PRODUCTION!
    This cluster is for security testing and educational purposes only.
  EOT
}
