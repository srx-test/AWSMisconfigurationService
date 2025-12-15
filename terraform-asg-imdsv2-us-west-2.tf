# Auto Scaling Group with IMDSv2 Enforcement - us-west-2
# This file demonstrates proper IMDSv2 configuration for security testing
# Account: 222634381402
# Region: us-west-2

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Get default VPC
data "aws_vpc" "default_west" {
  default = true
}

# Get default subnets in us-west-2
data "aws_subnets" "default_west" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_west.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Security group for ASG instances
resource "aws_security_group" "asg_sg_west" {
  name_prefix = "asg-imdsv2-sg-west-"
  description = "Security group for ASG with IMDSv2 in us-west-2"
  vpc_id      = data.aws_vpc.default_west.id

  # Allow HTTP from anywhere (for testing)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere (for testing)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
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
    Name        = "ASG-IMDSv2-SecurityGroup"
    Environment = "SecurityTesting"
    Region      = "us-west-2"
    Purpose     = "ASG with IMDSv2 enforcement"
  }
}

# Get latest Amazon Linux 2 AMI for us-west-2
data "aws_ami" "amazon_linux_west" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Launch template with IMDSv2 enforcement
resource "aws_launch_template" "imdsv2_template_west" {
  name_prefix   = "imdsv2-enforced-template-west-"
  description   = "Launch template with IMDSv2 enforcement for us-west-2"
  image_id      = data.aws_ami.amazon_linux_west.id
  instance_type = "t2.micro"

  # SECURITY BEST PRACTICE: IMDSv2 required
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # This enforces IMDSv2
    http_put_response_hop_limit = 1           # Recommended security setting
  }

  vpc_security_group_ids = [aws_security_group.asg_sg_west.id]

  # User data to demonstrate metadata access
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    
    # Create a simple web page showing IMDSv2 usage
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>IMDSv2 Enforced Instance</title>
    </head>
    <body>
        <h1>IMDSv2 Enforced Auto Scaling Group Instance</h1>
        <p>This instance is part of an Auto Scaling Group with IMDSv2 enforcement.</p>
        <p>Region: us-west-2</p>
        <h2>Testing IMDSv2 Access</h2>
        <p>To test metadata access, SSH to this instance and run:</p>
        <pre>
# This will FAIL (IMDSv1)
curl http://169.254.169.254/latest/meta-data/instance-id

# This will SUCCEED (IMDSv2)
TOKEN=\$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/instance-id
        </pre>
    </body>
    </html>
HTML
  EOF
  )

  # Encrypted EBS volume (security best practice)
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # Enable detailed monitoring
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "ASG-IMDSv2-Instance"
      Environment = "SecurityTesting"
      Region      = "us-west-2"
      IMDSVersion = "v2-required"
    }
  }

  tags = {
    Name        = "ASG-IMDSv2-LaunchTemplate"
    Environment = "SecurityTesting"
    Region      = "us-west-2"
  }
}

# Auto Scaling Group with the launch template
resource "aws_autoscaling_group" "imdsv2_asg_west" {
  name                = "imdsv2-enforced-asg-us-west-2"
  vpc_zone_identifier = data.aws_subnets.default_west.ids
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  health_check_type   = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.imdsv2_template_west.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ASG-IMDSv2-Instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "SecurityTesting"
    propagate_at_launch = true
  }

  tag {
    key                 = "Region"
    value               = "us-west-2"
    propagate_at_launch = true
  }

  tag {
    key                 = "IMDSVersion"
    value               = "v2-required"
    propagate_at_launch = true
  }
}

# Outputs
output "launch_template_id_west" {
  description = "ID of the launch template with IMDSv2 enforcement in us-west-2"
  value       = aws_launch_template.imdsv2_template_west.id
}

output "launch_template_latest_version_west" {
  description = "Latest version of the launch template in us-west-2"
  value       = aws_launch_template.imdsv2_template_west.latest_version
}

output "autoscaling_group_name_west" {
  description = "Name of the Auto Scaling Group in us-west-2"
  value       = aws_autoscaling_group.imdsv2_asg_west.name
}

output "autoscaling_group_arn_west" {
  description = "ARN of the Auto Scaling Group in us-west-2"
  value       = aws_autoscaling_group.imdsv2_asg_west.arn
}

output "security_group_id_west" {
  description = "Security group ID for ASG instances in us-west-2"
  value       = aws_security_group.asg_sg_west.id
}

output "verification_instructions_west" {
  description = "Instructions for verifying IMDSv2 enforcement in us-west-2"
  value       = <<-EOT
    
    ===== IMDSv2 Verification Instructions (us-west-2) =====
    
    1. Wait for instances to launch in the Auto Scaling Group
    2. Get the instance ID from the ASG
    3. Connect to the instance via SSM or EC2 Instance Connect
    4. Run these commands to verify IMDSv2 enforcement:
    
    # This should FAIL (IMDSv1 not allowed):
    curl http://169.254.169.254/latest/meta-data/instance-id
    
    # This should SUCCEED (IMDSv2):
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id
    
    ============================================
  EOT
}
