"""import boto3

ec2 = boto3.client("ec2")

def lambda_handler(event, context):
    response = ec2.describe_instances()

    instances = []
    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            instances.append({
                "InstanceId": instance["InstanceId"],
                "State": instance["State"]["Name"],
                "SubnetId": instance.get("SubnetId"),
                "VpcId": instance.get("VpcId")
            })

    return {
        "instance_count": len(instances),
        "instances": instances
    }"""

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

    #Snapshot age threshold
    #DAYS_OLD = 365
    MAX_AGE = timedelta(days=365)
    TIMEFRAME = "days"
    #MAX_AGE = timedelta(hours=1) #For Debugging
    #timeframe = "hours"
    #MAX_AGE = timedelta(minutes=1) #For Debugging
    #timeframe = "minutes"

    def lambda_handler(event, context):
        logger.info("Starting EC2 snapshot scrubbing")

        #cuttoff_date = datetime.now(timezone.utc) timedelta(days=DAYS_OLD)

        try:
            #Only snapshots owned by this account
            response = ec2.describe_snapshots(OwnerIds=["self"])
            snapshots = response.get("Snapshots", [])

            logger.info(f"Found {len(snapshots)} snapshots")

            for snapshot in snapshots:
                snapshot_id = snapshot["SnapshotID"]
                start_time = snapshot["StartTime"]

                age = datetime.now(timezone.utc) - start_time

                #if start_time < cuttoff_date:
                if age > MAX_AGE:
                    logger.info(
                        #f"Snapshot {snapshot_id} is older than {DAYS_OLD} days"
                        f"Snapshot {snapshot_id} is older than {MAX_AGE} {TIMEFRAME}"
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
