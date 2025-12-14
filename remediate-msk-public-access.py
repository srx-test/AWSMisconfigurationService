#!/usr/bin/env python3
"""
MSK Public Access Remediation Script
This script disables public access for Amazon MSK clusters in AWS account 13437518

WARNING: This script modifies production infrastructure. Use with caution.
Always test in a non-production environment first.

Usage:
    python3 remediate-msk-public-access.py --region us-east-2 --cluster-arn <cluster-arn>
    python3 remediate-msk-public-access.py --region us-east-2 --scan-all
"""

import argparse
import boto3
import json
import sys
from typing import List, Dict, Optional


def get_msk_client(region: str):
    """Initialize MSK boto3 client for the specified region"""
    return boto3.client('kafka', region_name=region)


def list_all_clusters(client) -> List[Dict]:
    """List all MSK clusters in the account"""
    clusters = []
    paginator = client.get_paginator('list_clusters_v2')
    
    try:
        for page in paginator.paginate():
            clusters.extend(page['ClusterInfoList'])
    except Exception as e:
        print(f"❌ Error listing clusters: {str(e)}")
        sys.exit(1)
    
    return clusters


def get_cluster_details(client, cluster_arn: str) -> Optional[Dict]:
    """Get detailed information about a specific cluster"""
    try:
        response = client.describe_cluster_v2(ClusterArn=cluster_arn)
        return response['ClusterInfo']
    except Exception as e:
        print(f"❌ Error getting cluster details for {cluster_arn}: {str(e)}")
        return None


def has_public_access(cluster_info: Dict) -> bool:
    """Check if a cluster has public access enabled"""
    try:
        connectivity = cluster_info.get('BrokerNodeGroupInfo', {}).get('ConnectivityInfo', {})
        public_access = connectivity.get('PublicAccess', {})
        return public_access.get('Type') is not None
    except Exception:
        return False


def disable_public_access(client, cluster_arn: str, current_version: str, dry_run: bool = False) -> bool:
    """
    Disable public access for an MSK cluster
    
    Note: AWS MSK doesn't support direct modification of public access after cluster creation.
    This would require cluster recreation. This function demonstrates the intended approach.
    """
    if dry_run:
        print(f"[DRY RUN] Would disable public access for cluster: {cluster_arn}")
        return True
    
    print(f"⚠️  WARNING: MSK clusters cannot modify public access settings after creation.")
    print(f"⚠️  To disable public access, you need to:")
    print(f"   1. Create a new MSK cluster without public access")
    print(f"   2. Migrate your data and applications to the new cluster")
    print(f"   3. Delete the old cluster with public access")
    print(f"\nFor cluster: {cluster_arn}")
    print(f"Current version: {current_version}")
    
    return False


def scan_and_report(client, region: str) -> List[Dict]:
    """Scan all clusters and report those with public access enabled"""
    print(f"\n🔍 Scanning MSK clusters in region: {region}")
    print("=" * 80)
    
    clusters = list_all_clusters(client)
    
    if not clusters:
        print("✅ No MSK clusters found in this region.")
        return []
    
    print(f"Found {len(clusters)} MSK cluster(s)")
    
    vulnerable_clusters = []
    
    for cluster in clusters:
        cluster_arn = cluster['ClusterArn']
        cluster_name = cluster['ClusterName']
        cluster_state = cluster['State']
        
        cluster_details = get_cluster_details(client, cluster_arn)
        if not cluster_details:
            continue
        
        has_public = has_public_access(cluster_details)
        
        print(f"\n📊 Cluster: {cluster_name}")
        print(f"   ARN: {cluster_arn}")
        print(f"   State: {cluster_state}")
        print(f"   Public Access: {'❌ ENABLED (VULNERABLE)' if has_public else '✅ DISABLED'}")
        
        if has_public:
            vulnerable_clusters.append({
                'name': cluster_name,
                'arn': cluster_arn,
                'state': cluster_state,
                'version': cluster_details.get('CurrentVersion', 'unknown')
            })
    
    print("\n" + "=" * 80)
    print(f"\n📈 Summary:")
    print(f"   Total clusters: {len(clusters)}")
    print(f"   Clusters with public access: {len(vulnerable_clusters)}")
    print(f"   Compliant clusters: {len(clusters) - len(vulnerable_clusters)}")
    
    return vulnerable_clusters


def main():
    parser = argparse.ArgumentParser(
        description='Remediate MSK public access misconfiguration',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        '--region',
        required=True,
        help='AWS region (e.g., us-east-2)'
    )
    
    parser.add_argument(
        '--cluster-arn',
        help='Specific cluster ARN to remediate'
    )
    
    parser.add_argument(
        '--scan-all',
        action='store_true',
        help='Scan all clusters in the region and report status'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Perform a dry run without making changes'
    )
    
    args = parser.parse_args()
    
    # Initialize client
    client = get_msk_client(args.region)
    
    print(f"\n🚀 MSK Public Access Remediation Tool")
    print(f"Region: {args.region}")
    print(f"Mode: {'Dry Run' if args.dry_run else 'Live'}")
    print("=" * 80)
    
    if args.scan_all:
        vulnerable_clusters = scan_and_report(client, args.region)
        
        if vulnerable_clusters:
            print(f"\n⚠️  Found {len(vulnerable_clusters)} cluster(s) with public access enabled:")
            for cluster in vulnerable_clusters:
                print(f"   - {cluster['name']} ({cluster['arn']})")
            
            print("\n💡 Recommended Actions:")
            print("   1. Review each cluster's public access requirement")
            print("   2. Update application code to use VPC peering or AWS PrivateLink")
            print("   3. Create new clusters without public access")
            print("   4. Migrate data and applications to new clusters")
            print("   5. Delete old clusters with public access")
            print("   6. Implement AWS Config rules to prevent future misconfigurations")
            
            sys.exit(1 if vulnerable_clusters else 0)
    
    elif args.cluster_arn:
        cluster_details = get_cluster_details(client, args.cluster_arn)
        if not cluster_details:
            sys.exit(1)
        
        if has_public_access(cluster_details):
            print(f"⚠️  Cluster has public access enabled")
            current_version = cluster_details.get('CurrentVersion', 'unknown')
            disable_public_access(client, args.cluster_arn, current_version, args.dry_run)
        else:
            print(f"✅ Cluster already has public access disabled")
    
    else:
        parser.print_help()
        print("\n❌ Error: Please specify either --cluster-arn or --scan-all")
        sys.exit(1)


if __name__ == "__main__":
    main()
