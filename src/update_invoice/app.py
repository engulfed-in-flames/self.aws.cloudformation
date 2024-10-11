import json
import os

import boto3


def lambda_handler(event, context):
    if not ("pathParameters" in event and "body" in event and event["httpMethod"] == "PUT"):
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
        payload = json.loads(event["body"])

        response = table.update_item(
            Key=keys,
            UpdateExpression="SET #attr = :val",
            ExpressionAttributeNames={
                "#attr": "itemName",
            },
            ExpressionAttributeValues={
                ":val": payload["itemName"],
            },
            ReturnValues="ALL_NEW",
        )
        print(response)

        return {
            "statusCode": 200,
            "headers": {},
            "body": json.dumps({"msg": "Updated the invoice."}),
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
