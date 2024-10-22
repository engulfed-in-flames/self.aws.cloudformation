import os
import json
import boto3



def lambda_handler(event, context):
    if not ("httpMethod" in event and event["httpMethod"] == "GET"):
        return {
            "statusCode": 400,
            "headers": {},
            "body": json.dumps({"msg": "Bad Request"}),
        }

    try:
        bucket_name = event["detail"]["bucket"]["name"]
        object_key = event["detail"]["object"]["key"]

        lambda_client = boto3.client("lambda")
        lambda_client.update_function_code(
            FunctionName=os.environ["TARGET_LAMBDA_FUNCTION_NAME"],
            S3Bucket=bucket_name,
            S3Key=object_key,
        )

        return json.dumps({
            "statusCode": 200,
            "body":{
                "msg": "Successfully executed.",
            },
        })
    except KeyError as e:
        return json.dumps({
            "statusCode": 500,
            "body":{
                "msg":"The bucket name or object key is not found.",
            }
        })
    except Exception as e:
        return json.dumps({
            "statusCode": 500,
            "body": {
                "event": event,
                "exception": str(e),
            }
        })
