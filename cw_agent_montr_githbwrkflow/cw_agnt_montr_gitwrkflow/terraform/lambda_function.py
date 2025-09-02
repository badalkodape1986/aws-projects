import boto3
import os

cloudwatch = boto3.client('cloudwatch')
ec2 = boto3.client('ec2')
sns_topic = os.environ['SNS_TOPIC_ARN']

def has_monitoring_tag(instance_id):
    resp = ec2.describe_tags(
        Filters=[
            {"Name": "resource-id", "Values": [instance_id]},
            {"Name": "key", "Values": ["Monitoring"]},
            {"Name": "value", "Values": ["Enabled"]}
        ]
    )
    return len(resp.get("Tags", [])) > 0

def create_alarms(instance_id):
    cloudwatch.put_metric_alarm(
        AlarmName=f"CPUUtilization-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=2,
        MetricName="CPUUtilization",
        Namespace="AWS/EC2",
        Period=60,
        Statistic="Average",
        Threshold=80,
        AlarmActions=[sns_topic],
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
    )

    cloudwatch.put_metric_alarm(
        AlarmName=f"MemoryUtilization-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=2,
        MetricName="mem_used_percent",
        Namespace="CWAgent",
        Period=60,
        Statistic="Average",
        Threshold=80,
        AlarmActions=[sns_topic],
        Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
    )

    cloudwatch.put_metric_alarm(
        AlarmName=f"DiskUtilization-{instance_id}",
        ComparisonOperator="GreaterThanThreshold",
        EvaluationPeriods=2,
        MetricName="disk_used_percent",
        Namespace="CWAgent",
        Period=60,
        Statistic="Average",
        Threshold=80,
        AlarmActions=[sns_topic],
        Dimensions=[
            {"Name": "InstanceId", "Value": instance_id},
            {"Name": "path", "Value": "/"},
            {"Name": "fstype", "Value": "xfs"},
        ],
    )

def delete_alarms(instance_id):
    alarm_prefixes = [
        f"CPUUtilization-{instance_id}",
        f"MemoryUtilization-{instance_id}",
        f"DiskUtilization-{instance_id}",
    ]
    for prefix in alarm_prefixes:
        alarms = cloudwatch.describe_alarms(AlarmNamePrefix=prefix)
        names = [a["AlarmName"] for a in alarms.get("MetricAlarms", [])]
        if names:
            cloudwatch.delete_alarms(AlarmNames=names)

def lambda_handler(event, context):
    detail = event.get("detail", {})
    instance_id = detail.get("instance-id")
    state = detail.get("state")

    if not instance_id or not state:
        return {"status": "ignored"}

    if state == "running":
        if has_monitoring_tag(instance_id):
            create_alarms(instance_id)
            return {"status": f"alarms created for {instance_id}"}
        return {"status": f"skipped {instance_id}, no Monitoring=Enabled tag"}

    elif state in ["stopped", "terminated"]:
        delete_alarms(instance_id)
        return {"status": f"alarms removed for {instance_id}"}

    return {"status": f"state {state} ignored"}
