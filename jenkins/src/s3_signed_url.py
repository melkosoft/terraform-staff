import uuid
import boto3
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    # Get the service client.
    s3 = boto3.client('s3')
    status = ""
    # Generate a random S3 key name
    upload_key = uuid.uuid4().hex
    #print event
    #print context
    action = event['path'][1:]
    bucket_name = event['queryStringParameters']['bname'] or "" 
    bucket_folder = event['queryStringParameters']['fname'] or ""
    bucket_key = event['queryStringParameters']['fkey'] or ""
    if bucket_name == "" or bucket_key == "":
       status = 503
       output = "Missing bname or fkey query parameters"
       action = ""
    else:
       bucket_key = bucket_folder + ("" if bucket_folder == "" else "/") + bucket_key
    # Generate the presigned URL for put requests
    if action == "import":
      try:
         signed_url = s3.generate_presigned_url(
                         ClientMethod='put_object',
                         Params={
                            'Bucket': bucket_name,
                            'Key': bucket_key
                         }
                      )
         output = "{ 'file': '" + bucket_key + "', 'url': '" + signed_url + "' }"
         status = 200
      except ClientError as e:
         err_code = e.response["Error"]["Code"]
         err_msg = e.response["Error"]["Message"]
         status = 503
         output = "{ 'error': '" + err_code + "', 'message': '" + err_msg + "' }"
 
    if action == "check":
      try: 
         obj = boto3.resource("s3").Object(bucket_name, bucket_key)
         output = "{'etag': '" + obj.get()['ETag'][1:-1] + "', 'size': '" + str(obj.get()['ContentLength']) + "' }"
         status = 200
      except ClientError as e:
         err_code = e.response["Error"]["Code"]
         err_msg = e.response["Error"]["Message"]
         status = 503
         output = "{ 'error': '" + err_code + "', 'message': '" + err_msg + "' }"
    # Return the presigned URL
    return {
        "statusCode": status,
        "body": output
    }
