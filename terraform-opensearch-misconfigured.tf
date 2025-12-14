# Intentionally Misconfigured OpenSearch Domain - FOR SECURITY TESTING ONLY
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
  region = "us-east-1"
}

# MISCONFIGURATION 1: Publicly accessible OpenSearch domain
resource "aws_opensearch_domain" "misconfigured_opensearch" {
  domain_name    = "misconfigured-opensearch-domain"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "gp3"
  }

  # MISCONFIGURATION: Publicly accessible endpoint
  # This allows anyone on the internet to access the OpenSearch domain
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "es:*"
        ]
        Resource = "arn:aws:es:us-east-1:*:domain/misconfigured-opensearch-domain/*"
      }
    ]
  })

  # MISCONFIGURATION 2: No encryption at rest
  encrypt_at_rest {
    enabled = false
  }

  # MISCONFIGURATION 3: No node-to-node encryption
  node_to_node_encryption {
    enabled = false
  }

  # MISCONFIGURATION 4: No encryption in transit (no HTTPS enforcement)
  domain_endpoint_options {
    enforce_https       = false
    tls_security_policy = "Policy-Min-TLS-1-0-2019-07"
  }

  # MISCONFIGURATION 5: No VPC configuration (publicly accessible)
  # When VPC options are not specified, the domain is publicly accessible

  # MISCONFIGURATION 6: Advanced security options disabled
  advanced_security_options {
    enabled                        = false
    internal_user_database_enabled = false
  }

  # MISCONFIGURATION 7: Audit logs disabled
  # Intentionally not configuring log_publishing_options to disable audit logging

  tags = {
    Name        = "MisconfiguredOpenSearch"
    Environment = "SecurityTesting"
    Purpose     = "Intentionally vulnerable for testing"
  }
}

# Output the endpoint
output "opensearch_endpoint" {
  value = aws_opensearch_domain.misconfigured_opensearch.endpoint
}

output "opensearch_domain_id" {
  value = aws_opensearch_domain.misconfigured_opensearch.domain_id
}

output "opensearch_arn" {
  value = aws_opensearch_domain.misconfigured_opensearch.arn
}

output "security_warnings" {
  value = "WARNING: This OpenSearch domain is intentionally misconfigured with public access, no encryption, and no VPC protection!"
}
