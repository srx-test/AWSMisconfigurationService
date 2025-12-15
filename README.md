# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access
2. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities
3. **terraform-asg-imdsv2-us-east-2.tf** - Auto Scaling Group with IMDSv2 enforcement in us-east-2 (SECURE)
4. **terraform-asg-imdsv2-us-west-2.tf** - Auto Scaling Group with IMDSv2 enforcement in us-west-2 (SECURE)

### CloudFormation Files
1. **cloudformation-s3-misconfigured.yaml** - Misconfigured S3 bucket using CloudFormation
2. **cloudformation-ec2-misconfigured.yaml** - Misconfigured EC2 instance using CloudFormation
3. **cloudformation-sg-misconfig.yaml** - Misconfigured Security Group using CloudFormation
4. **cloudformation-rds-misconfig.yaml** - Misconfigured RDS instance using CloudFormation
5. **cloudformation-asg-imdsv2.yaml** - Auto Scaling Group with IMDSv2 enforcement (SECURE)

### Security Scripts
1. **identify-non-imdsv2-asgs.sh** - Script to identify Auto Scaling Groups not using IMDSv2
2. **verify-imdsv2-enforcement.sh** - Script to verify IMDSv2 enforcement on EC2 instances

## Security Misconfigurations Included

### S3 Bucket Misconfigurations
- ❌ Public access block disabled
- ❌ Public read/write ACL permissions
- ❌ No server-side encryption
- ❌ Versioning disabled
- ❌ No access logging
- ❌ Public bucket policy allowing full access
- ❌ No lifecycle policies
- ❌ No CloudTrail monitoring

### EC2 Instance Misconfigurations
- ❌ Security groups allowing access from 0.0.0.0/0 on multiple ports (SSH, RDP, HTTP, HTTPS, databases)
- ❌ IAM roles with excessive permissions (PowerUserAccess, IAMFullAccess)
- ❌ Hardcoded credentials in user data
- ❌ Unencrypted EBS volumes
- ❌ IMDSv1 enabled (vulnerable to SSRF attacks)
- ❌ No detailed monitoring
- ❌ Public IP assignment
- ❌ Weak user passwords
- ❌ SSH password authentication enabled
- ❌ Firewall disabled
- ❌ Sudo access without password requirements
- ❌ Sensitive information exposed via web interface

### Auto Scaling Group - IMDSv2 Enforcement (SECURE CONFIGURATION)
- ✅ IMDSv2 required (http_tokens = "required")
- ✅ Encrypted EBS volumes
- ✅ Detailed monitoring enabled
- ✅ Proper metadata options configured (http_put_response_hop_limit = 1)
- ✅ Launch template with security best practices
- ✅ Multi-region support (us-east-2 and us-west-2)

## Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform installed (for .tf files)
- CloudFormation access (for .yaml files)

### Terraform Deployment
```bash
# For S3 misconfigured bucket
terraform init
terraform plan -var-file="terraform-s3-misconfigured.tf"
terraform apply -var-file="terraform-s3-misconfigured.tf"

# For EC2 misconfigured instance
terraform init
terraform plan -var-file="terraform-ec2-misconfigured.tf"
terraform apply -var-file="terraform-ec2-misconfigured.tf"

# For Auto Scaling Group with IMDSv2 in us-east-2 (SECURE)
terraform init
terraform plan -var-file="terraform-asg-imdsv2-us-east-2.tf"
terraform apply -var-file="terraform-asg-imdsv2-us-east-2.tf"

# For Auto Scaling Group with IMDSv2 in us-west-2 (SECURE)
terraform init
terraform plan -var-file="terraform-asg-imdsv2-us-west-2.tf"
terraform apply -var-file="terraform-asg-imdsv2-us-west-2.tf"
```

### CloudFormation Deployment
```bash
# For S3 misconfigured bucket
aws cloudformation create-stack \
  --stack-name misconfigured-s3-stack \
  --template-body file://cloudformation-s3-misconfigured.yaml

# For EC2 misconfigured instance
aws cloudformation create-stack \
  --stack-name misconfigured-ec2-stack \
  --template-body file://cloudformation-ec2-misconfigured.yaml \
  --capabilities CAPABILITY_NAMED_IAM

# For Auto Scaling Group with IMDSv2 (SECURE)
aws cloudformation create-stack \
  --region us-east-2 \
  --stack-name imdsv2-asg-stack \
  --template-body file://cloudformation-asg-imdsv2.yaml
```

### Using the Deployment Script
```bash
# Make the script executable
chmod +x deploy.sh

# Deploy Auto Scaling Group with IMDSv2 in us-east-2
./deploy.sh terraform-deploy-asg-east-2

# Deploy Auto Scaling Group with IMDSv2 in us-west-2
./deploy.sh terraform-deploy-asg-west-2

# Deploy using CloudFormation
./deploy.sh cf-deploy-asg

# Identify ASGs not using IMDSv2
./deploy.sh identify-non-imdsv2 -r us-east-2

# Verify IMDSv2 enforcement
./deploy.sh verify-imdsv2 -a imdsv2-enforced-asg-us-east-2 -r us-east-2
```

## Security Testing Tools

These misconfigurations can be detected by various security scanning tools:
- **AWS Config Rules**
- **AWS Security Hub**
- **AWS Inspector**
- **Scout Suite**
- **Prowler**
- **CloudSploit**
- **Checkov**
- **Terrascan**
- **tfsec**

## ⚠️ Important Warnings

1. **DO NOT deploy these in production environments**
2. **These resources will incur AWS charges**
3. **Public S3 buckets may be discovered and abused by attackers**
4. **EC2 instances with weak security groups are vulnerable to attacks**
5. **Always destroy resources after testing**: `terraform destroy` or `aws cloudformation delete-stack`
6. **Monitor your AWS bill and usage during testing**

## Educational Use Cases

- Security training and awareness
- Penetration testing practice
- Security tool validation
- Infrastructure security scanning
- DevSecOps pipeline testing
- Compliance testing

## Cleanup

Always remember to clean up resources after testing:

```bash
# Terraform cleanup
terraform destroy

# Using the deployment script
./deploy.sh terraform-destroy-asg-east-2
./deploy.sh terraform-destroy-asg-west-2

# CloudFormation cleanup
aws cloudformation delete-stack --stack-name misconfigured-s3-stack
aws cloudformation delete-stack --stack-name misconfigured-ec2-stack
aws cloudformation delete-stack --region us-east-2 --stack-name imdsv2-asg-stack

# Using the deployment script
./deploy.sh cf-destroy-asg
```

## IMDSv2 Enforcement and Verification

### What is IMDSv2?
Instance Metadata Service Version 2 (IMDSv2) is a security enhancement that helps protect against Server-Side Request Forgery (SSRF) attacks. It requires a session token to access instance metadata, making it significantly more secure than IMDSv1.

### Remediation Steps for Existing ASGs
1. **Identify non-compliant ASGs**: Run `./deploy.sh identify-non-imdsv2 -r us-east-2`
2. **Update launch templates**: Set `http_tokens = "required"` in metadata_options
3. **Update Auto Scaling groups**: Associate the updated launch template
4. **Replace existing instances**: Perform instance refresh or rolling replacement
5. **Verify enforcement**: Run `./deploy.sh verify-imdsv2 -a <asg-name> -r <region>`

### Testing IMDSv2 Enforcement
Once instances are launched, connect to them and test:

```bash
# This should FAIL (IMDSv1 not allowed):
curl http://169.254.169.254/latest/meta-data/instance-id

# This should SUCCEED (IMDSv2):
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id
```

### Scripts Included
- **identify-non-imdsv2-asgs.sh**: Scans AWS accounts to find ASGs not using IMDSv2
- **verify-imdsv2-enforcement.sh**: Verifies IMDSv2 enforcement on running instances

## Contributing

If you find additional misconfigurations that should be included or improvements to existing ones, please feel free to contribute via pull requests.

## License

This repository is for educational and testing purposes only. Use at your own risk.