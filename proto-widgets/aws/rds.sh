#!/bin/bash

function rds_clusters {
  echo "rds_clusters"
}

function rds_db_security_groups {
  # OwnerId, EC2securityGroups[], IPRanges[], DBSecurityGroupArn
  aws rds describe-db-security-groups \
    --query 'DBSecurityGroups[].{" Name":DBSecurityGroupName, Description:DBSecurityGroupDescription}' \
    --output table
}

function rds_db_instances {
  # MasterUsername, DBSecurityGroups[], VpcSecurityGroups[{ VpcSecurityGroupId, status }], DbInstanceArn, IAMDatabaseAutenticatioNEnabled
  # DBParamaterGroups[{ DBParameterGroupName, ParameterApplyStatus }]
  aws rds describe-db-instances \
    --query 'DBInstances[].{" Name":DBInstanceIdentifier, Type:DBEngine, Class:DBInstanceClass, Zone:AvailabilityZone, Endpoint:Endpoint.Address, Public:PubliclyAccessibe }' \
    --output table
}

function rds_db_subnets {
  # DBSubnetGroup[{ DBSubnetGroupName, DBSubnetGroupDescrxiption, VpcId, SubnetGroupStatus, Subnets[ SubnetIdentifier, SubnetAvailabilityZone.Name, SubnetStatus }]
  aws rds describe-db-subnet-groups \
    --query 'DBSubnetGroups[].{" Name":DBSubnetGroupName, Description:DBSubnetGroupDescription, VPC:VpcId}' \
    --output table
}
