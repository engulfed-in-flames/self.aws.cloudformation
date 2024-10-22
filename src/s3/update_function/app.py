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
        target_lambda_function_name = zip_to_pascal_name(object_key)

        lambda_client = boto3.client("lambda")
        lambda_client.update_function_code(
            FunctionName=target_lambda_function_name,
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

def zip_to_pascal_name(filename: str) -> str:
    name, _ = os.path.splitext(filename)
    words: list[str] = name.split("-")[:-1]
    pascal_case_words = [word.title() for word in words]

    return "".join(pascal_case_words)
