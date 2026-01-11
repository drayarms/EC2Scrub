#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script to invoke the EC2 snapshot cleanup Lambda and optionally view logs
# -----------------------------------------------------------------------------

# Configuration
LAMBDA_NAME="ec2-inventory-lambda" #Must match our Lambda function_name
REGION="us-west-1" #AWS region *Must match the region in terraform, set in root variables.tf
PAYLOAD='{"DryRun": true}' #Optional payload; adjust or set '{}' if unused
OUTPUT_FILE="/tmp/lambda_output.json"

# Invoke the Lambda
echo "Invoking Lambda function: $LAMBDA_NAME in region: $REGION"
aws lambda invoke \
    --function-name "$LAMBDA_NAME" \
    --region "$REGION" \
    --payload "$PAYLOAD" \
    "$OUTPUT_FILE"

echo "Lambda response saved to $OUTPUT_FILE"

# Optionally stream the latest logs from CloudWatch
echo
echo "Streaming Lambda logs from CloudWatch..."
aws logs tail "/aws/lambda/$LAMBDA_NAME" --region "$REGION" --follow
