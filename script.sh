#!/bin/bash

<< comment 
This script is going to encrypt the aws log group of AWS CloudWatch
comment

# Define AWS region
aws_region="us-east-1"
aws_cmk_key_id="ebe49f2c-d801-4ab5-93e2-853e381d2523"

# List CloudWatch log groups
list_log_groups() {
    echo "The following CloudWatch log groups will be encrypted using CMK Keyz:"
    aws logs describe-log-groups --region $aws_region --query 'logGroups[*].logGroupName' --output table
}

# Encrypt CloudWatch log groups
encrypt_log_groups() {
    echo "Encrypting CloudWatch log groups..."
    # Loop through each log group and encrypt
    log_groups=$(aws logs describe-log-groups --region $aws_region --query 'logGroups[*].logGroupName' --output text)
    for log_group in $log_groups; do
        aws logs put-retention-policy --region $aws_region --log-group-name $log_group --retention-in-days 30 --kms-key-id $aws_cmk_key_id
    done
    echo "Encryption complete."
}

# Main script
list_log_groups
read -p "Do you want to proceed with encryption? (yes/no): " choice
case "$choice" in 
  yes|Yes|YES )
    encrypt_log_groups
    ;;
  no|No|NO )
    echo "Encryption aborted."
    ;;
  * )
    echo "Invalid input. Encryption aborted."
    ;;
esac
