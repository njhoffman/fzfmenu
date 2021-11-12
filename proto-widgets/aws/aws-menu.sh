#!/bin/bash

function _fzf-source-ec2 {
 json_file="./data/ec2-describe-instances.json"
 while read -r line; do
   # .Reservations[].Instances[].Tags.[Key,Value]
   fields=".ImageId, .InstanceType, .InstanceId, .PublicDnsName, .PublicIpAddress"
   fields="${fields}, .SubnetId, .VpcId, .LaunchTime, .State.Name"
   # data=
   IFS=$'\n' read -r -d '' \
     image_id instance_type instance_id public_dns public_ip \
     subnet_id vpc_id launch state \
     <<< $(echo "$line" | jq -r "$fields")

   printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
     $state $image_id $instance_type $instance_id $public_dns $public_ip \
     $subnet_id $vpc_id $launch

 done < <(cat "$json_file" | jq -c '.Reservations[].Instances[]')
}

function _fzf-menu-ec2 {
  echo "2 ec2 instances running"
}

menu_ec2
