import json
import os

import boto3


def lambda_handler(event, context):
    if not ("httpMethod" in event and event["httpMethod"] == "GET"):
        return {
            "statusCode": 400,
            "headers": {},
            "body": json.dumps({"msg": "Bad Request"}),
        }
    try:
        table_name = os.environ.get("TABLE", "Invoices")
        region = os.environ.get("REGION", "ap-northeast-1")

        resource = boto3.resource("dynamodb", region_name=region)

        table = resource.Table(table_name)
        response = table.scan()

        return {
            "statusCode": 200,
            "headers": {},
            "body": json.dumps(response["Items"]),
        }
    except Exception as e:
        print(str(e))
        return {
            "statusCode": 500,
            "body": {
                "event": event,
                "exception": str(e),
            }
        }
