# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access
2. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities
3. **terraform-opensearch-misconfigured.tf** - Misconfigured OpenSearch domain with public access

### CloudFormation Files
1. **cloudformation-sg-misconfig.yaml** - Misconfigured Security Group with overly permissive rules
2. **cloudformation-rds-misconfig.yaml** - Misconfigured RDS instance with public access
3. **cloudformation-opensearch-misconfig.yaml** - Misconfigured OpenSearch domain with public access

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

### OpenSearch Domain Misconfigurations
- ❌ Publicly accessible domain (no VPC configuration)
- ❌ Access policy allows public access (Principal: "*")
- ❌ No encryption at rest
- ❌ No node-to-node encryption
- ❌ HTTPS not enforced
- ❌ Weak TLS policy (TLS 1.0)
- ❌ Advanced security options disabled
- ❌ Fine-grained access control disabled
- ❌ Audit logging disabled
- ❌ No VPC protection

## Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform installed (for .tf files)
- CloudFormation access (for .yaml files)

### Terraform Deployment
```bash
# For S3 misconfigured bucket
cd /path/to/repo
terraform init
terraform apply -auto-approve terraform-s3-misconfigured.tf

# For EC2 misconfigured instance
cd /path/to/repo
terraform init
terraform apply -auto-approve terraform-ec2-misconfigured.tf

# For OpenSearch misconfigured domain
cd /path/to/repo
terraform init
terraform apply -auto-approve terraform-opensearch-misconfigured.tf
```

### CloudFormation Deployment
```bash
# For Security Group misconfigurations
aws cloudformation create-stack \
  --stack-name misconfigured-sg-stack \
  --template-body file://cloudformation-sg-misconfig.yaml

# For RDS misconfigurations
aws cloudformation create-stack \
  --stack-name misconfigured-rds-stack \
  --template-body file://cloudformation-rds-misconfig.yaml

# For OpenSearch misconfigurations
aws cloudformation create-stack \
  --stack-name misconfigured-opensearch-stack \
  --template-body file://cloudformation-opensearch-misconfig.yaml
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

# CloudFormation cleanup
aws cloudformation delete-stack --stack-name misconfigured-sg-stack
aws cloudformation delete-stack --stack-name misconfigured-rds-stack
aws cloudformation delete-stack --stack-name misconfigured-opensearch-stack
```

## Contributing

If you find additional misconfigurations that should be included or improvements to existing ones, please feel free to contribute via pull requests.

## License

This repository is for educational and testing purposes only. Use at your own risk.