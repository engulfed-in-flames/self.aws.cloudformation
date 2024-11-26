#!/bin/bash

set -e

PROFILE="YOUR_AWS_PROFILE"
TEMPLATE="template.yaml"
PACKAGED_TEMPLATE="packaged-template.yaml"
REGION="YOUR_AWS_REGION"
S3_BUCKET="YOUR_AWS_S3_BUCKET"
STACK_NAME="YOUR_AWS_STACK_NAME"

# 1. Create a S3 bucket if it doesn't exists.
if aws s3 ls --profile $PROFILE "s3://$S3_BUCKET" 2>&1 | grep -q 'NoSuchBucket'
then
  echo "Creating S3 bucket: $S3_BUCKET"
  aws s3 mb --profile $PROFILE s3://$S3_BUCKET
else
  echo "S3 bucket $S3_BUCKET already exists."
fi

# 2. Package CloudFormation template (for Lambda code)
echo "Packaging CloudFormation template..."
aws cloudformation package \
  --template-file $TEMPLATE \
  --output-template-file $PACKAGED_TEMPLATE \
  --region $REGION \
  --s3-bucket $S3_BUCKET

if [ ! -f "$PACKAGED_TEMPLATE" ] 
then
  echo "Error: Packaged template file $PACKAGED_TEMPLATE does not exist. Exiting."
  exit 1
else
  echo "$PACKAGED_TEMPLATE exists."
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
