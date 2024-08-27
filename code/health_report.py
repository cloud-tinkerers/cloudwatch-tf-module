import boto3
import os
import json
import requests
from datetime import datetime, timedelta

def get_average_metric(namespace, metric_name, dimensions, start_time, end_time, region, period=3600):
    """
    Retrieve the average value of a given CloudWatch metric over a specified time range.
    
    Parameters:
        namespace (str): The CloudWatch namespace (e.g., 'AWS/EC2', 'AWS/RDS').
        metric_name (str): The name of the metric (e.g., 'CPUUtilization').
        dimensions (list): A list of dimensions for the metric.
        start_time (datetime): The start of the time range.
        end_time (datetime): The end of the time range.
        period (int): The granularity, in seconds, of the data points (default is 3600 seconds).
    
    Returns:
        float: The average value of the metric over the specified time range.
    """
    cloudwatch = boto3.client('cloudwatch', region_name=region)
    response = cloudwatch.get_metric_statistics(
        Namespace=namespace,
        MetricName=metric_name,
        Dimensions=dimensions,
        StartTime=start_time,
        EndTime=end_time,
        Period=period,
        Statistics=['Average']
    )
    
    datapoints = response['Datapoints']
    
    if datapoints:
        avg_value = sum([dp['Average'] for dp in datapoints]) / len(datapoints)
        return avg_value
    else:
        return None

def send_to_discord(webhook, message):
    """
    Send a message to a Discord webhook.
    
    Parameters:
        webhook (str): The Discord webhook URL.
        message (str): The message to send.
    
    Returns:
        dict: Status code and body of the response.
    """
    try:
        data = {
            "content": message
        }
        response = requests.post(webhook, json=data)
        return {
            'statusCode': response.status_code,
            'body': json.dumps('Report sent to Discord')
        }
    except Exception as e:
        print(f"Error sending message to Discord: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Failed to send message to Discord: {e}")
        }

def get_parameter(name):
    ssm = boto3.client('ssm')
    response = ssm.get_parameter(Name=name, WithDecryption=True)
    return response['Parameter']['Value']

def lambda_handler(event, context):
    asg_name = os.environ['ASG_NAME']
    rds_id = os.environ['RDS_ID']
    region = os.environ['REGION']
    webhook = get_parameter(os.environ['discord_webhook'])

    # Define the time range for the past week
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=7)

    report_message = "Health report:"

    # Get average CPU utilization for ASG
    asg_avg_cpu = get_average_metric(
        namespace='AWS/EC2',
        metric_name='CPUUtilization',
        dimensions=[{'Name': 'AutoScalingGroupName', 'Value': asg_name}],
        start_time=start_time,
        end_time=end_time,
        region=region
    )

    if asg_avg_cpu is not None:
        report_message += f"Average ASG CPU utilization for the past week: {asg_avg_cpu:.2f}%\n"

    asg_network_in = get_average_metric(
        namespace='AWS/EC2',
        metric_name='NetworkIn',
        dimensions=[{'Name': 'AutoScalingGroupName', 'Value': asg_name}],
        start_time=start_time,
        end_time=end_time,
        region=region
    )

    if asg_network_in is not None:
        asg_network_in_mb = asg_network_in / (1024 * 1024)  # Convert bytes to MB
        report_message += f"Average ASG NetworkIn for the past week: {asg_network_in_mb:.2f}MB\n"

    asg_network_out = get_average_metric(
        namespace='AWS/EC2',
        metric_name='NetworkOut',
        dimensions=[{'Name': 'AutoScalingGroupName', 'Value': asg_name}],
        start_time=start_time,
        end_time=end_time,
        region=region
    )

    if asg_network_out is not None:
        asg_network_out_mb = asg_network_out / (1024 * 1024)  # Convert bytes to MB
        report_message += f"Average ASG NetworkOut for the past week: {asg_network_out_mb:.2f}MB\n"

    # Get average CPU utilization for RDS
    rds_avg_cpu = get_average_metric(
        namespace='AWS/RDS',
        metric_name='CPUUtilization',
        dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': rds_id}],
        start_time=start_time,
        end_time=end_time,
        region=region
    )

    if rds_avg_cpu is not None:
        report_message += f"Average RDS CPU utilization for the past week: {rds_avg_cpu:.2f}%\n"

    if report_message:
        send_to_discord(webhook, report_message)

    return {
        'statusCode': 200,
        'body': json.dumps('Metrics fetched and reported to Discord')
    }