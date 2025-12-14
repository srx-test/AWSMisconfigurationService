#!/bin/bash

# AWS Misconfiguration Test Deployment Script
# WARNING: This script deploys intentionally vulnerable infrastructure
# DO NOT USE IN PRODUCTION

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "AWS Misconfiguration Test Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  terraform-deploy-s3     Deploy misconfigured S3 bucket using Terraform"
    echo "  terraform-deploy-ec2    Deploy misconfigured EC2 instance using Terraform"
    echo "  terraform-deploy-msk    Deploy misconfigured MSK cluster using Terraform"
    echo "  terraform-destroy-s3    Destroy S3 Terraform resources"
    echo "  terraform-destroy-ec2   Destroy EC2 Terraform resources"
    echo "  terraform-destroy-msk   Destroy MSK Terraform resources"
    echo "  cf-deploy-s3           Deploy misconfigured S3 bucket using CloudFormation"
    echo "  cf-deploy-ec2          Deploy misconfigured EC2 instance using CloudFormation"
    echo "  cf-deploy-msk          Deploy misconfigured MSK cluster using CloudFormation"
    echo "  cf-destroy-s3          Destroy S3 CloudFormation stack"
    echo "  cf-destroy-ec2         Destroy EC2 CloudFormation stack"
    echo "  cf-destroy-msk         Destroy MSK CloudFormation stack"
    echo "  help                   Show this help message"
    echo ""
    echo "⚠️  WARNING: These resources are intentionally misconfigured and vulnerable!"
    echo "⚠️  Always destroy resources after testing to avoid charges and security risks!"
}

check_requirements() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is required but not installed."
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        echo "❌ AWS CLI is not configured or credentials are invalid."
        echo "Run 'aws configure' to set up your credentials."
        exit 1
    fi
}

terraform_deploy_s3() {
    echo "🚀 Deploying misconfigured S3 bucket with Terraform..."
    if ! command -v terraform &> /dev/null; then
        echo "❌ Terraform is required but not installed."
        exit 1
    fi
    
    mkdir -p terraform-s3-work
    cp terraform-s3-misconfigured.tf terraform-s3-work/
    cd terraform-s3-work
    terraform init
    terraform plan
    echo ""
    echo "⚠️  WARNING: This will create a PUBLICLY ACCESSIBLE S3 bucket!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        terraform apply -auto-approve
        echo "✅ S3 bucket deployed. Remember to destroy it when done!"
    else
        echo "Deployment cancelled."
    fi
    cd ..
}

terraform_deploy_ec2() {
    echo "🚀 Deploying misconfigured EC2 instance with Terraform..."
    if ! command -v terraform &> /dev/null; then
        echo "❌ Terraform is required but not installed."
        exit 1
    fi
    
    mkdir -p terraform-ec2-work
    cp terraform-ec2-misconfigured.tf terraform-ec2-work/
    cd terraform-ec2-work
    terraform init
    terraform plan
    echo ""
    echo "⚠️  WARNING: This will create a PUBLICLY ACCESSIBLE EC2 instance with weak security!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        terraform apply -auto-approve
        echo "✅ EC2 instance deployed. Remember to destroy it when done!"
    else
        echo "Deployment cancelled."
    fi
    cd ..
}

terraform_deploy_msk() {
    echo "🚀 Deploying misconfigured MSK cluster with Terraform..."
    if ! command -v terraform &> /dev/null; then
        echo "❌ Terraform is required but not installed."
        exit 1
    fi
    
    mkdir -p terraform-msk-work
    cp terraform-msk-misconfigured.tf terraform-msk-work/
    cd terraform-msk-work
    terraform init
    terraform plan
    echo ""
    echo "⚠️  CRITICAL WARNING: This will create an MSK cluster with PUBLIC ACCESS!"
    echo "⚠️  MSK clusters can be EXPENSIVE - charges will apply immediately!"
    echo "⚠️  Public MSK clusters expose Kafka streams to the internet!"
    read -p "Are you ABSOLUTELY sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        terraform apply -auto-approve
        echo "✅ MSK cluster deployment initiated. This may take 20-30 minutes."
        echo "⚠️  Remember to destroy it when done to avoid high charges!"
    else
        echo "Deployment cancelled."
    fi
    cd ..
}

terraform_destroy_s3() {
    echo "🗑️  Destroying S3 Terraform resources..."
    if [[ -d "terraform-s3-work" ]]; then
        cd terraform-s3-work
        terraform destroy -auto-approve
        cd ..
        rm -rf terraform-s3-work
        echo "✅ S3 resources destroyed."
    else
        echo "No S3 Terraform resources found to destroy."
    fi
}

terraform_destroy_ec2() {
    echo "🗑️  Destroying EC2 Terraform resources..."
    if [[ -d "terraform-ec2-work" ]]; then
        cd terraform-ec2-work
        terraform destroy -auto-approve
        cd ..
        rm -rf terraform-ec2-work
        echo "✅ EC2 resources destroyed."
    else
        echo "No EC2 Terraform resources found to destroy."
    fi
}

terraform_destroy_msk() {
    echo "🗑️  Destroying MSK Terraform resources..."
    if [[ -d "terraform-msk-work" ]]; then
        cd terraform-msk-work
        echo "⚠️  This will destroy the MSK cluster. Deletion may take 10-15 minutes."
        terraform destroy -auto-approve
        cd ..
        rm -rf terraform-msk-work
        echo "✅ MSK resources destroyed."
    else
        echo "No MSK Terraform resources found to destroy."
    fi
}

cf_deploy_s3() {
    echo "🚀 Deploying misconfigured S3 bucket with CloudFormation..."
    echo ""
    echo "⚠️  WARNING: This will create a PUBLICLY ACCESSIBLE S3 bucket!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        aws cloudformation create-stack \
            --stack-name misconfigured-s3-stack \
            --template-body file://cloudformation-s3-misconfigured.yaml
        echo "✅ CloudFormation stack deployment initiated. Check AWS console for progress."
        echo "✅ Remember to destroy the stack when done!"
    else
        echo "Deployment cancelled."
    fi
}

cf_deploy_ec2() {
    echo "🚀 Deploying misconfigured EC2 instance with CloudFormation..."
    echo ""
    echo "⚠️  WARNING: This will create a PUBLICLY ACCESSIBLE EC2 instance with weak security!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        aws cloudformation create-stack \
            --stack-name misconfigured-ec2-stack \
            --template-body file://cloudformation-ec2-misconfigured.yaml \
            --capabilities CAPABILITY_NAMED_IAM
        echo "✅ CloudFormation stack deployment initiated. Check AWS console for progress."
        echo "✅ Remember to destroy the stack when done!"
    else
        echo "Deployment cancelled."
    fi
}

cf_deploy_msk() {
    echo "🚀 Deploying misconfigured MSK cluster with CloudFormation..."
    echo ""
    echo "You need to provide VPC ID and at least 2 Subnet IDs in different AZs."
    read -p "Enter VPC ID: " vpc_id
    read -p "Enter Subnet ID 1: " subnet_1
    read -p "Enter Subnet ID 2: " subnet_2
    echo ""
    echo "⚠️  CRITICAL WARNING: This will create an MSK cluster with PUBLIC ACCESS!"
    echo "⚠️  MSK clusters can be EXPENSIVE - charges will apply immediately!"
    echo "⚠️  Public MSK clusters expose Kafka streams to the internet!"
    read -p "Are you ABSOLUTELY sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        aws cloudformation create-stack \
            --stack-name misconfigured-msk-stack \
            --template-body file://cloudformation-msk-misconfig.yaml \
            --parameters ParameterKey=VpcId,ParameterValue="$vpc_id" \
                         ParameterKey=SubnetIds,ParameterValue="$subnet_1,$subnet_2"
        echo "✅ CloudFormation stack deployment initiated. This may take 20-30 minutes."
        echo "✅ Check AWS console for progress."
        echo "⚠️  Remember to destroy the stack when done to avoid high charges!"
    else
        echo "Deployment cancelled."
    fi
}

cf_destroy_s3() {
    echo "🗑️  Destroying S3 CloudFormation stack..."
    aws cloudformation delete-stack --stack-name misconfigured-s3-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

cf_destroy_ec2() {
    echo "🗑️  Destroying EC2 CloudFormation stack..."
    aws cloudformation delete-stack --stack-name misconfigured-ec2-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

cf_destroy_msk() {
    echo "🗑️  Destroying MSK CloudFormation stack..."
    echo "⚠️  This will destroy the MSK cluster. Deletion may take 10-15 minutes."
    aws cloudformation delete-stack --stack-name misconfigured-msk-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

# Main script logic
case "${1:-help}" in
    terraform-deploy-s3)
        check_requirements
        terraform_deploy_s3
        ;;
    terraform-deploy-ec2)
        check_requirements
        terraform_deploy_ec2
        ;;
    terraform-deploy-msk)
        check_requirements
        terraform_deploy_msk
        ;;
    terraform-destroy-s3)
        check_requirements
        terraform_destroy_s3
        ;;
    terraform-destroy-ec2)
        check_requirements
        terraform_destroy_ec2
        ;;
    terraform-destroy-msk)
        check_requirements
        terraform_destroy_msk
        ;;
    cf-deploy-s3)
        check_requirements
        cf_deploy_s3
        ;;
    cf-deploy-ec2)
        check_requirements
        cf_deploy_ec2
        ;;
    cf-deploy-msk)
        check_requirements
        cf_deploy_msk
        ;;
    cf-destroy-s3)
        check_requirements
        cf_destroy_s3
        ;;
    cf-destroy-ec2)
        check_requirements
        cf_destroy_ec2
        ;;
    cf-destroy-msk)
        check_requirements
        cf_destroy_msk
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac