import json
import os
import uuid
from datetime import datetime

import boto3


def lambda_handler(event, context):
    if not ("body" in event and event["httpMethod"] == "POST"):
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
        payload = json.loads(event["body"])

        params = {
            "id": str(uuid.uuid4()),
            "storeName": payload["storeName"],
            "itemName": payload["itemName"],
            "price": payload["price"],
            "createdAt": str(datetime.timestamp(datetime.now())),
        }

        response = table.put_item(TableName=table_name, Item=params)
        print(response)

        return {
            "statusCode": 201,
            "headers": {},
            "body": json.dumps({"msg": "New Invoice Created"}),
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
