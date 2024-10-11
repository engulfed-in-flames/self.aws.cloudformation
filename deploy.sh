#!/bin/bash

set -e

TEMPLATE="template.yaml"
PACKAGED_TEMPLATE="packaged-template.yaml"
REGION="ap-northeast-1"
S3_BUCKET="flame-bucket"
STACK_NAME="flame-stack"
LAMBDA_FUNCTION_NAME="FlameLambdaFunction"

# 1. Create a S3 bucket if it doesn't exists.
if aws s3 ls "s3://$S3_BUCKET" 2>&1 | grep -q 'NoSuchBucket'; then
  echo "Creating S3 bucket: $S3_BUCKET"
  aws s3 mb s3://$S3_BUCKET
else
  echo "S3 bucket $S3_BUCKET already exists."
fi

# 2. Package CloudFormation template (for Lambda code)
echo "Packaging CloudFormation template..."
aws cloudformation package \
  --template-file $TEMPLATE \
  --output-template-file $PACKAGED_TEMPLATE \
  --region $REGION
  # --s3-bucket $S3_BUCKET \

# 3. Deploy CloudFormation stack
echo "Deploying CloudFormation stack: $STACK_NAME"
aws cloudformation deploy \
  --template-file $PACKAGED_TEMPLATE \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_IAM

if [! -f "$PACKAGED_TEMPLATE" ]: then
  echo "Error: Packaged template file $PACKAGED_TEMPLATE does not exist. Exiting."
  exit 1
fi

# 4. Wait until the CloudFormation stack creation/update is complete
echo "Waiting for CloudFormation stack to complete..."
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME || aws cloudformation wait stack-update-complete --stack-name $STACK_NAME

# Check stack outputs
echo "CloudFormation stack $STACK_NAME deployed. Fetching outputs..."
aws cloudformation describe-stacks --stack-name $STACK_NAME

# Invoke Lambda function for testing
echo "Invoking Lambda function: $LAMBDA_FUNCTION_NAME"
aws lambda invoke \
  --function-name $LAMBDA_FUNCTION_NAME \
  --log-type Tail \
  ./logs/output.txt

# Show the output of the Lambda function
echo "Lambda function output:"
cat ./logs/output.txt

# Cleanup (optional)
# Delete the stack after execution
# echo "Deleting CloudFormation stack..."
# aws cloudformation delete-stack --stack-name $STACK_NAME