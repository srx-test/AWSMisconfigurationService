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
    echo "  terraform-deploy-s3            Deploy misconfigured S3 bucket using Terraform"
    echo "  terraform-deploy-ec2           Deploy misconfigured EC2 instance using Terraform"
    echo "  terraform-deploy-asg-east-2    Deploy ASG with IMDSv2 in us-east-2 using Terraform"
    echo "  terraform-deploy-asg-west-2    Deploy ASG with IMDSv2 in us-west-2 using Terraform"
    echo "  terraform-destroy-s3           Destroy S3 Terraform resources"
    echo "  terraform-destroy-ec2          Destroy EC2 Terraform resources"
    echo "  terraform-destroy-asg-east-2   Destroy ASG in us-east-2 Terraform resources"
    echo "  terraform-destroy-asg-west-2   Destroy ASG in us-west-2 Terraform resources"
    echo "  cf-deploy-s3                   Deploy misconfigured S3 bucket using CloudFormation"
    echo "  cf-deploy-ec2                  Deploy misconfigured EC2 instance using CloudFormation"
    echo "  cf-deploy-asg                  Deploy ASG with IMDSv2 using CloudFormation"
    echo "  cf-destroy-s3                  Destroy S3 CloudFormation stack"
    echo "  cf-destroy-ec2                 Destroy EC2 CloudFormation stack"
    echo "  cf-destroy-asg                 Destroy ASG CloudFormation stack"
    echo "  verify-imdsv2                  Run IMDSv2 verification script"
    echo "  identify-non-imdsv2            Identify ASGs not using IMDSv2"
    echo "  help                           Show this help message"
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

terraform_deploy_asg_east_2() {
    echo "🚀 Deploying ASG with IMDSv2 enforcement in us-east-2 with Terraform..."
    if ! command -v terraform &> /dev/null; then
        echo "❌ Terraform is required but not installed."
        exit 1
    fi
    
    mkdir -p terraform-asg-east-2-work
    cp terraform-asg-imdsv2-us-east-2.tf terraform-asg-east-2-work/
    cd terraform-asg-east-2-work
    terraform init
    terraform plan
    echo ""
    echo "⚠️  This will create an Auto Scaling Group with IMDSv2 enforcement in us-east-2"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        terraform apply -auto-approve
        echo "✅ ASG deployed. Remember to destroy it when done!"
    else
        echo "Deployment cancelled."
    fi
    cd ..
}

terraform_deploy_asg_west_2() {
    echo "🚀 Deploying ASG with IMDSv2 enforcement in us-west-2 with Terraform..."
    if ! command -v terraform &> /dev/null; then
        echo "❌ Terraform is required but not installed."
        exit 1
    fi
    
    mkdir -p terraform-asg-west-2-work
    cp terraform-asg-imdsv2-us-west-2.tf terraform-asg-west-2-work/
    cd terraform-asg-west-2-work
    terraform init
    terraform plan
    echo ""
    echo "⚠️  This will create an Auto Scaling Group with IMDSv2 enforcement in us-west-2"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        terraform apply -auto-approve
        echo "✅ ASG deployed. Remember to destroy it when done!"
    else
        echo "Deployment cancelled."
    fi
    cd ..
}

terraform_destroy_asg_east_2() {
    echo "🗑️  Destroying ASG Terraform resources in us-east-2..."
    if [[ -d "terraform-asg-east-2-work" ]]; then
        cd terraform-asg-east-2-work
        terraform destroy -auto-approve
        cd ..
        rm -rf terraform-asg-east-2-work
        echo "✅ ASG resources destroyed."
    else
        echo "No ASG Terraform resources found to destroy."
    fi
}

terraform_destroy_asg_west_2() {
    echo "🗑️  Destroying ASG Terraform resources in us-west-2..."
    if [[ -d "terraform-asg-west-2-work" ]]; then
        cd terraform-asg-west-2-work
        terraform destroy -auto-approve
        cd ..
        rm -rf terraform-asg-west-2-work
        echo "✅ ASG resources destroyed."
    else
        echo "No ASG Terraform resources found to destroy."
    fi
}

cf_deploy_asg() {
    echo "🚀 Deploying ASG with IMDSv2 enforcement using CloudFormation..."
    echo ""
    echo "⚠️  This will create an Auto Scaling Group with IMDSv2 enforcement"
    read -p "Enter region (us-east-2 or us-west-2): " region
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        aws cloudformation create-stack \
            --region "$region" \
            --stack-name imdsv2-asg-stack \
            --template-body file://cloudformation-asg-imdsv2.yaml
        echo "✅ CloudFormation stack deployment initiated. Check AWS console for progress."
        echo "✅ Remember to destroy the stack when done!"
    else
        echo "Deployment cancelled."
    fi
}

cf_destroy_asg() {
    echo "🗑️  Destroying ASG CloudFormation stack..."
    read -p "Enter region (us-east-2 or us-west-2): " region
    aws cloudformation delete-stack --region "$region" --stack-name imdsv2-asg-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

verify_imdsv2() {
    echo "🔍 Running IMDSv2 verification script..."
    if [[ -f "verify-imdsv2-enforcement.sh" ]]; then
        ./verify-imdsv2-enforcement.sh "$@"
    else
        echo "❌ verify-imdsv2-enforcement.sh not found"
        exit 1
    fi
}

identify_non_imdsv2() {
    echo "🔍 Identifying ASGs not using IMDSv2..."
    if [[ -f "identify-non-imdsv2-asgs.sh" ]]; then
        ./identify-non-imdsv2-asgs.sh "$@"
    else
        echo "❌ identify-non-imdsv2-asgs.sh not found"
        exit 1
    fi
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
    terraform-deploy-asg-east-2)
        check_requirements
        terraform_deploy_asg_east_2
        ;;
    terraform-deploy-asg-west-2)
        check_requirements
        terraform_deploy_asg_west_2
        ;;
    terraform-destroy-s3)
        check_requirements
        terraform_destroy_s3
        ;;
    terraform-destroy-ec2)
        check_requirements
        terraform_destroy_ec2
        ;;
    terraform-destroy-asg-east-2)
        check_requirements
        terraform_destroy_asg_east_2
        ;;
    terraform-destroy-asg-west-2)
        check_requirements
        terraform_destroy_asg_west_2
        ;;
    cf-deploy-s3)
        check_requirements
        cf_deploy_s3
        ;;
    cf-deploy-ec2)
        check_requirements
        cf_deploy_ec2
        ;;
    cf-deploy-asg)
        check_requirements
        cf_deploy_asg
        ;;
    cf-destroy-s3)
        check_requirements
        cf_destroy_s3
        ;;
    cf-destroy-ec2)
        check_requirements
        cf_destroy_ec2
        ;;
    cf-destroy-asg)
        check_requirements
        cf_destroy_asg
        ;;
    verify-imdsv2)
        check_requirements
        shift
        verify_imdsv2 "$@"
        ;;
    identify-non-imdsv2)
        check_requirements
        shift
        identify_non_imdsv2 "$@"
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