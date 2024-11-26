#!/bin/bash

set -e

function create_bucket() {
  local bucket_name=$1
  local profile=$2

  # Check whether the bucket already exists.
  if aws s3api head-bucket \
    --bucket "$bucket_name" \
    --profile "$profile" \
    >/dev/null 2>&1; then

    echo "The bucket already exists"
  else
    echo "The bucket doesn't exists"
    echo "Creating S3 bucket: $bucket_name"
    aws s3 mb s3://$bucket_name --profile $profile
  fi
}

function packaged_template_exists() {
  local packaged_template_name=$1

  if [ -f "$packaged_template_name" ]; then
    echo "$packaged_template_name exists."
    return 0
  else
    echo "Error: Packaged template file $packaged_template_name does not exist."
    echo "Exit..."
    return 1
  fi
}

PROFILE="YOUR_AWS_PROFILE"
REGION="YOUR_AWS_REGION"
S3_BUCKET="cfn-resources"
TEMPLATE="template.yaml"
PACKAGED_TEMPLATE="packaged-template.yaml"
STACK_NAME="YOUR_AWS_STACK_NAME"

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --init)
      if [[ "$2" == "true" ]]; then
        TEMPLATE="template.init.yaml"
        PACKAGED_TEMPLATE="packaged-template.init.yaml"
        STACK_NAME="flame-init"
      fi
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# 1. Create a S3 bucket if it doesn't exists.
create_bucket "$S3_BUCKET" "$PROFILE"

# 2. Package CloudFormation template (for Lambda code)
echo "Packaging CloudFormation template..."
aws cloudformation package \
  --s3-bucket $S3_BUCKET \
  --template-file $TEMPLATE \
  --output-template-file $PACKAGED_TEMPLATE \
  --output yaml \
  --region $REGION

if ! packaged_template_exists "$PACKAGED_TEMPLATE"; then 
  exit 1
fi

# 3. Deploy CloudFormation stack
echo "Deploying CloudFormation stack: $STACK_NAME"
aws cloudformation deploy \
  --profile $PROFILE \
  --template-file $PACKAGED_TEMPLATE \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_NAMED_IAM

# 4. Wait until the CloudFormation stack creation/update is complete
echo "Waiting for CloudFormation stack to complete..."
aws cloudformation wait stack-create-complete --profile $PROFILE --stack-name $STACK_NAME || aws cloudformation wait stack-update-complete --profile $PROFILE --stack-name $STACK_NAME

# Check stack outputs
echo "CloudFormation stack $STACK_NAME deployed. Fetching outputs..."
aws cloudformation describe-stacks --profile $PROFILE --stack-name $STACK_NAME

# Cleanup (optional)
# Delete the stack after execution
#
# echo "Deleting CloudFormation stack..."
# aws cloudformation delete-stack \
#   --profile $PROFILE \
#   --stack-name $STACK_NAME
