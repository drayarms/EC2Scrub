#!/usr/bin/env bash
# Script to package, update, and invoke the EC2 snapshot cleanup Lambda

set -e
export AWS_PAGER="" #Prevents AWS CLI pager from silently blockiing execution

# Move to the directory where this script lives
# (so lambda_function.py is found reliably)
cd "$(dirname "$0")"


# Configuration
LAMBDA_NAME="ec2-inventory-lambda"   # Must match Lambda function_name
REGION="us-west-1"                    # AWS region
ZIP_FILE="/tmp/lambda_function.zip"
OUTPUT_FILE="/tmp/lambda_output.json"
PAYLOAD_FILE="/tmp/payload.json"

# Optional environment variables (defaults if not set)
MAX_AGE_VALUE=${MAX_AGE_VALUE:-365}
TIMEFRAME=${TIMEFRAME:-days}


# CREATE PAYLOAD
echo '{"DryRun": true}' > "$PAYLOAD_FILE"


# PACKAGE LAMBDA
echo "Packaging Lambda function..."
rm -f "$ZIP_FILE"
zip -r "$ZIP_FILE" lambda_function.py > /dev/null
echo "Package created: $ZIP_FILE"


# UPDATE LAMBDA FUNCTION CODE
echo "Updating Lambda function code: $LAMBDA_NAME in region: $REGION"
aws lambda update-function-code \
    --function-name "$LAMBDA_NAME" \
    --zip-file "fileb://$ZIP_FILE" \
    --region "$REGION"

echo "Waiting for Lambda update to complete..."
aws lambda wait function-updated \
  --function-name "$LAMBDA_NAME" \
  --region "$REGION"

# UPDATE LAMBDA ENVIRONMENT VARIABLES
echo "Updating Lambda environment variables..."
aws lambda update-function-configuration \
    --function-name "$LAMBDA_NAME" \
    --region "$REGION" \
    --environment "Variables={MAX_AGE_VALUE=$MAX_AGE_VALUE,TIMEFRAME=$TIMEFRAME}"

echo "Waiting for configuration update to complete..."
aws lambda wait function-updated \
  --function-name "$LAMBDA_NAME" \
  --region "$REGION"    

#VERIFY FUNCTION IS FULLY UPDATED BEFORE INVOKING SCRIPT
echo "Verifying Lambda update state..."
MAX_WAIT_SECONDS=300
START_TIME=$(date +%s)

while true; do
  STATUS=$(aws lambda get-function-configuration \
    --function-name "$LAMBDA_NAME" \
    --region "$REGION" \
    --query 'LastUpdateStatus' \
    --output text)

  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))

  echo "Status: $STATUS (elapsed ${ELAPSED}s)"

  if [[ "$STATUS" == "Successful" ]]; then
    echo "Lambda update successful."
    break
  fi

  if [[ "$STATUS" == "Failed" ]]; then
    echo "Lambda update failed."
    exit 1
  fi

  if [[ "$ELAPSED" -ge "$MAX_WAIT_SECONDS" ]]; then
    echo "Timed out waiting for Lambda update."
    exit 1
  fi

  sleep 5
done

# INVOKE LAMBDA
echo "Invoking Lambda function: $LAMBDA_NAME in region: $REGION"
aws lambda invoke \
    --function-name "$LAMBDA_NAME" \
    --region "$REGION" \
    --payload fileb://"$PAYLOAD_FILE" \
    "$OUTPUT_FILE"

echo "Lambda response saved to $OUTPUT_FILE"


# STREAM LOGS
echo
echo "Streaming Lambda logs from CloudWatch..."
aws logs tail "/aws/lambda/$LAMBDA_NAME" --region "$REGION" --follow
