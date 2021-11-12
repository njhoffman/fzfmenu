#!/bin/bash

function ec2_instances {
read -d '' query << EOF
  Reservations[].Instances[].{
    " Name": Tags[?Key=='Name'].Value | [0],
    ID:InstanceId,
    Type:InstanceType,
    Image:ImageId,
    IP:PublicIpAddress,
    State:State.Name
  }
EOF
read -d '' query_v << EOF
  Reservations[].Instances[].{
    " Name": Tags[?Key=='Name'].Value | [0],
    ID:InstanceId,
    Type:InstanceType,
    Image:ImageId,
    DNS:PublicDnsName,
    IP:PublicIpAddress,
    State:State.Name
  }
EOF

  if [ "$1" == "-a" ]; then
    aws ec2 describe-instances --query 'Reservations[].Instances[]' --output table
  elif [ "$1" == "-v" ]; then
    aws ec2 describe-instances --query "$query_v" --output table
  else
    aws ec2 describe-instances --query "$query" --output table
  fi
}

function ec2_volumes {
  # CreateTime, SnapshotId, Encrypted, Iops, Attachments[{ AttachTime, Device, instanceId, State, VolumeId, DeleteOnTermination }]
read -d '' query << EOF
  Volumes[].{
    " Name": VolumeId,
    Zone:AvailabilityZone,
    State:State,
    Type:VolumeType,
    Size:Size
  }
EOF

  if [ "$1" == "-a" ]; then
    aws ec2 describe-volumes --query "Volumes[]" --output table
  else
    aws ec2 describe-volumes --query "$query" --output table
  fi
}

function ec2_vpcs {
read -d '' query << EOF
  Vpcs[].{
    " Name": VpcId,
    CIDR:CidrBlock,
    State:State,
    DHCP:DhcOptionsId,
    Default:IsDefault
  }
EOF
  # OwnerId, InstanceTenancy, CidrBlockAssociationSet[], Tags[]
  aws ec2 describe-vpcs --query "$query" --output table
}

function ec2_subnets {
  # AvailabilityZoneId, OwnerId, SubnetArn, MapPublicIpOnLaunch, DefaultForAz, AvailableIpAddressCount
    aws ec2 describe-subnets \
      --query 'Subnets[].{" Name": SubnetId, Zone:AvailabilityZone, State:State, VPC:VpcId, CIDR:CidrBlock}' \
      --output table
}

function ec2_security_groups {
  if [ "$1" == "-v" ]; then
    aws ec2 describe-security-groups \
      --query 'SecurityGroups[].{" Name":GroupName, Description:Description, VPC:VpcId, Ports: IpPermissions[].[FromPort, ToPort]}' \
      --output table
  else
    aws ec2 describe-security-groups \
      --query 'SecurityGroups[].{" Name":GroupName, Description:Description, VPC:VpcId,  From: IpPermissions[].FromPort | [0], To: IpPermissions[].ToPort | [0]}' \
      --output table
  fi
}
