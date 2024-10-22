import json

def lambda_handler(event, context):
    if not ("httpMethod" in event and event["httpMethod"] == "GET"):
        return {
            "statusCode": 400,
            "headers": {},
            "body": json.dumps({"msg": "Bad Request"}),
        }

    try:
        return {
            "statusCode": 200,
            "body": json.dumps({"msg": "Successfully executed."}),
        }
    except Exception as e:
        print(str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({
                "event": event,
                "exception": str(e),
            })
        }
