#!/bin/bash

function eks_list_clusters {
  aws eks list-clusters --output table
}

function eks_describe_cluster {
  # cluster.{ name, arn, createdAt, version, endpoint, roleArn, status, platform, tagsj }
  # cluster.resourcesVpcConfig.{ subnetIds, securityGroupIds, clusterSecurityGroupId, vpcId, endpointPublicAccess, endpointPrivateAccess, publicAccessCidrs
  # cluster.logging.clusterLogging[].types
  # cluster.certificateAuthority.data
read -d '' query << EOF
  cluster.{
    " Name":name,
    "Status":status,
    "Tags":tags
  }
EOF
  aws eks describe-cluster --name $1 --query "$query" --output table
}

function eks_list_nodegroups {
  aws eks list-nodegroups --cluster-name $1 --output table
}

function eks_describe_nodegroup {
  aws eks describe-nodegroup --nodegroup-name $1 --output table
}
