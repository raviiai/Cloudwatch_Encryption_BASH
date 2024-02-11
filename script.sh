#!/bin/bash

###############################
## AWS config
###############################
aws_region="us-east-1"
cmk_key_arn="arn:aws:kms:us-east-1:871794273757:key/09276167-1b21-4420-8b32-9fe77c58f6bd"


###############################
## Function to list log Groups
###############################

list_log_groups() {
    echo "The following CloudWatch log groups will be encrypted using CMK :"
    aws logs describe-log-groups --region $aws_region --query 'logGroups[*].logGroupName' --output table
}

###############################
## Encrypt CloudWatch log groups
###############################

encrypt_log_groups() {
    echo "Encrypting CloudWatch log groups..."
    log_groups=$(aws logs describe-log-groups --region $aws_region --query 'logGroups[*].logGroupName' --output text)
    for log_group in $log_groups; do
        aws logs associate-kms-key --log-group-name $log_group --kms-key-id $cmk_key_arn
    done
    echo "Encryption complete."
}

###############################
## Error Handling
###############################
set -e
# function to handle error
handle_error() {
    echo "Failed to set retention policy for log group: $log_group"
    exit 1
}
# Trap errors and call the custom function
trap 'handle_error' ERR


###############################
## Main
###############################
list_log_groups
if [ "$1" == "-y" ]; then
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
