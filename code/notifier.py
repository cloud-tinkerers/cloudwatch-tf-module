import json
import requests
import os
import boto3

def get_parameter(name):
    ssm = boto3.client('ssm')
    response = ssm.get_parameter(Name=name, WithDecryption=True)
    return response['Parameter']['Value']

def lambda_handler(event, context):
    # Loop through SNS records (in case of multiple messages)
    for record in event['Records']:
        sns_message = json.loads(record['Sns']['Message'])

        # Extract relevant fields from the SNS message
        alarm_name = sns_message['AlarmName']
        new_state = sns_message['NewStateValue']
        reason = sns_message['NewStateReason']
        
        # Customize the message based on the alarm name
        if alarm_name == "HighCPUUtilisation":
            message = f"CPU Alarm triggered: {reason}"
        else:
            message = f"Unknown alarm {alarm_name} triggered: {reason}"

        # Send the message to Discord via webhook
        discord_webhook_url = get_parameter(os.environ['discord_webhook'])
        data = {
            "content": message
        }

        response = requests.post(discord_webhook_url, json=data)

        return {
            'statusCode': response.status_code,
            'body': json.dumps('Alert sent to Discord')
        }
