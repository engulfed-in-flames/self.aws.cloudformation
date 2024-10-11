#!/bin/bash

set -e

TEMPLATE="template.yaml"
PACKAGED_TEMPLATE="packaged-template.yaml"
REGION="ap-northeast-1"
S3_BUCKET="flame-lambda-code-bucket"
STACK_NAME="flame"
LAMBDA_FUNCTION_NAME="FlameLambdaFunction"

# Build and package the SAM application
echo "Building SAM application..."
sam build

# Package the SAM template and upload Lambda code to S3
echo "Packaging SAM application..."
sam package \
  --template-file $TEMPLATE \
  --output-template-file $PACKAGED_TEMPLATE \
  --region $REGION \
  --s3-bucket $S3_BUCKET \

if [ ! -f "$PACKAGED_TEMPLATE" ] 
then
  echo "Error: Packaged template file $PACKAGED_TEMPLATE does not exist. Exiting."
  exit 1
else
  echo "$PACKAGED_TEMPLATE exists."
fi

# Deploy the SAM application
echo "Deploying SAM application: $STACK_NAME"
sam deploy \
  --template-file $PACKAGED_TEMPLATE \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --guided

# Wait for CloudFormation stack to complete
echo "Waiting for CloudFormation stack to complete..."
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME || aws cloudformation wait stack-update-complete --stack-name $STACK_NAME

# Check stack outputs
echo "CloudFormation stack $STACK_NAME deployed. Fetching outputs..."
aws cloudformation describe-stacks --stack-name $STACK_NAME

# Invoke Lambda function for testing
echo "Invoking Lambda function: $LAMBDA_FUNCTION_NAME"
mkdir -p ./logs
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
# sam delete --stack-name $STACK_NAME
