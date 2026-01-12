import boto3
import os
import logging
from datetime import datetime, timezone, timedelta
from botocore.exceptions import ClientError

#Config logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

#Create EC2 clinet (region inherited from Lambda exec env)
ec2 = boto3.client("ec2")

MAX_AGE_VALUE = float(os.environ.get("MAX_AGE_VALUE", 365))  # default 365
MAX_AGE_UNIT = os.environ.get("TIMEFRAME", "days").lower()   # default 'days'

if MAX_AGE_UNIT == "days":
    MAX_AGE = timedelta(days=MAX_AGE_VALUE)
elif MAX_AGE_UNIT == "hours":
    MAX_AGE = timedelta(hours=MAX_AGE_VALUE)
elif MAX_AGE_UNIT == "minutes":
    MAX_AGE = timedelta(minutes=MAX_AGE_VALUE)
else:
    raise ValueError(f"Invalid TIMEFRAME value: {MAX_AGE_UNIT}")

def lambda_handler(event, context):
    logger.info("Starting EC2 snapshot scrubbing")

    try:
        #Only snapshots owned by this account
        response = ec2.describe_snapshots(OwnerIds=["self"])
        snapshots = response.get("Snapshots", [])

        logger.info(f"Found {len(snapshots)} snapshots")

        for snapshot in snapshots:
            snapshot_id = snapshot["SnapshotId"]
            start_time = snapshot["StartTime"]

            age = datetime.now(timezone.utc) - start_time

            if age > MAX_AGE_VALUE:
                logger.info(
                    f"Snapshot {snapshot_id} is older than {MAX_AGE_VALUE} {MAX_AGE_UNIT}"
                    f"(created {start_time})"
                )

                try:
                    logger.info(f"Deleting snapshot: {snapshot_id}")
                    ec2.delete_snapshot(SnapshotId=snapshot_id)
                except ClientError as e:
                    logger.error(
                        f"Failed to delete snapshot {snapshot_id}: "
                        f"{e.response['Error']['Message']}"
                    )

        logger.info("Completed snapshot scrubbing")

    except ClientError as e:
        logger.error(f"Error retrieving snapshots: {e.response['Error']['message']}")
        raise
