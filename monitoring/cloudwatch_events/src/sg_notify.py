import boto3
import botocore
import json
import os
 
APPLICABLE_APIS = ["AuthorizeSecurityGroupIngress", "RevokeSecurityGroupIngress"]

# send email
def send_notification_email(event):
  rcpt_to = os.getenv('RCPT_TO') or ''
  mail_from = os.getenv('MAIL_FROM') or 'mamaenko@hp.com'
  client = boto3.client('ses', region_name='us-east-1')
  response = client.send_email(
     Destination={
         'ToAddresses': [rcpt_to],
     },
     Message={
         'Body': {
             'Text': {
                 'Charset': 'UTF-8',
                 'Data': json.dumps(event, sort_keys=True, indent=4),
             },
         },
         'Subject': {
             'Charset': 'UTF-8',
             'Data': 'AWS SG Changes Notification',
         },
     },
     Source=mail_from,
    )
  print response

# evaluate compliance
def evaluate_filter(event):
    event_name = event["detail"]["eventName"]
    if event_name not in APPLICABLE_APIS:
        print("This rule does not apply for the event ", event_name, ".")
        return
    filter = (os.getenv('SG_FILTER_TYPE') or '').lower()
    key_name = (os.getenv('SG_FILTER_KEY') or '').lower()
    key_value = (os.getenv('SG_FILTER_VALUE') or '').lower()
    print(filter)
    # monitoring all security groups
    if filter == '':
       send_notification_email(event)
       return
    # Monitoring particular SG (by group_id)
    group_id = event["detail"]["requestParameters"]["groupId"]
    print("group id: ", group_id)
    if filter == "groupid":
        if group_id in key_value:
            send_notification_email(event)
            return
    # check if sg is monitored (by vpc or tags)
    client = boto3.client("ec2")
    try:
        response = client.describe_security_groups(GroupIds=[group_id])
    except botocore.exceptions.ClientError as e:
        print("describe_security_groups failure on group ", group_id, " .")
        return
    print("Key: ", key_name, ", Value: ", key_value)
    if filter == 'vpc':
       if response["SecurityGroups"][0]["VpcId"][1:-1] in key_value:
          send_notification_email(event)
          return
    if filter == 'tag':
       tags = response["SecurityGroups"][0]["Tags"]
       print(tags)
       for tag in tags:
           print(tag['Key'].lower())
           if tag['Key'].lower() == key_name:
              if tag['Value'] and tag['Value'].lower() not in key_value:
                 continue
              send_notification_email(event)
              return


def lambda_handler(event, context):
    res = evaluate_filter(event)

