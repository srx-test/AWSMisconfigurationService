#!/bin/bash

# Script to identify Auto Scaling Groups not using IMDSv2
# This script helps identify ASGs that need to be updated for security compliance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo "Auto Scaling Group IMDSv2 Compliance Checker"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --region REGION    AWS region to check (default: all regions)"
    echo "  -o, --output FILE      Output results to a file"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                              # Check all regions"
    echo "  $0 -r us-east-2                # Check only us-east-2"
    echo "  $0 -r us-east-2 -o report.txt  # Check us-east-2 and save to file"
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
        echo -e "${YELLOW}⚠️  jq is not installed. Output will be less formatted.${NC}"
        echo "Install jq for better output: https://stedolan.github.io/jq/"
        HAS_JQ=false
    else
        HAS_JQ=true
    fi
}

get_regions() {
    if [[ -n "$TARGET_REGION" ]]; then
        echo "$TARGET_REGION"
    else
        aws ec2 describe-regions --query 'Regions[*].RegionName' --output text
    fi
}

check_launch_template_imdsv2() {
    local region=$1
    local lt_id=$2
    local lt_version=$3
    
    # Parse JSON using jq if available, otherwise use AWS CLI query directly
    if [[ "$HAS_JQ" == true ]]; then
        # Get launch template data
        local lt_data=$(aws ec2 describe-launch-template-versions \
            --region "$region" \
            --launch-template-id "$lt_id" \
            --versions "$lt_version" \
            --query 'LaunchTemplateVersions[0].LaunchTemplateData.MetadataOptions' \
            --output json 2>/dev/null)
        
        if [[ -z "$lt_data" || "$lt_data" == "null" ]]; then
            echo "unknown"
            return
        fi
        
        local http_tokens=$(echo "$lt_data" | jq -r '.HttpTokens // "optional"')
        echo "$http_tokens"
    else
        # Fallback: use AWS CLI query directly for more reliable parsing
        local http_tokens=$(aws ec2 describe-launch-template-versions \
            --region "$region" \
            --launch-template-id "$lt_id" \
            --versions "$lt_version" \
            --query 'LaunchTemplateVersions[0].LaunchTemplateData.MetadataOptions.HttpTokens' \
            --output text 2>/dev/null)
        
        if [[ -z "$http_tokens" || "$http_tokens" == "None" ]]; then
            echo "optional"
        else
            echo "$http_tokens"
        fi
    fi
}

check_asg_imdsv2_compliance() {
    local region=$1
    
    echo -e "${BLUE}Checking region: $region${NC}"
    
    # Get all Auto Scaling Groups in the region
    local asgs=$(aws autoscaling describe-auto-scaling-groups \
        --region "$region" \
        --query 'AutoScalingGroups[*].[AutoScalingGroupName,LaunchTemplate.LaunchTemplateId,LaunchTemplate.Version]' \
        --output text 2>/dev/null)
    
    if [[ -z "$asgs" ]]; then
        echo -e "${YELLOW}  No Auto Scaling Groups found in $region${NC}"
        return
    fi
    
    local total=0
    local compliant=0
    local non_compliant=0
    local unknown=0
    
    while IFS=$'\t' read -r asg_name lt_id lt_version; do
        if [[ "$asg_name" == "None" || -z "$lt_id" ]]; then
            echo -e "${YELLOW}  ⚠️  ASG: $asg_name - No launch template (using launch configuration or mixed instances)${NC}"
            ((unknown++))
            ((total++))
            continue
        fi
        
        # Resolve $Latest or $Default to actual version number
        if [[ "$lt_version" == "\$Latest" ]]; then
            lt_version=$(aws ec2 describe-launch-templates \
                --region "$region" \
                --launch-template-ids "$lt_id" \
                --query 'LaunchTemplates[0].LatestVersionNumber' \
                --output text 2>/dev/null)
        elif [[ "$lt_version" == "\$Default" ]]; then
            lt_version=$(aws ec2 describe-launch-templates \
                --region "$region" \
                --launch-template-ids "$lt_id" \
                --query 'LaunchTemplates[0].DefaultVersionNumber' \
                --output text 2>/dev/null)
        fi
        
        local imdsv2_status=$(check_launch_template_imdsv2 "$region" "$lt_id" "$lt_version")
        
        ((total++))
        
        if [[ "$imdsv2_status" == "required" ]]; then
            echo -e "${GREEN}  ✅ ASG: $asg_name - IMDSv2 REQUIRED (Compliant)${NC}"
            ((compliant++))
        elif [[ "$imdsv2_status" == "optional" ]]; then
            echo -e "${RED}  ❌ ASG: $asg_name - IMDSv2 OPTIONAL (Non-Compliant)${NC}"
            ((non_compliant++))
        else
            echo -e "${YELLOW}  ⚠️  ASG: $asg_name - IMDSv2 status unknown${NC}"
            ((unknown++))
        fi
    done <<< "$asgs"
    
    echo ""
    echo -e "${BLUE}Summary for $region:${NC}"
    echo -e "  Total ASGs: $total"
    echo -e "  ${GREEN}Compliant (IMDSv2 required): $compliant${NC}"
    echo -e "  ${RED}Non-Compliant (IMDSv2 optional): $non_compliant${NC}"
    echo -e "  ${YELLOW}Unknown/No Launch Template: $unknown${NC}"
    echo ""
    
    # Add to global counters
    GLOBAL_TOTAL=$((GLOBAL_TOTAL + total))
    GLOBAL_COMPLIANT=$((GLOBAL_COMPLIANT + compliant))
    GLOBAL_NON_COMPLIANT=$((GLOBAL_NON_COMPLIANT + non_compliant))
    GLOBAL_UNKNOWN=$((GLOBAL_UNKNOWN + unknown))
}

# Parse command line arguments
TARGET_REGION=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            TARGET_REGION="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
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

# Initialize global counters
GLOBAL_TOTAL=0
GLOBAL_COMPLIANT=0
GLOBAL_NON_COMPLIANT=0
GLOBAL_UNKNOWN=0

# Main execution
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Auto Scaling Group IMDSv2 Compliance Checker        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

check_requirements

if [[ -n "$OUTPUT_FILE" ]]; then
    exec &> >(tee "$OUTPUT_FILE")
fi

echo -e "${BLUE}Starting compliance check...${NC}"
echo ""

# Get regions and check each one
regions=$(get_regions)

for region in $regions; do
    check_asg_imdsv2_compliance "$region"
done

# Display global summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  GLOBAL SUMMARY                                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Total ASGs across all regions: $GLOBAL_TOTAL"
echo -e "  ${GREEN}Compliant (IMDSv2 required): $GLOBAL_COMPLIANT${NC}"
echo -e "  ${RED}Non-Compliant (IMDSv2 optional): $GLOBAL_NON_COMPLIANT${NC}"
echo -e "  ${YELLOW}Unknown/No Launch Template: $GLOBAL_UNKNOWN${NC}"
echo ""

if [[ $GLOBAL_NON_COMPLIANT -gt 0 ]]; then
    echo -e "${RED}⚠️  WARNING: $GLOBAL_NON_COMPLIANT Auto Scaling Group(s) are not IMDSv2 compliant!${NC}"
    echo -e "${YELLOW}Please update these ASGs to enforce IMDSv2 for better security.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All Auto Scaling Groups are IMDSv2 compliant!${NC}"
    exit 0
fi
