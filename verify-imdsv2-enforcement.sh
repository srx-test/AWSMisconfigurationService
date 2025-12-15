#!/bin/bash

# Script to verify IMDSv2 enforcement on EC2 instances
# This script tests both IMDSv1 and IMDSv2 access to confirm proper configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo "IMDSv2 Enforcement Verification Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --instance-id ID   EC2 instance ID to verify"
    echo "  -r, --region REGION    AWS region (default: us-east-2)"
    echo "  -a, --asg-name NAME    Auto Scaling Group name to verify all instances"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -i i-1234567890abcdef0                          # Verify specific instance"
    echo "  $0 -a imdsv2-enforced-asg-us-east-2 -r us-east-2  # Verify all instances in ASG"
    echo ""
    echo "Note: This script uses SSM to run commands. Ensure instances have SSM agent installed."
}

check_requirements() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is required but not installed.${NC}"
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not configured or credentials are invalid.${NC}"
        echo "Run 'aws configure' to set up your credentials."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠️  jq is not installed. Using AWS CLI text output for JSON parsing.${NC}"
        HAS_JQ=false
    else
        HAS_JQ=true
    fi
}

verify_instance_imdsv2() {
    local instance_id=$1
    local region=$2
    
    echo -e "${BLUE}Verifying IMDSv2 enforcement on instance: $instance_id${NC}"
    
    # Check if instance exists and is running
    local instance_state=$(aws ec2 describe-instances \
        --region "$region" \
        --instance-ids "$instance_id" \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text 2>/dev/null)
    
    if [[ -z "$instance_state" || "$instance_state" == "None" ]]; then
        echo -e "${RED}❌ Instance $instance_id not found in region $region${NC}"
        return 1
    fi
    
    if [[ "$instance_state" != "running" ]]; then
        echo -e "${YELLOW}⚠️  Instance $instance_id is not running (state: $instance_state)${NC}"
        return 1
    fi
    
    # Check instance metadata options from EC2 API
    echo -e "${BLUE}Checking metadata options from EC2 API...${NC}"
    local metadata_options=$(aws ec2 describe-instances \
        --region "$region" \
        --instance-ids "$instance_id" \
        --query 'Reservations[0].Instances[0].MetadataOptions' \
        --output json)
    
    # Parse JSON using jq if available, otherwise use AWS CLI query directly
    if [[ "$HAS_JQ" == true ]]; then
        local http_tokens=$(echo "$metadata_options" | jq -r '.HttpTokens // "unknown"')
        local http_endpoint=$(echo "$metadata_options" | jq -r '.HttpEndpoint // "unknown"')
    else
        # Fallback: use AWS CLI query directly for more reliable parsing
        local http_tokens=$(aws ec2 describe-instances \
            --region "$region" \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].MetadataOptions.HttpTokens' \
            --output text 2>/dev/null || echo "unknown")
        local http_endpoint=$(aws ec2 describe-instances \
            --region "$region" \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].MetadataOptions.HttpEndpoint' \
            --output text 2>/dev/null || echo "unknown")
    fi
    
    echo -e "  HttpEndpoint: ${YELLOW}$http_endpoint${NC}"
    echo -e "  HttpTokens: ${YELLOW}$http_tokens${NC}"
    
    if [[ "$http_tokens" == "required" ]]; then
        echo -e "${GREEN}✅ IMDSv2 is REQUIRED (Compliant)${NC}"
    elif [[ "$http_tokens" == "optional" ]]; then
        echo -e "${RED}❌ IMDSv2 is OPTIONAL (Non-Compliant)${NC}"
    else
        echo -e "${YELLOW}⚠️  IMDSv2 status unknown${NC}"
    fi
    
    # Try to run verification commands using SSM
    echo ""
    echo -e "${BLUE}Testing metadata access from within the instance...${NC}"
    
    # Test IMDSv1 (should fail if IMDSv2 is enforced)
    echo -e "${YELLOW}Testing IMDSv1 access (should fail if properly configured)...${NC}"
    local imdsv1_result=$(aws ssm send-command \
        --region "$region" \
        --instance-ids "$instance_id" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["timeout 5 curl -s http://169.254.169.254/latest/meta-data/instance-id || echo FAILED"]' \
        --query 'Command.CommandId' \
        --output text 2>/dev/null)
    
    if [[ -n "$imdsv1_result" && "$imdsv1_result" != "None" ]]; then
        sleep 3
        local imdsv1_output=$(aws ssm get-command-invocation \
            --region "$region" \
            --command-id "$imdsv1_result" \
            --instance-id "$instance_id" \
            --query 'StandardOutputContent' \
            --output text 2>/dev/null)
        
        if [[ "$imdsv1_output" == *"FAILED"* ]] || [[ -z "$imdsv1_output" ]]; then
            echo -e "${GREEN}  ✅ IMDSv1 access blocked (as expected)${NC}"
        else
            echo -e "${RED}  ❌ IMDSv1 access succeeded (vulnerability!)${NC}"
            echo -e "     Output: $imdsv1_output"
        fi
    else
        echo -e "${YELLOW}  ⚠️  Could not test IMDSv1 (SSM may not be available)${NC}"
    fi
    
    # Test IMDSv2 (should succeed)
    echo -e "${YELLOW}Testing IMDSv2 access (should succeed)...${NC}"
    local imdsv2_result=$(aws ssm send-command \
        --region "$region" \
        --instance-ids "$instance_id" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["TOKEN=$(curl -X PUT \"http://169.254.169.254/latest/api/token\" -H \"X-aws-ec2-metadata-token-ttl-seconds: 21600\" 2>/dev/null) && curl -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo FAILED"]' \
        --query 'Command.CommandId' \
        --output text 2>/dev/null)
    
    if [[ -n "$imdsv2_result" && "$imdsv2_result" != "None" ]]; then
        sleep 3
        local imdsv2_output=$(aws ssm get-command-invocation \
            --region "$region" \
            --command-id "$imdsv2_result" \
            --instance-id "$instance_id" \
            --query 'StandardOutputContent' \
            --output text 2>/dev/null)
        
        if [[ "$imdsv2_output" == "$instance_id" ]]; then
            echo -e "${GREEN}  ✅ IMDSv2 access succeeded (as expected)${NC}"
            echo -e "     Retrieved instance ID: $imdsv2_output"
        elif [[ "$imdsv2_output" == *"FAILED"* ]]; then
            echo -e "${RED}  ❌ IMDSv2 access failed (unexpected)${NC}"
        else
            echo -e "${YELLOW}  ⚠️  IMDSv2 test results unclear${NC}"
            echo -e "     Output: $imdsv2_output"
        fi
    else
        echo -e "${YELLOW}  ⚠️  Could not test IMDSv2 (SSM may not be available)${NC}"
    fi
    
    echo ""
}

verify_asg_instances() {
    local asg_name=$1
    local region=$2
    
    echo -e "${BLUE}Verifying all instances in Auto Scaling Group: $asg_name${NC}"
    echo ""
    
    # Get all instance IDs from the ASG
    local instance_ids=$(aws autoscaling describe-auto-scaling-groups \
        --region "$region" \
        --auto-scaling-group-names "$asg_name" \
        --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
        --output text 2>/dev/null)
    
    if [[ -z "$instance_ids" || "$instance_ids" == "None" ]]; then
        echo -e "${YELLOW}⚠️  No instances found in ASG $asg_name in region $region${NC}"
        return 1
    fi
    
    local total=0
    local compliant=0
    
    for instance_id in $instance_ids; do
        ((total++))
        verify_instance_imdsv2 "$instance_id" "$region"
        
        # Check if compliant based on metadata options
        local http_tokens=$(aws ec2 describe-instances \
            --region "$region" \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].MetadataOptions.HttpTokens' \
            --output text 2>/dev/null)
        
        if [[ "$http_tokens" == "required" ]]; then
            ((compliant++))
        fi
        
        echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
        echo ""
    done
    
    echo -e "${BLUE}Summary for ASG $asg_name:${NC}"
    echo -e "  Total instances: $total"
    echo -e "  ${GREEN}Compliant: $compliant${NC}"
    echo -e "  ${RED}Non-Compliant: $((total - compliant))${NC}"
    echo ""
}

# Parse command line arguments
INSTANCE_ID=""
REGION="us-east-2"
ASG_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--instance-id)
            INSTANCE_ID="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -a|--asg-name)
            ASG_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  IMDSv2 Enforcement Verification Script              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

check_requirements

if [[ -z "$INSTANCE_ID" && -z "$ASG_NAME" ]]; then
    echo -e "${RED}❌ Error: Either --instance-id or --asg-name must be provided${NC}"
    echo ""
    show_help
    exit 1
fi

if [[ -n "$INSTANCE_ID" ]]; then
    verify_instance_imdsv2 "$INSTANCE_ID" "$REGION"
elif [[ -n "$ASG_NAME" ]]; then
    verify_asg_instances "$ASG_NAME" "$REGION"
fi

echo -e "${GREEN}✅ Verification complete${NC}"
