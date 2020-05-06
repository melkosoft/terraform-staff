import boto3
import botocore
import json
import os
 
APPLICABLE_APIS = ["CreateRoute", "CreateRouteTable", "ReplaceRoute", "ReplaceRouteTableAssociation", "DeleteRouteTable","DeleteRoute","DisassociateRouteTable"]
# send email
def send_notification_email(event):
  rcpt_to = os.getenv('RCPT_TO') or ''
  mail_from = os.getenv('MAIL_FROM') or 'user@example.com'
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
             'Data': 'AWS RouteTable Changes Notification',
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

    # Notify if RT was deleted
    if event_name == "DeleteRouteTable":
       send_notification_email(event)
       return

    filter = (os.getenv('RT_FILTER_TYPE') or '').lower()
    key_name = (os.getenv('RT_FILTER_KEY') or '').lower()
    key_value = (os.getenv('RT_FILTER_VALUE') or '').lower()
    print(filter)
    # monitoring all Route Tables
    if filter == '':
       send_notification_email(event)
       return

    rt_id = event["detail"]["requestParameters"]["routeTableId"]
    print("rt id: ", rt_id)
    if filter == "routetableid":
        if rt_id in key_value:
            send_notification_email(event)
            return
    # check if rt is monitored (by vpc or tags)
    client = boto3.client("ec2")
    try:
        response = client.describe_route_tables(RouteTableIds=[rt_id])
    except botocore.exceptions.ClientError as e:
        print("describe_route_tables failure on RouteTable ", rt_id, " .")
        return
    print("Key: ", key_name, ", Value: ", key_value)
    if filter == "vpc":
       vpcid = response["RouteTables"][0]["VpcId"]
       if vpcid in key_value:
          send_notification_email(event)
          return
    if filter == 'tag':
       tags = response["RouteTables"][0]["Tags"]
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

