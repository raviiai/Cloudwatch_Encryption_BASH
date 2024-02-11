#!/bin/bash

<< comment 
This script is going to encrypt the aws log group of AWS CloudWatch
comment

# Define AWS region
aws_region="us-east-1"
cmk_key="ebe49f2c-d801-4ab5-93e2-853e381d2523"

# List CloudWatch log groups
list_log_groups() {
    echo "The following CloudWatch log groups will be encrypted using CMK Keyz:"
    aws logs describe-log-groups --region $aws_region --query 'logGroups[?kmsKeyId==`null`].logGroupName' --output table

}



cat << EOF > resource-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEncryption",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.amazonaws.com"
      },
      "Action": "kms:Encrypt",
      "Resource": "${cmk_key}",
      "Condition": {
        "StringEquals": {
          "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:us-east-1:871794273757:log-group:*"
        }
      }
    }
  ]
}
EOF

# Encrypt CloudWatch log groups
encrypt_log_groups() {
    echo "Encrypting CloudWatch log groups..."
    # Loop through each log group and encrypt
    log_groups=$(aws logs describe-log-groups --region $aws_region --query 'logGroups[*].logGroupName' --output text)
    for log_group in $log_groups; do
        aws logs put-resource-policy --policy-name "CMKEncryptionPolicy-${log_group}" --policy-document file://resource-policy.json
    done
    echo "Encryption complete."
}
############################
## Main
############################

list_log_groups
if [[ "$1" == "-y" ]]; then
    encrypt_log_groups
else
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
fi
rm resource-policy.json
