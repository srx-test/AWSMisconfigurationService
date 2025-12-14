# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access
2. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities
3. **terraform-msk-misconfigured.tf** - Misconfigured Amazon MSK cluster with public access enabled

### CloudFormation Files
1. **cloudformation-s3-misconfigured.yaml** - Misconfigured S3 bucket using CloudFormation
2. **cloudformation-ec2-misconfigured.yaml** - Misconfigured EC2 instance using CloudFormation
3. **cloudformation-rds-misconfig.yaml** - Misconfigured RDS instance using CloudFormation
4. **cloudformation-sg-misconfig.yaml** - Misconfigured Security Groups using CloudFormation
5. **cloudformation-msk-misconfig.yaml** - Misconfigured Amazon MSK cluster using CloudFormation

### Remediation Scripts
1. **remediate-msk-public-access.py** - Python script to scan and report MSK clusters with public access

### Configuration Files
1. **aws-config-msk-public-access-rule.json** - AWS Config rule for MSK public access compliance checking

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

### Amazon MSK Cluster Misconfigurations
- ❌ Public access enabled (accessible from the internet)
- ❌ No encryption at rest
- ❌ Plaintext client communication (no TLS)
- ❌ No authentication required (unauthenticated access)
- ❌ Security group allows access from 0.0.0.0/0 on all Kafka ports
- ❌ Logging completely disabled
- ❌ No enhanced monitoring
- ❌ Unencrypted EBS volumes

### RDS Instance Misconfigurations
- ❌ Publicly accessible RDS instances
- ❌ No backup retention
- ❌ Deletion protection disabled
- ❌ Storage encryption disabled
- ❌ Security groups allowing database access from 0.0.0.0/0

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

# For MSK misconfigured cluster
terraform init
terraform plan -var-file="terraform-msk-misconfigured.tf"
terraform apply -var-file="terraform-msk-misconfigured.tf"
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

# For MSK misconfigured cluster
aws cloudformation create-stack \
  --stack-name misconfigured-msk-stack \
  --template-body file://cloudformation-msk-misconfig.yaml \
  --parameters ParameterKey=VpcId,ParameterValue=<your-vpc-id> \
               ParameterKey=SubnetIds,ParameterValue=<subnet-id-1>\\,<subnet-id-2>
```

### MSK Remediation Script
```bash
# Scan all MSK clusters for public access
python3 remediate-msk-public-access.py --region us-east-2 --scan-all

# Check a specific cluster
python3 remediate-msk-public-access.py --region us-east-2 --cluster-arn <cluster-arn>

# Dry run mode
python3 remediate-msk-public-access.py --region us-east-2 --scan-all --dry-run
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
2. **These resources will incur AWS charges** (especially MSK clusters which can be expensive)
3. **Public S3 buckets may be discovered and abused by attackers**
4. **EC2 instances with weak security groups are vulnerable to attacks**
5. **MSK clusters with public access expose Kafka streams to the internet**
6. **Always destroy resources after testing**: `terraform destroy` or `aws cloudformation delete-stack`
7. **Monitor your AWS bill and usage during testing**

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
aws cloudformation delete-stack --stack-name misconfigured-s3-stack
aws cloudformation delete-stack --stack-name misconfigured-ec2-stack
```

## Contributing

If you find additional misconfigurations that should be included or improvements to existing ones, please feel free to contribute via pull requests.

## License

This repository is for educational and testing purposes only. Use at your own risk.