# Deployment of Lambda functions to monitor SecurityGroups and RouteTables changes

Terraform files to deploy Lambda functions
#### SG_CHANGES
Python script to monitor API calls to make changes in security groups
Using several Environment Variables:
 - RCPT_TO - destination email address for notifications. Has to be verified in SES (one per region)
 - MAIL_FROM - sender email address, has to be verified(?)
 - SG_FILTER_TYPE (Optional) - define filter for security groups monitored. If empty or missing notifications will be sent for changes applied to ANY SecurityGroups. Possible values: '', 'vpc', 'tag', 'groupid'
 - SG_FILTER_KEY (Optional) - define tag name when SG_FILTER_TYPE is 'tag'
 - SG_FILTER_VALUE (Optional) - define list of tags (separated by comma) when 'tag', list of vpc_id when SG_FILTER_TYPE is 'vpc' or list of group_id when - 'groupid'
 
#### RT_CHANGES
Python script to monitor API calls to make changes in route tables
Using several Environment Variables:
 - RCPT_TO - destination email address for notifications. Has to be verified in SES (one per region)
 - MAIL_FROM - sender email address, has to be verified(?)
 - SG_FILTER_TYPE (Optional) - define filter for route tables monitored. If empty or missing notifications will be sent for changes applied to ANY RouteTable. Possible values: '', 'vpc', 'tag', 'routetableid'
 - SG_FILTER_KEY (Optional) - define tag name when SG_FILTER_TYPE is 'tag'
 - SG_FILTER_VALUE (Optional) - define list of tags (separated by comma) when 'tag', list of vpc_id when SG_FILTER_TYPE is 'vpc' or list of routetable_id when - 'routetableid'

