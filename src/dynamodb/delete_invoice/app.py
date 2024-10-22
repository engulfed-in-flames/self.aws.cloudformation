import json
import os

import boto3


def lambda_handler(event, context):
    if not ("pathParameters" in event and event["httpMethod"] == "DELETE"):
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
        invoice_id = event["pathParameters"]["id"]
        keys = {"id": invoice_id}

        response = table.delete_item(Key=keys)
        print(response)

        return {
            "statusCode": 200,
            "headers": {},
            "body": json.dumps({"msg": "Deleted the invoice."}),
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

 
