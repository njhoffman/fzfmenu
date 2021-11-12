#!/bin/bash

# function ec_security_groups {}
function ec_subnet_groups {
  # Subnets[{ SubnetIdentifier, SubnetAvailabilityZone.Name }]
  aws rds describe-cache-subnet-groups \
    --query 'CacheSubnetGroups[].{" Name":CacheSubnetGroupName, Description:CacheSubnetGroupDescription, VPC:VpcId }' \
    --output table
}
function ec_clusters {
  # ClientDownloadLandingPage, EngineVersion, CaheClusterCreateTime, CacheParameterGroup{}, CacheSubnetGroupName,
  #  SecurityGroups[]
  aws rds describe-cache-clusters \
    --query 'CacheClusters[].{" Name":CacheClusterId, Type: Engine, Size:CacheNodeType, Status:CacheClusterStatus, Zone:PreferredAvailabilityZone, Nodes:NumCacheNodes }' \
    --output table
}


