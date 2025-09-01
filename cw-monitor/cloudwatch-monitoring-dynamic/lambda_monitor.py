import boto3
import os

cloudwatch = boto3.client("cloudwatch")
ec2 = boto3.client("ec2")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")


def create_alarms(instance_id):
    print(f"Creating alarms for {instance_id}")

    # CPU Utilization Alarm
    cloudwatch.put_metric_alarm(
        AlarmName=f"HighCPU-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=1,
        MetricName="CPUUtilization",
        Namespace="AWS/EC2",
        Period=300,
        Statistic="Average",
        Threshold=80.0,
        ActionsEnabled=True,
        AlarmActions=[SNS_TOPIC_ARN],
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
        Unit="Percent"
    )

    # Memory Alarm (needs CloudWatch Agent)
    cloudwatch.put_metric_alarm(
        AlarmName=f"HighMemory-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=1,
        MetricName="mem_used_percent",
        Namespace="CWAgent",
        Period=300,
        Statistic="Average",
        Threshold=80.0,
        ActionsEnabled=True,
        AlarmActions=[SNS_TOPIC_ARN],
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}]
    )

    # Disk Usage Alarm (needs CloudWatch Agent)
    cloudwatch.put_metric_alarm(
        AlarmName=f"HighDisk-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=1,
        MetricName="disk_used_percent",
        Namespace="CWAgent",
        Period=300,
        Statistic="Average",
        Threshold=80.0,
        ActionsEnabled=True,
        AlarmActions=[SNS_TOPIC_ARN],
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}]
    )


def delete_alarms(instance_id):
    print(f"Deleting alarms for {instance_id}")
    alarm_names = [
        f"HighCPU-{instance_id}",
        f"HighMemory-{instance_id}",
        f"HighDisk-{instance_id}",
    ]
    cloudwatch.delete_alarms(AlarmNames=alarm_names)


def scan_and_create_for_all_running():
    """Scan all running EC2s and ensure alarms exist"""
    print("Scanning for existing running EC2s...")
    reservations = ec2.describe_instances(
        Filters=[{"Name": "instance-state-name", "Values": ["running"]}]
    )["Reservations"]

    for r in reservations:
        for instance in r["Instances"]:
            instance_id = instance["InstanceId"]
            create_alarms(instance_id)


def lambda_handler(event, context):
    print("Event:", event)

    # If triggered manually (no event) → scan all EC2s
    if not event or event == {}:
        scan_and_create_for_all_running()
        return {"status": "scanned_existing"}

    detail_type = event.get("detail-type")
    detail = event.get("detail", {})

    if detail_type == "EC2 Instance State-change Notification":
        state = detail.get("state")
        instance_id = detail.get("instance-id")

        if state == "running":
            create_alarms(instance_id)
        elif state in ["terminated", "stopped"]:
            delete_alarms(instance_id)

    return {"status": "done"}