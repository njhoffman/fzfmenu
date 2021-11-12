#!/bin/bash

aws ec2 get-console-output --instance-id i-0b94c05f9f7088509 | jq
aws logs describe-log-streams
aws logs describe-log-groups

awslogs groups
awslogs streams GROUP
awslogs get GROUP [STREAM_EXPRESSION]
awslogs --start='2d' --filter-pattern="[r=REPORT,...]"
awslogs get my_lambda_group --query=message

# https://github.com/TylerBrock/saw
